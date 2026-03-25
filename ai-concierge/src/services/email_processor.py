"""Email processing pipeline — 15 steps from receive to track."""

from __future__ import annotations

import asyncio
import re
import time
from collections import defaultdict
from pathlib import Path

import structlog
from bs4 import BeautifulSoup

from src.config import settings

# ---------------------------------------------------------------------------
# Processed-ID tracking (crash-safe, thread-safe)
# ---------------------------------------------------------------------------

# Track processed message IDs to avoid reprocessing (observation mode)
_PROCESSED_IDS_FILE = Path(__file__).resolve().parent.parent.parent / "processed_ids.txt"
_processed_ids: set[str] = set()

# asyncio.Lock for thread-safe access from webhook + polling loop
_processed_lock = asyncio.Lock()

# In-memory retry counts — if an email crashes the pipeline 3 times, mark as processed
_retry_counts: dict[str, int] = {}
_MAX_RETRIES = 3


def _load_processed_ids():
    global _processed_ids
    if _PROCESSED_IDS_FILE.exists():
        _processed_ids = set(_PROCESSED_IDS_FILE.read_text().strip().splitlines())


async def _save_processed_id(msg_id: str):
    """Save a processed ID (thread-safe)."""
    async with _processed_lock:
        _processed_ids.add(msg_id)
        with open(_PROCESSED_IDS_FILE, "a") as f:
            f.write(msg_id + "\n")


async def is_already_processed(msg_id: str) -> bool:
    """Check if a message has already been processed (thread-safe)."""
    async with _processed_lock:
        if not _processed_ids:
            _load_processed_ids()
        return msg_id in _processed_ids


from src.exceptions import ConciergeError, EscalationRequired
from src.models.ai import AIRule, Escalation
from src.models.enums import ConversationCategory, EscalationReason, MessageDirection
from src.models.message import InboundEmail
from src.services import ai_engine, outlook, supabase_client as db
from src.tools.handlers import clear_session_state, get_pending_team_actions
from src.services.confidence import compute_confidence
from src.services.cost_tracker import compute_cost_eur
from src.services.escalation import check_post_escalation, check_pre_escalation, notify_escalation, notify_team_action
from src.services.language import detect_language

log = structlog.get_logger()

# ---------------------------------------------------------------------------
# Body truncation limits
# ---------------------------------------------------------------------------
_MAX_BODY_CHARS = 8000          # ~2000 tokens — full thread for AI context
_MAX_LATEST_MSG_CHARS = 3000    # latest message only — for escalation detection

# Patterns for emails to skip (auto-replies, internal, spam-like)
_SKIP_PATTERNS = [
    re.compile(r"(noreply|no-reply|no_reply|mailer-daemon|postmaster)", re.IGNORECASE),
    re.compile(r"^(out of office|automatic reply|réponse automatique)", re.IGNORECASE),
    re.compile(r"(justificatif|payline|notification@|receipt@|invoice@|billing@)", re.IGNORECASE),
    re.compile(r"(collections@|accounting@|factur)", re.IGNORECASE),
    re.compile(r"(tracking@|suivi\s+de\s+commande|avis\s+de\s+chargement)", re.IGNORECASE),
    re.compile(r"(confirmation-\w+@|newsletter@|inspiration@)", re.IGNORECASE),
    re.compile(r"(virement\s+SEPA|confirmation\s+de\s+(?:votre\s+)?virement)", re.IGNORECASE),
]

# Non-guest content patterns — detected in subject + body.
# These are NOT guests: job seekers, ads, B2B, press, real estate, newsletters.
# → Skip entirely (no AI, no draft, no escalation, just mark as read).
_NON_GUEST_PATTERNS = [
    # Job applications / recruitment
    re.compile(
        r"\b(cherche\w*\s+(?:du\s+)?travail|looking\s+for\s+(?:a\s+)?(?:job|work)|"
        r"candidature|curriculum|CV\b|résumé\b|lettre\s+de\s+motivation|cover\s+letter|"
        r"emploi|recrutement|recruitment|hiring|job\s+(?:application|opening|posting)|"
        r"poste\s+(?:de|à|disponible)|postuler|apply\s+for)\b", re.IGNORECASE),
    # Commercial / advertising / prospection
    re.compile(
        r"\b(proposition\s+commerciale|offre\s+commerciale|démarchage|prospection|"
        r"partenariat|partner(?:ship)?|sponsor\w*|"
        r"collaborat(?:ion|e|ing)\s+(?:commerciale|with\s+your)|work\s+together|"
        r"business\s+(?:opportunity|proposal|development)|"
        r"devis\s+(?:gratuit|commercial)|tarif\s+(?:professionnel|groupe)|"
        r"newsletter|désabonner|unsubscribe|mailing\s+list)\b", re.IGNORECASE),
    # Press / media / influencer / PR agencies
    re.compile(
        r"\b(journaliste|journalist|presse|press\s+(?:release|inquiry)|"
        r"rédaction|editorial|influenceu?r|blog\s*(?:geu?r|trip)|"
        r"media\s+(?:kit|coverage|partnership)|"
        r"PR\s+(?:campaigns?|agency|services)|communication\s+agency|"
        r"agence\s+(?:de\s+)?(?:communication|presse|PR))\b", re.IGNORECASE),
    # Real estate / investment / B2B
    re.compile(
        r"\b(immobilier|real\s+estate|programme\s+(?:immobilier|ICADE)|"
        r"investissement|promoteur|promotrice|lot\s+\d|copropriété|"
        r"b2b|wholesale|bulk\s+(?:booking|order|rate))\b", re.IGNORECASE),
    # Marketing newsletters / mass emails
    re.compile(
        r"\b(view\s+(?:this\s+)?(?:email\s+)?in\s+(?:your\s+)?browser|"
        r"se\s+d[eé]sinscrire|unsubscribe|"
        r"cet\s+e-?mail\s+a\s+[eé]t[eé]\s+envoy[eé]\s+par)\b", re.IGNORECASE),
]

# Known suppliers / vendors / partners — these are NOT hotel guests.
# Their emails should be ignored entirely (no AI response, no escalation).
_SUPPLIER_EMAILS: set[str] = {
    "instant.floral@yahoo.com",        # Fleuriste
    "slinet@assistance97.fr",          # Assistance 97 (prestataire technique)
    "groupage.maritime@sas-sxm.com",  # Groupage Maritime (logistique)
}
# ---------------------------------------------------------------------------
# Rate limiting: max emails per sender per hour
# ---------------------------------------------------------------------------
_RATE_LIMIT = 10
_RATE_WINDOW = 3600  # 1 hour in seconds
_sender_timestamps: dict[str, list[float]] = defaultdict(list)


def _is_rate_limited(from_email: str) -> bool:
    """Check if sender has exceeded rate limit."""
    now = time.monotonic()
    key = from_email.lower().strip()

    # Clean old timestamps
    _sender_timestamps[key] = [
        ts for ts in _sender_timestamps[key] if now - ts < _RATE_WINDOW
    ]

    if len(_sender_timestamps[key]) >= _RATE_LIMIT:
        return True

    _sender_timestamps[key].append(now)
    return False


_SUPPLIER_DOMAINS: set[str] = {
    "hm2.tripadvisor.com",             # Rapports automatiques TripAdvisor
    "tripadvisor.com",                 # TripAdvisor (+ subdomains via endswith check)
    "mrandmrssmith.com",              # Mr & Mrs Smith (plateforme résa)
    "app.siteminder.com",             # SiteMinder (channel manager)
    "tablethotels.com",               # Tablet Hotels (newsletters)
    "tablet.com",                     # Tablet Hotels
    "belcost.com",                    # Belcost (villas Méditerranée)
    "sas-sxm.com",                   # SAS SXM (logistique Saint-Martin)
    "pixellweb.com",                 # Pixellweb (tracking colis SAS SXM)
    "sumup.com",                     # SumUp (paiements / factures)
    "notification.sumup.com",        # SumUp notifications
    "expediagroup.com",              # Expedia collections/factures
    "bred.fr",                       # BRED Banque — confirmations de virement
    "brevosend.com",                 # Brevo/Sendinblue — newsletters marketing
    "laredoute.fr",                  # La Redoute — service client / commandes
    "laredoutebusiness.com",         # La Redoute Business — mobilier pro
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
    if await is_already_processed(email.outlook_message_id):
        return {"status": "already_processed", "email_id": email.outlook_message_id}

    # Check retry count — if we've already failed too many times, give up
    attempt = _retry_counts.get(email.outlook_message_id, 0)
    if attempt >= _MAX_RETRIES:
        log.error(
            "pipeline.max_retries_exceeded",
            email_id=email.outlook_message_id,
            from_email=email.from_email,
            attempts=attempt,
        )
        await _save_processed_id(email.outlook_message_id)
        return {"status": "error", "email_id": email.outlook_message_id, "error": "max retries exceeded"}

    _retry_counts[email.outlook_message_id] = attempt + 1

    try:
        # Clear tool session state from any previous run
        clear_session_state()

        # ── 2. PARSE — strip HTML, extract plain text ──
        body_text = _parse_body(email)
        detected_lang = detect_language(body_text)
        log.info("pipeline.parse", from_email=email.from_email, language=detected_lang,
                 subject=email.subject)

        # ── 3. VALIDATE — skip spam, auto-replies, internal ──
        if _should_skip(email):
            await _save_processed_id(email.outlook_message_id)
            log.info("pipeline.skipped", reason="auto-reply or internal", from_email=email.from_email)
            result["status"] = "skipped"
            return result

        # ── 3b. RATE LIMIT — prevent spam/abuse from burning API budget ──
        if _is_rate_limited(email.from_email):
            log.warning("pipeline.rate_limited", from_email=email.from_email)
            return {"status": "rate_limited", "from": email.from_email}

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
        deferred_escalation = None  # Option B: AI drafts first, escalate after

        if pre_esc:
            if pre_esc.reason == EscalationReason.BOOKING_MODIFICATION.value:
                # Option B: let AI generate a short draft, then escalate
                deferred_escalation = pre_esc
                log.info("pipeline.deferred_escalation",
                         reason=pre_esc.reason, detail=pre_esc.details)
            else:
                # All other reasons: block immediately (complaints, payment, etc.)
                await _handle_escalation(
                    exc=pre_esc,
                    conversation=conversation,
                    client=client,
                    msg_record=msg_record,
                    body_text=body_text,
                )
                try:
                    await outlook.mark_as_read(email.outlook_message_id)
                except Exception:
                    pass
                await _save_processed_id(email.outlook_message_id)
                result["status"] = "escalated"
                result["reason"] = pre_esc.reason
                return result

        # ── 9-10. KNOWLEDGE + EXAMPLES — handled inside ai_engine ──

        # Fetch conversation history for context
        conv_messages = await db.get_conversation_messages(conversation["id"], limit=10)

        # Thread dedup: if a recent outbound message exists in this conversation,
        # skip processing (Marion or the AI already replied to this thread)
        if conv_messages and email.received_at:
            received_iso = email.received_at.isoformat() if email.received_at else ""
            recent_outbound = [
                m for m in conv_messages
                if m.get("direction") == "outbound"
                and m.get("created_at", "") > received_iso
            ]
            if recent_outbound:
                log.info(
                    "pipeline.skipped_already_replied",
                    from_email=email.from_email,
                    conversation_id=conversation["id"],
                )
                await _save_processed_id(email.outlook_message_id)
                result["status"] = "skipped"
                result["reason"] = "already_replied_in_thread"
                return result

        # ── 11. AI GENERATE — Claude tool_use loop ──
        escalation_hint = None
        if deferred_escalation:
            escalation_hint = (
                f"Ce client demande une MODIFICATION/ANNULATION de réservation "
                f"({deferred_escalation.details}). L'équipe va s'en occuper. "
                f"Écris juste un accusé de réception bref et chaleureux."
            )

        ai_response = await ai_engine.generate_response(
            email_body=body_text,
            email_subject=email.subject or "",
            from_email=email.from_email,
            detected_language=detected_lang,
            rules=rules,
            client_context=client,
            conversation_history=conv_messages,
            escalation_hint=escalation_hint,
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
            # Create Outlook draft EVEN on post-escalation so Emmanuel can edit & send
            response_html = _text_to_html(ai_response.response_text)
            try:
                draft_id = await outlook.create_draft_reply(
                    email.outlook_message_id, response_html,
                )
                log.info(
                    "pipeline.post_escalation_draft_created",
                    draft_id=draft_id,
                    from_email=email.from_email,
                    reason=post_esc.reason,
                )
            except Exception as draft_exc:
                log.error("pipeline.post_escalation_draft_failed", error=str(draft_exc))
                draft_id = None

            await _handle_escalation(
                exc=post_esc,
                conversation=conversation,
                client=client,
                msg_record=msg_record,
                body_text=body_text,
                ai_draft=ai_response.response_text,
            )
            # Still save the AI draft for reference
            await db.update_message(msg_record["id"], {
                "ai_draft": ai_response.response_text,
                "confidence_score": round(final_score, 2),
                "tokens_input": ai_response.tokens_input,
                "tokens_output": ai_response.tokens_output,
                "response_time_ms": ai_response.response_time_ms,
                "category": ai_response.category,
            })
            try:
                await outlook.mark_as_read(email.outlook_message_id)
            except Exception:
                pass
            await _save_processed_id(email.outlook_message_id)
            result["status"] = "escalated"
            result["reason"] = post_esc.reason
            return result

        # ── 14. DELIVER — create draft reply (Emmanuel reviews and sends) ──
        cost = compute_cost_eur(
            settings.anthropic_model,
            ai_response.tokens_input,
            ai_response.tokens_output,
        )
        response_html = _text_to_html(ai_response.response_text)

        # DRAFT MODE: create a draft reply in Outlook for Emmanuel to review
        draft_id = None
        try:
            draft_id = await outlook.create_draft_reply(
                email.outlook_message_id, response_html,
            )
            log.info(
                "pipeline.draft_created",
                draft_id=draft_id,
                from_email=email.from_email,
                subject=email.subject,
                confidence=round(final_score, 2),
            )
        except Exception as draft_exc:
            log.error(
                "pipeline.draft_creation_failed",
                error=str(draft_exc),
                from_email=email.from_email,
            )

        # Save outbound message (with Outlook draft ID if created)
        await db.create_message({
            "conversation_id": conversation["id"],
            "outlook_message_id": draft_id,
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

        # ── 14b. DEFERRED ESCALATION — draft created, now notify Emmanuel ──
        if deferred_escalation:
            await _handle_escalation(
                exc=deferred_escalation,
                conversation=conversation,
                client=client,
                msg_record=msg_record,
                body_text=body_text,
                ai_draft=ai_response.response_text,
            )
            log.info(
                "pipeline.deferred_escalation_sent",
                reason=deferred_escalation.reason,
                draft_id=draft_id,
            )

        # ── 14c. TEAM ACTIONS — notify Emmanuel of follow-up tasks ──
        team_actions = get_pending_team_actions()
        if team_actions:
            client_name = f"{client.get('first_name', '')} {client.get('last_name', '')}".strip()
            for action in team_actions:
                try:
                    await notify_team_action(
                        conversation_id=conversation["id"],
                        client_email=client.get("email", ""),
                        client_name=client_name,
                        action=action["action"],
                        partner_name=action.get("partner_name", ""),
                        urgency=action.get("urgency", "normal"),
                        original_email=body_text,
                        ai_draft=ai_response.response_text,
                    )
                except Exception as notif_exc:
                    log.error("pipeline.team_action_notify_failed", error=str(notif_exc))
            log.info("pipeline.team_actions_sent", count=len(team_actions))

        # ── 15. TRACK — mark as read so it doesn't reappear ──
        try:
            await outlook.mark_as_read(email.outlook_message_id)
        except Exception as mark_exc:
            log.error("pipeline.mark_read_failed", error=str(mark_exc))
        await _save_processed_id(email.outlook_message_id)

        log.info(
            "pipeline.complete",
            from_email=email.from_email,
            category=ai_response.category,
            confidence=round(final_score, 2),
            tools=ai_response.tools_used,
            cost_eur=cost,
            response_time_ms=ai_response.response_time_ms,
            deferred_escalation=deferred_escalation is not None,
        )

        result["confidence"] = round(final_score, 2)
        result["category"] = ai_response.category
        result["tools_used"] = ai_response.tools_used
        result["cost_eur"] = cost
        if deferred_escalation:
            result["deferred_escalation"] = deferred_escalation.reason

        # Success — clear retry counter
        _retry_counts.pop(email.outlook_message_id, None)

    except EscalationRequired as exc:
        log.warning("pipeline.escalation", reason=exc.reason, details=exc.details)
        result["status"] = "escalated"
        result["reason"] = exc.reason
    except ConciergeError as exc:
        log.error("pipeline.error", error=str(exc), email_id=email.outlook_message_id)
        # If we already stored the message (step 6+), save as processed to avoid infinite retry
        if attempt + 1 >= _MAX_RETRIES:
            log.error("pipeline.giving_up_after_retries", email_id=email.outlook_message_id)
            await _save_processed_id(email.outlook_message_id)
        result["status"] = "error"
        result["error"] = str(exc)
    except Exception as exc:
        log.exception("pipeline.unexpected_error", email_id=email.outlook_message_id)
        # If we already stored the message (step 6+), save as processed to avoid infinite retry
        if attempt + 1 >= _MAX_RETRIES:
            log.error("pipeline.giving_up_after_retries", email_id=email.outlook_message_id)
            await _save_processed_id(email.outlook_message_id)
        result["status"] = "error"
        result["error"] = str(exc)

    return result


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _parse_body(email: InboundEmail) -> str:
    """Extract clean text from the email (full thread -- used for AI context)."""
    if email.body_html:
        soup = BeautifulSoup(email.body_html, "html.parser")
        for tag in soup(["script", "style", "head"]):
            tag.decompose()
        text = soup.get_text(separator="\n", strip=True)
    else:
        text = email.body_text

    text = re.sub(r"\n{3,}", "\n\n", text)
    text = re.sub(r"[ \t]+", " ", text)
    text = text.strip()

    # Attachment awareness — detect if the original HTML contains attachment indicators
    if email.body_html and _has_attachment_indicators(email.body_html):
        text = "[Note: cet email contient des pièces jointes qui ne sont pas visibles ici]\n\n" + text

    # Truncate to avoid blowing up token counts (~2000 tokens)
    if len(text) > _MAX_BODY_CHARS:
        log.warning("pipeline.body_truncated", original_len=len(text), max_len=_MAX_BODY_CHARS)
        text = text[:_MAX_BODY_CHARS] + "\n\n[...contenu tronqué...]"

    return text


def _has_attachment_indicators(html: str) -> bool:
    """Check if raw HTML/headers contain signs of attachments."""
    indicators = [
        'Content-Disposition: attachment',
        'Content-Disposition:attachment',
        'filename=',
        'cid:image',  # inline images that are actual attachments
    ]
    html_lower = html.lower()
    return any(ind.lower() in html_lower for ind in indicators)


def _extract_latest_message(email: InboundEmail) -> str:
    """Extract ONLY the latest message (no quoted thread) -- used for escalation detection."""
    if email.body_html:
        soup = BeautifulSoup(email.body_html, "html.parser")
        for tag in soup(["script", "style", "head"]):
            tag.decompose()

        # Remove Outlook / Gmail quoted replies
        for tag in soup.select('div#appendonsend, div.gmail_quote, blockquote'):
            tag.decompose()

        # Apple Mail: remove quoted content
        for tag in soup.select('div.AppleOriginalContents, blockquote[type="cite"]'):
            tag.decompose()

        # Thunderbird: remove citation prefix block
        for tag in soup.select('div.moz-cite-prefix'):
            # Remove the prefix AND everything after it (the quoted text)
            for sibling in list(tag.find_next_siblings()):
                sibling.decompose()
            tag.decompose()

        # Yahoo Mail: remove quoted block
        for tag in soup.select('div.yahoo_quoted'):
            tag.decompose()

        # Remove everything after the first <hr> (Outlook / Samsung Mail / Outlook Mobile thread separator)
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
    text = text.strip()

    # Truncate latest message to keep escalation detection fast
    if len(text) > _MAX_LATEST_MSG_CHARS:
        log.warning("pipeline.latest_msg_truncated", original_len=len(text), max_len=_MAX_LATEST_MSG_CHARS)
        text = text[:_MAX_LATEST_MSG_CHARS]

    return text


def _should_skip(email: InboundEmail) -> bool:
    """Check if this email should be skipped."""
    from_lower = email.from_email.lower()

    # Skip known suppliers / vendors / partners
    if from_lower in _SUPPLIER_EMAILS:
        log.info("pipeline.skipped_supplier", from_email=email.from_email, reason="known supplier email")
        return True
    from_domain = from_lower.split("@", 1)[-1]
    if from_domain in _SUPPLIER_DOMAINS or any(
        from_domain.endswith("." + sd) for sd in _SUPPLIER_DOMAINS
    ):
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

    # Skip non-guest content: job applications, ads, press, real estate, B2B
    # Use parsed body if available (HTML emails may have empty body_text)
    body_for_check = email.body_text
    if not body_for_check and email.body_html:
        soup = BeautifulSoup(email.body_html, "html.parser")
        for tag in soup(["script", "style", "head"]):
            tag.decompose()
        body_for_check = soup.get_text(separator=" ", strip=True)
    search_text = f"{email.subject or ''} {body_for_check}"
    for pattern in _NON_GUEST_PATTERNS:
        if pattern.search(search_text):
            log.info(
                "pipeline.skipped_non_guest",
                from_email=email.from_email,
                subject=email.subject,
                pattern=pattern.pattern[:60],
            )
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
    ai_draft: str = "",
) -> None:
    """Store escalation and notify Emmanuel by email."""
    # Update conversation status
    await db.update_conversation(conversation["id"], {"status": "escalated", "assignee": "emmanuel"})

    # Create escalation record
    await db.create_escalation({
        "conversation_id": conversation["id"],
        "message_id": msg_record.get("id"),
        "reason": exc.reason,
        "details": exc.details,
    })

    # Send notification email to Emmanuel
    client_name = f"{client.get('first_name', '')} {client.get('last_name', '')}".strip()
    try:
        await notify_escalation(
            conversation_id=conversation["id"],
            client_email=client.get("email", ""),
            client_name=client_name,
            reason=exc.reason,
            details=exc.details,
            original_email=body_text,
            ai_draft=ai_draft,
        )
    except Exception as notif_exc:
        log.error("pipeline.escalation_notify_failed", error=str(notif_exc))

    log.info(
        "pipeline.escalated",
        client_email=client.get("email", ""),
        client_name=client_name,
        reason=exc.reason,
        details=exc.details,
    )
