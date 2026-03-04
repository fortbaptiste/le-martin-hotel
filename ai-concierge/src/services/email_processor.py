"""Email processing pipeline — 15 steps from receive to track."""

from __future__ import annotations

import re
from pathlib import Path

import structlog
from bs4 import BeautifulSoup

from src.config import settings

# Track processed message IDs to avoid reprocessing (observation mode)
_PROCESSED_IDS_FILE = Path(__file__).resolve().parent.parent.parent / "processed_ids.txt"
_processed_ids: set[str] = set()


def _load_processed_ids():
    global _processed_ids
    if _PROCESSED_IDS_FILE.exists():
        _processed_ids = set(_PROCESSED_IDS_FILE.read_text().strip().splitlines())


def _save_processed_id(msg_id: str):
    _processed_ids.add(msg_id)
    with open(_PROCESSED_IDS_FILE, "a") as f:
        f.write(msg_id + "\n")


def is_already_processed(msg_id: str) -> bool:
    if not _processed_ids:
        _load_processed_ids()
    return msg_id in _processed_ids
from src.exceptions import ConciergeError, EscalationRequired
from src.models.ai import AIRule, Escalation
from src.models.enums import ConversationCategory, EscalationReason, MessageDirection
from src.models.message import InboundEmail
from src.services import ai_engine, outlook, supabase_client as db
from src.services.confidence import compute_confidence
from src.services.cost_tracker import compute_cost_eur
from src.services.escalation import check_post_escalation, check_pre_escalation, notify_escalation
from src.services.language import detect_language

log = structlog.get_logger()

# Patterns for emails to skip (auto-replies, internal, spam-like)
_SKIP_PATTERNS = [
    re.compile(r"(noreply|no-reply|no_reply|mailer-daemon|postmaster)", re.IGNORECASE),
    re.compile(r"^(out of office|automatic reply|réponse automatique)", re.IGNORECASE),
    re.compile(r"(justificatif|payline|notification@|receipt@|invoice@|billing@)", re.IGNORECASE),
    re.compile(r"(collections@|accounting@|factur)", re.IGNORECASE),
]

# Known suppliers / vendors / partners — these are NOT hotel guests.
# Their emails should be ignored entirely (no AI response, no escalation).
_SUPPLIER_EMAILS: set[str] = {
    "instant.floral@yahoo.com",        # Fleuriste
    "slinet@assistance97.fr",          # Assistance 97 (prestataire technique)
}
_SUPPLIER_DOMAINS: set[str] = {
    "hm2.tripadvisor.com",             # Rapports automatiques TripAdvisor
    "tripadvisor.com",                 # TripAdvisor
    "mrandmrssmith.com",              # Mr & Mrs Smith (plateforme résa)
    "app.siteminder.com",             # SiteMinder (channel manager)
}


async def process_email(email: InboundEmail) -> dict:
    """
    Full 15-step pipeline:
      1. RECEIVE  2. PARSE  3. VALIDATE  4. CLIENT  5. CONVERSATION
      6. STORE    7. RULES  8. PRE-ESCALATION  9. KNOWLEDGE  10. EXAMPLES
      11. AI GENERATE  12. CONFIDENCE  13. POST-CHECK  14. DELIVER  15. TRACK
    """
    result: dict = {"status": "processed", "email_id": email.outlook_message_id}

    # Skip already processed emails (observation mode)
    if is_already_processed(email.outlook_message_id):
        return {"status": "already_processed", "email_id": email.outlook_message_id}

    try:
        # ── 2. PARSE — strip HTML, extract plain text ──
        body_text = _parse_body(email)
        detected_lang = detect_language(body_text)
        log.info("pipeline.parse", from_email=email.from_email, language=detected_lang,
                 subject=email.subject)

        # ── 3. VALIDATE — skip spam, auto-replies, internal ──
        if _should_skip(email):
            _save_processed_id(email.outlook_message_id)
            log.info("pipeline.skipped", reason="auto-reply or internal", from_email=email.from_email)
            result["status"] = "skipped"
            return result

        # ── 4. CLIENT — lookup or create ──
        client = await db.get_client_by_email(email.from_email)
        if not client:
            client = await db.create_client_record({
                "email": email.from_email,
                "first_name": _extract_first_name(email.from_name),
                "last_name": _extract_last_name(email.from_name),
                "language": detected_lang,
            })
            log.info("pipeline.client_created", email=email.from_email)
        else:
            await db.update_client(client["id"], {"language": detected_lang})

        # ── 5. CONVERSATION — lookup or create by conversation_id ──
        conversation = None
        if email.outlook_conversation_id:
            conversation = await db.get_conversation_by_thread(email.outlook_conversation_id)

        if not conversation:
            conversation = await db.create_conversation({
                "client_id": client["id"],
                "outlook_thread_id": email.outlook_thread_id,
                "outlook_conversation_id": email.outlook_conversation_id,
                "subject": email.subject,
            })
            log.info("pipeline.conversation_created", conv_id=conversation["id"])

        # ── 6. STORE — save inbound message ──
        msg_record = await db.create_message({
            "conversation_id": conversation["id"],
            "outlook_message_id": email.outlook_message_id,
            "direction": MessageDirection.INBOUND,
            "from_email": email.from_email,
            "to_email": email.to_email,
            "subject": email.subject,
            "body_text": body_text,
            "body_html": email.body_html,
            "detected_language": detected_lang,
        })

        # ── 7. RULES — load active AI rules ──
        raw_rules = await db.get_active_rules()
        rules = [AIRule(**r) for r in raw_rules]

        # ── 8. PRE-ESCALATION — pattern matching on latest message only ──
        latest_message = _extract_latest_message(email)
        pre_esc = check_pre_escalation(latest_message, email.subject or "")
        if pre_esc:
            await _handle_escalation(
                exc=pre_esc,
                conversation=conversation,
                client=client,
                msg_record=msg_record,
                body_text=body_text,
            )
            _save_processed_id(email.outlook_message_id)
            result["status"] = "escalated"
            result["reason"] = pre_esc.reason
            return result

        # ── 9-10. KNOWLEDGE + EXAMPLES — handled inside ai_engine ──

        # Fetch conversation history for context
        conv_messages = await db.get_conversation_messages(conversation["id"], limit=10)

        # ── 11. AI GENERATE — Claude tool_use loop ──
        ai_response = await ai_engine.generate_response(
            email_body=body_text,
            email_subject=email.subject or "",
            from_email=email.from_email,
            detected_language=detected_lang,
            rules=rules,
            client_context=client,
            conversation_history=conv_messages,
        )

        # ── 12. CONFIDENCE — scoring ──
        confidence = compute_confidence(
            ai_response_text=ai_response.response_text,
            llm_self_score=ai_response.confidence_score,
            tools_used=ai_response.tools_used,
            email_body=body_text,
            rules_count=len(rules),
        )
        final_score = confidence.weighted_score

        # ── 13. POST-CHECK — post-AI escalation ──
        post_esc = check_post_escalation(ai_response.response_text, final_score)
        if post_esc:
            await _handle_escalation(
                exc=post_esc,
                conversation=conversation,
                client=client,
                msg_record=msg_record,
                body_text=body_text,
            )
            # Still save the draft for reference
            await db.update_message(msg_record["id"], {
                "ai_draft": ai_response.response_text,
                "confidence_score": round(final_score, 2),
                "tokens_input": ai_response.tokens_input,
                "tokens_output": ai_response.tokens_output,
                "response_time_ms": ai_response.response_time_ms,
                "category": ai_response.category,
            })
            _save_processed_id(email.outlook_message_id)
            result["status"] = "escalated"
            result["reason"] = post_esc.reason
            return result

        # ── 14. DELIVER — draft or auto-send ──
        cost = compute_cost_eur(
            settings.anthropic_model,
            ai_response.tokens_input,
            ai_response.tokens_output,
        )
        response_html = _text_to_html(ai_response.response_text)

        # OBSERVATION MODE: log response locally, do NOT create Outlook drafts or send replies
        log.info(
            "pipeline.observation_response",
            from_email=email.from_email,
            subject=email.subject,
            response_preview=ai_response.response_text[:500],
        )

        # Save outbound message
        await db.create_message({
            "conversation_id": conversation["id"],
            "direction": MessageDirection.OUTBOUND,
            "from_email": settings.email_address,
            "to_email": email.from_email,
            "subject": f"Re: {email.subject}" if email.subject else "Re:",
            "ai_draft": ai_response.response_text,
            "final_text": ai_response.response_text,
            "confidence_score": round(final_score, 2),
            "tokens_input": ai_response.tokens_input,
            "tokens_output": ai_response.tokens_output,
            "cost_eur": cost,
            "response_time_ms": ai_response.response_time_ms,
            "detected_language": detected_lang,
            "category": ai_response.category,
        })

        # Update conversation category
        await db.update_conversation(conversation["id"], {
            "category": ai_response.category,
        })

        # ── 15. TRACK — mark read, log ──
        # OBSERVATION MODE: ne pas marquer comme lu pour ne pas interférer avec Emmanuel
        # await outlook.mark_as_read(email.outlook_message_id)
        _save_processed_id(email.outlook_message_id)

        log.info(
            "pipeline.complete",
            from_email=email.from_email,
            category=ai_response.category,
            confidence=round(final_score, 2),
            tools=ai_response.tools_used,
            cost_eur=cost,
            response_time_ms=ai_response.response_time_ms,
        )

        result["confidence"] = round(final_score, 2)
        result["category"] = ai_response.category
        result["tools_used"] = ai_response.tools_used
        result["cost_eur"] = cost

    except EscalationRequired as exc:
        log.warning("pipeline.escalation", reason=exc.reason, details=exc.details)
        result["status"] = "escalated"
        result["reason"] = exc.reason
    except ConciergeError as exc:
        log.error("pipeline.error", error=str(exc))
        result["status"] = "error"
        result["error"] = str(exc)
    except Exception as exc:
        log.exception("pipeline.unexpected_error")
        result["status"] = "error"
        result["error"] = str(exc)

    return result


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _parse_body(email: InboundEmail) -> str:
    """Extract clean text from the email (full thread — used for AI context)."""
    if email.body_html:
        soup = BeautifulSoup(email.body_html, "html.parser")
        for tag in soup(["script", "style", "head"]):
            tag.decompose()
        text = soup.get_text(separator="\n", strip=True)
    else:
        text = email.body_text

    text = re.sub(r"\n{3,}", "\n\n", text)
    text = re.sub(r"[ \t]+", " ", text)
    return text.strip()


def _extract_latest_message(email: InboundEmail) -> str:
    """Extract ONLY the latest message (no quoted thread) — used for escalation detection."""
    if email.body_html:
        soup = BeautifulSoup(email.body_html, "html.parser")
        for tag in soup(["script", "style", "head"]):
            tag.decompose()
        # Remove Outlook / Gmail quoted replies
        for tag in soup.select('div#appendonsend, div.gmail_quote, blockquote'):
            tag.decompose()
        # Remove everything after the first <hr> (Outlook thread separator)
        for hr in soup.find_all("hr"):
            for sibling in list(hr.find_next_siblings()):
                sibling.decompose()
            hr.decompose()
            break
        text = soup.get_text(separator="\n", strip=True)
    else:
        text = email.body_text

    # Strip text-based reply markers
    lines = text.split("\n")
    cleaned = []
    for line in lines:
        if re.match(r"^-{2,}\s*(Original Message|Message d'origine|Forwarded)", line, re.IGNORECASE):
            break
        if re.match(r"^(From|De|Sent|Envoyé|Date)\s*:", line, re.IGNORECASE) and cleaned:
            break
        if not line.strip().startswith(">"):
            cleaned.append(line)
    text = "\n".join(cleaned)

    text = re.sub(r"\n{3,}", "\n\n", text)
    text = re.sub(r"[ \t]+", " ", text)
    return text.strip()


def _should_skip(email: InboundEmail) -> bool:
    """Check if this email should be skipped."""
    from_lower = email.from_email.lower()

    # Skip known suppliers / vendors / partners
    if from_lower in _SUPPLIER_EMAILS:
        log.info("pipeline.skipped_supplier", from_email=email.from_email, reason="known supplier email")
        return True
    from_domain = from_lower.split("@", 1)[-1]
    if from_domain in _SUPPLIER_DOMAINS:
        log.info("pipeline.skipped_supplier", from_email=email.from_email, reason="known supplier domain")
        return True

    # Skip auto-replies and system emails
    for pattern in _SKIP_PATTERNS:
        if pattern.search(email.from_email):
            return True
        if email.subject and pattern.search(email.subject):
            return True

    # Skip emails from the hotel itself
    if from_lower == settings.email_address.lower():
        return True
    if from_lower.endswith("@lemartinhotel.com"):
        return True

    return False


def _extract_first_name(full_name: str | None) -> str | None:
    if not full_name:
        return None
    parts = full_name.strip().split()
    return parts[0] if parts else None


def _extract_last_name(full_name: str | None) -> str | None:
    if not full_name:
        return None
    parts = full_name.strip().split()
    return " ".join(parts[1:]) if len(parts) > 1 else None


def _text_to_html(text: str) -> str:
    """Convert plain text to simple HTML for Outlook."""
    escaped = text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    paragraphs = escaped.split("\n\n")
    html_parts = [f"<p>{p.replace(chr(10), '<br>')}</p>" for p in paragraphs if p.strip()]
    return "\n".join(html_parts)


async def _handle_escalation(
    *,
    exc: EscalationRequired,
    conversation: dict,
    client: dict,
    msg_record: dict,
    body_text: str,
) -> None:
    """Store escalation and notify Emmanuel."""
    # Update conversation status
    await db.update_conversation(conversation["id"], {"status": "escalated", "assignee": "emmanuel"})

    # Create escalation record
    await db.create_escalation({
        "conversation_id": conversation["id"],
        "message_id": msg_record.get("id"),
        "reason": exc.reason,
        "details": exc.details,
    })

    # OBSERVATION MODE: log escalation locally, do NOT send notification email to Emmanuel
    log.info(
        "pipeline.observation_escalation",
        client_email=client.get("email", ""),
        client_name=f"{client.get('first_name', '')} {client.get('last_name', '')}".strip(),
        reason=exc.reason,
        details=exc.details,
    )
