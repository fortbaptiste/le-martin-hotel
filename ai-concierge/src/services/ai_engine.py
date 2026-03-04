"""Claude tool_use loop — core AI engine for email response generation."""

from __future__ import annotations

import re
import time

import anthropic
import structlog

from src.config import settings
from src.exceptions import AIError
from src.models.ai import AIRule
from src.models.message import AIResponse
from src.prompts.few_shot import format_few_shot_messages, select_few_shot_examples
from src.prompts.system import build_system_prompt
from src.services import supabase_client as db
from src.tools.definitions import TOOLS
from src.tools.handlers import handle_tool_call

log = structlog.get_logger()

MAX_TOOL_ITERATIONS = 8


async def generate_response(
    *,
    email_body: str,
    email_subject: str = "",
    from_email: str,
    detected_language: str = "en",
    rules: list[AIRule],
    client_context: dict | None = None,
    conversation_history: list[dict] | None = None,
) -> AIResponse:
    """Run the Claude tool_use loop and return a structured AI response."""
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

    # Build the messages array
    messages: list[dict] = []
    messages.extend(few_shot_messages)
    messages.append({
        "role": "user",
        "content": (
            f"Nouvel email reçu de {from_email}:\n"
            f"Objet : {email_subject}\n\n"
            f"{email_body}"
        ),
    })

    # Claude API client
    client = anthropic.Anthropic(api_key=settings.anthropic_api_key)
    total_input_tokens = 0
    total_output_tokens = 0
    tools_used: list[str] = []

    # Tool-use loop (max iterations)
    for iteration in range(MAX_TOOL_ITERATIONS):
        log.debug("ai.iteration", iteration=iteration + 1)

        try:
            response = client.messages.create(
                model=settings.anthropic_model,
                max_tokens=settings.anthropic_max_tokens,
                temperature=settings.anthropic_temperature,
                system=system_prompt,
                tools=TOOLS,
                messages=messages,
            )
        except anthropic.APIError as exc:
            raise AIError(f"Claude API error: {exc}") from exc

        total_input_tokens += response.usage.input_tokens
        total_output_tokens += response.usage.output_tokens

        # Check if Claude wants to use tools
        if response.stop_reason == "tool_use":
            # Process tool calls
            tool_results = []
            for block in response.content:
                if block.type == "tool_use":
                    tool_name = block.name
                    tool_input = block.input
                    tools_used.append(tool_name)
                    log.info("ai.tool_call", tool=tool_name, input=tool_input)

                    result = await handle_tool_call(tool_name, tool_input)
                    tool_results.append({
                        "type": "tool_result",
                        "tool_use_id": block.id,
                        "content": result,
                    })

            # Add assistant response + tool results to messages
            messages.append({"role": "assistant", "content": response.content})
            messages.append({"role": "user", "content": tool_results})
        else:
            # Final text response — extract it
            break
    else:
        log.warning("ai.max_iterations_reached")

    # Extract text from the final response
    response_text = ""
    for block in response.content:
        if hasattr(block, "text"):
            response_text += block.text

    if not response_text.strip():
        raise AIError("Claude returned an empty response.")

    # Parse CONFIDENCE and CATEGORY from the end of the response
    confidence, category, clean_text = _parse_metadata(response_text)

    elapsed_ms = int((time.monotonic() - start_ms) * 1000)

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


def _parse_metadata(text: str) -> tuple[float, str, str]:
    """Extract CONFIDENCE and CATEGORY lines from the response text."""
    confidence = 0.5
    category = "other"

    # Extract confidence
    m = re.search(r"CONFIDENCE:\s*([\d.]+)", text)
    if m:
        try:
            confidence = min(1.0, max(0.0, float(m.group(1))))
        except ValueError:
            pass

    # Extract category
    m2 = re.search(r"CATEGORY:\s*(\w+)", text)
    if m2:
        category = m2.group(1).lower()

    # Remove metadata lines from the email body
    clean = re.sub(r"\n?CONFIDENCE:.*", "", text)
    clean = re.sub(r"\n?CATEGORY:.*", "", clean)
    clean = clean.rstrip()

    return confidence, category, clean
