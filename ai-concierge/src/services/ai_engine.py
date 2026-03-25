"""Claude tool_use loop — core AI engine for email response generation."""

from __future__ import annotations

import asyncio
import re
import time

import anthropic
from anthropic import AsyncAnthropic
import structlog

from src.config import settings
from src.exceptions import AIError
from src.models.ai import AIRule
from src.models.enums import ConversationCategory
from src.models.message import AIResponse
from src.prompts.few_shot import format_few_shot_messages, select_few_shot_examples
from src.prompts.system import build_system_prompt
from src.services import supabase_client as db
from src.tools.definitions import TOOLS
from src.tools.handlers import handle_tool_call

log = structlog.get_logger()

MAX_TOOL_ITERATIONS = 8

# Limit concurrent Claude API calls to avoid burst overload
_API_SEMAPHORE = asyncio.Semaphore(3)

# ── Module-level async client (lazy singleton) ──────────────────────────
_client: AsyncAnthropic | None = None


def _get_client() -> AsyncAnthropic:
    """Return (and lazily create) the module-level AsyncAnthropic client."""
    global _client
    if _client is None:
        _client = AsyncAnthropic(api_key=settings.anthropic_api_key)
    return _client


# ── Prompt-injection defense helpers ────────────────────────────────────

_XML_TAG_RE = re.compile(r"</?[a-zA-Z_][\w.\-]*[^>]*>")


def _sanitize_email_body(raw: str) -> str:
    """Strip any XML-like tags from *raw* so they cannot break our delimiters."""
    return _XML_TAG_RE.sub("", raw)


# ── Main generation entry-point ─────────────────────────────────────────

async def generate_response(
    *,
    email_body: str,
    email_subject: str = "",
    from_email: str,
    detected_language: str = "en",
    rules: list[AIRule],
    client_context: dict | None = None,
    conversation_history: list[dict] | None = None,
    escalation_hint: str | None = None,
) -> AIResponse:
    """Run the Claude tool_use loop and return a structured AI response."""
    async with _API_SEMAPHORE:
        return await _generate_response_inner(
            email_body=email_body,
            email_subject=email_subject,
            from_email=from_email,
            detected_language=detected_language,
            rules=rules,
            client_context=client_context,
            conversation_history=conversation_history,
            escalation_hint=escalation_hint,
        )


async def _generate_response_inner(
    *,
    email_body: str,
    email_subject: str = "",
    from_email: str,
    detected_language: str = "en",
    rules: list[AIRule],
    client_context: dict | None = None,
    conversation_history: list[dict] | None = None,
    escalation_hint: str | None = None,
) -> AIResponse:
    """Inner implementation — runs inside the semaphore."""
    start_ms = time.monotonic()

    # Build system prompt
    system_prompt = build_system_prompt(
        rules=rules,
        client_context=client_context,
        detected_language=detected_language,
        conversation_history=conversation_history,
    )

    # Fetch and select few-shot examples
    all_examples = await db.get_email_examples()
    examples = select_few_shot_examples(email_body, all_examples, language=detected_language)
    few_shot_messages = format_few_shot_messages(examples)

    # ── Prompt injection defense: sanitize body AND subject ──
    safe_body = _sanitize_email_body(email_body)
    safe_subject = _sanitize_email_body(email_subject)

    # Build the messages array
    messages: list[dict] = []
    messages.extend(few_shot_messages)
    # Build user message content
    user_content = (
        f"Nouvel email reçu de {from_email}:\n"
        f"Objet : {safe_subject}\n\n"
        f"<guest_email>\n{safe_body}\n</guest_email>"
    )

    # Escalation hint: AI must write a short acknowledgement (Option B)
    if escalation_hint:
        user_content += (
            f"\n\n<escalation_context>\n{escalation_hint}\n"
            "Rédige un brouillon COURT (2-3 phrases max) qui accuse réception "
            "et dit que l'équipe s'en occupe. Ne propose PAS de solution toi-même.\n"
            "</escalation_context>"
        )

    messages.append({"role": "user", "content": user_content})

    # ── Claude async client (module-level singleton) ──
    client = _get_client()
    total_input_tokens = 0
    total_output_tokens = 0
    tools_used: list[str] = []
    response = None
    hit_max_tokens = False

    # Tool-use loop (max iterations)
    for iteration in range(MAX_TOOL_ITERATIONS):
        log.debug("ai.iteration", iteration=iteration + 1)

        try:
            response = await client.messages.create(
                model=settings.anthropic_model,
                max_tokens=settings.anthropic_max_tokens,
                temperature=settings.anthropic_temperature,
                system=[{
                    "type": "text",
                    "text": system_prompt,
                    "cache_control": {"type": "ephemeral"},
                }],
                tools=TOOLS,
                messages=messages,
            )
        except anthropic.APIError as exc:
            raise AIError(f"Claude API error: {exc}") from exc

        iter_input = response.usage.input_tokens
        iter_output = response.usage.output_tokens
        total_input_tokens += iter_input
        total_output_tokens += iter_output

        # Per-iteration cost logging (Claude 3.5 Sonnet pricing as reference)
        log.info(
            "ai.iteration_tokens",
            iteration=iteration + 1,
            input_tokens=iter_input,
            output_tokens=iter_output,
            cumulative_input=total_input_tokens,
            cumulative_output=total_output_tokens,
        )

        # ── Handle max_tokens truncation ──
        if response.stop_reason == "max_tokens":
            log.warning(
                "ai.max_tokens_hit",
                iteration=iteration + 1,
                output_tokens=iter_output,
            )
            hit_max_tokens = True
            break

        # Check if Claude wants to use tools
        if response.stop_reason == "tool_use":
            # Collect tool calls and execute them in parallel
            tool_blocks = [b for b in response.content if b.type == "tool_use"]
            for b in tool_blocks:
                tools_used.append(b.name)
                log.info("ai.tool_call", tool=b.name, input=b.input)

            results = await asyncio.gather(
                *(handle_tool_call(b.name, b.input) for b in tool_blocks)
            )
            tool_results = [
                {"type": "tool_result", "tool_use_id": b.id, "content": r}
                for b, r in zip(tool_blocks, results)
            ]

            # Add assistant response + tool results to messages
            messages.append({"role": "assistant", "content": response.content})
            messages.append({"role": "user", "content": tool_results})
        else:
            # Final text response — extract it
            break
    else:
        # Max iterations reached without a final text response
        log.warning("ai.max_iterations_reached", iterations=MAX_TOOL_ITERATIONS)

    # ── Extract text from the last response ──
    response_text = ""
    if response is not None:
        for block in response.content:
            if hasattr(block, "text"):
                response_text += block.text

    # ── Fallback: if text is empty after tool calls, retry once ──
    if not response_text.strip() and tools_used:
        log.warning("ai.empty_response_after_tools", tools_used=tools_used)
        # Retry once with an explicit instruction to write the email
        messages.append({"role": "assistant", "content": response.content if response else []})
        messages.append({
            "role": "user",
            "content": (
                "Tu DOIS rédiger un email au client. Écris un accusé de réception "
                "court et chaleureux (2-3 phrases) disant que l'équipe s'en occupe."
            ),
        })
        try:
            retry_response = await client.messages.create(
                model=settings.anthropic_model,
                max_tokens=settings.anthropic_max_tokens,
                temperature=settings.anthropic_temperature,
                system=system_prompt,
                tools=TOOLS,
                messages=messages,
            )
            total_input_tokens += retry_response.usage.input_tokens
            total_output_tokens += retry_response.usage.output_tokens
            for block in retry_response.content:
                if hasattr(block, "text"):
                    response_text += block.text
            log.info("ai.retry_succeeded", has_text=bool(response_text.strip()))
        except Exception as retry_exc:
            log.error("ai.retry_failed", error=str(retry_exc))

    # ── Ultimate fallback: generic acknowledgement ──
    if not response_text.strip():
        log.warning("ai.using_fallback_response", detected_language=detected_language)
        if detected_language == "fr":
            response_text = (
                f"Bonjour,\n\n"
                f"Nous avons bien reçu votre message et le transmettons à Emmanuel "
                f"qui reviendra vers vous très prochainement.\n\n"
                f"Marion & Emmanuel\n\n"
                f"---\nCONFIDENCE: 0.3\nCATEGORY: other"
            )
        else:
            response_text = (
                f"Dear Guest,\n\n"
                f"Thank you for your message. I'm forwarding it to Emmanuel "
                f"who will get back to you shortly.\n\n"
                f"Marion & Emmanuel\n\n"
                f"---\nCONFIDENCE: 0.3\nCATEGORY: other"
            )

    # Parse CONFIDENCE and CATEGORY from the end of the response
    confidence, category, clean_text = _parse_metadata(response_text)

    # ── Adjust confidence for degraded conditions ──
    if hit_max_tokens:
        # Response was truncated — lower confidence to signal degraded output
        confidence = min(confidence, 0.6)
        log.warning("ai.confidence_capped_max_tokens", adjusted_confidence=confidence)

    # If we exhausted all iterations, cap confidence even lower
    if response is not None and response.stop_reason == "tool_use":
        confidence = min(confidence, 0.4)
        log.warning(
            "ai.confidence_capped_max_iterations",
            adjusted_confidence=confidence,
        )

    elapsed_ms = int((time.monotonic() - start_ms) * 1000)

    log.info(
        "ai.response_complete",
        elapsed_ms=elapsed_ms,
        total_input_tokens=total_input_tokens,
        total_output_tokens=total_output_tokens,
        tools_used=tools_used,
        confidence=confidence,
        category=category,
    )

    return AIResponse(
        response_text=clean_text,
        confidence_score=confidence,
        detected_language=detected_language,
        category=category,
        tokens_input=total_input_tokens,
        tokens_output=total_output_tokens,
        tools_used=tools_used,
        response_time_ms=elapsed_ms,
    )


# ── Markdown stripping — Claude sometimes adds formatting despite rules ─

def _strip_markdown(text: str) -> str:
    """Remove markdown formatting so the email is clean plain text."""
    # **bold** or __bold__ → bold
    text = re.sub(r"\*\*(.+?)\*\*", r"\1", text)
    text = re.sub(r"__(.+?)__", r"\1", text)
    # *italic* or _italic_ (single, only between word boundaries)
    text = re.sub(r"(?<!\w)\*([^*\n]+?)\*(?!\w)", r"\1", text)
    # # Headings → just the text, with a blank line before
    text = re.sub(r"^#{1,4}\s+(.+)$", r"\n\1", text, flags=re.MULTILINE)
    # - or * bullet lists → plain line
    text = re.sub(r"^[\-\*•]\s+", "", text, flags=re.MULTILINE)
    # 1. numbered lists → plain line
    text = re.sub(r"^\d+\.\s+", "", text, flags=re.MULTILINE)
    # ```code blocks``` → just the content
    text = re.sub(r"```\w*\n?", "", text)
    # [link text](url) → link text (url)
    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r"\1 (\2)", text)
    # Clean up excessive blank lines
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


# ── Metadata parsing ────────────────────────────────────────────────────

# Regex patterns — case-insensitive to handle Claude's occasional variation
_CONFIDENCE_RE = re.compile(r"CONFIDENCE\s*:\s*([\d.]+)", re.IGNORECASE)
_CATEGORY_RE = re.compile(r"CATEGORY\s*:\s*([\w]+)", re.IGNORECASE)


def _parse_metadata(text: str) -> tuple[float, str, str]:
    """Extract CONFIDENCE and CATEGORY lines from the **end** of the response text.

    Parsing is restricted to the last 500 characters to avoid being fooled
    by content earlier in the message (e.g. inside a quoted guest email).

    Returns (confidence, category, cleaned_text).
    """
    confidence = 0.5
    category: str = ConversationCategory.OTHER
    tail = text[-500:] if len(text) > 500 else text

    # ── Confidence ──
    m = _CONFIDENCE_RE.search(tail)
    if m:
        try:
            confidence = min(1.0, max(0.0, float(m.group(1))))
        except ValueError:
            log.warning("ai.confidence_parse_failed", raw=m.group(1))
    else:
        log.warning("ai.confidence_not_found")

    # ── Category ──
    m2 = _CATEGORY_RE.search(tail)
    if m2:
        raw_cat = m2.group(1).lower()
        try:
            category = ConversationCategory(raw_cat)
        except ValueError:
            log.warning("ai.unknown_category", raw=raw_cat)
            category = ConversationCategory.OTHER
    else:
        log.warning("ai.category_not_found")

    # Remove metadata block from the visible email body:
    # the --- separator, CONFIDENCE line, and CATEGORY line
    clean = re.sub(r"\n?-{3,}\s*\n?", "\n", text)  # strip --- separators
    clean = re.sub(r"\n?CONFIDENCE\s*:.*", "", clean, flags=re.IGNORECASE)
    clean = re.sub(r"\n?CATEGORY\s*:.*", "", clean, flags=re.IGNORECASE)
    clean = _strip_markdown(clean)

    return confidence, category, clean
