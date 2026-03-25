"""Pre/post escalation detection + notification email to Emmanuel."""

from __future__ import annotations

import html
import re

import structlog

from src.config import settings
from src.exceptions import EscalationRequired
from src.models.enums import EscalationReason
from src.services import outlook

log = structlog.get_logger()

# ---------------------------------------------------------------------------
# Negation detection — skip matches preceded by negation words
# ---------------------------------------------------------------------------

_NEGATION_PATTERNS = re.compile(
    r"\b("
    # French negations — "ne ... pas" with verb in between (ne suis pas, n'est pas, etc.)
    r"ne\b.{0,20}\bpas|n'\w+\s+pas|\bpas\b|aucun|sans|non|jamais"
    r"|"
    # English negations
    r"not|no|don'?t|doesn'?t|didn'?t|won'?t|never|neither|without"
    r")\b",
    re.IGNORECASE,
)


def _is_negated(text: str, match: re.Match) -> bool:
    """Return True if the match is preceded by a negation word within ~50 chars."""
    start = max(0, match.start() - 50)
    prefix = text[start: match.start()]
    return bool(_NEGATION_PATTERNS.search(prefix))


# ---------------------------------------------------------------------------
# Pre-AI escalation patterns (applied BEFORE generating a response)
# ---------------------------------------------------------------------------

# Context words that must appear near "modification" or "cancel" to trigger
_BOOKING_CONTEXT = re.compile(
    r"\b(reservation|réservation|booking|séjour|stay)\b", re.IGNORECASE
)

_PRE_PATTERNS: list[tuple[re.Pattern, EscalationReason, str]] = [
    # Complaints / disputes
    (re.compile(
        r"\b(plainte|réclamation|remboursement|refund|complain\w*|dispute|déçu|disappointed|"
        r"unacceptable|inacceptable|terrible|worst|horrible|furious|furieux|avocat|lawyer|"
        r"litige|procès|arnaque|scam"
        r"|queja|reembolso"       # Spanish
        r"|klacht|terugbetaling"  # Dutch
        r"|Beschwerde|Erstattung" # German
        r")\b", re.IGNORECASE),
     EscalationReason.COMPLAINT,
     "Plainte ou litige détecté"),

    # Booking modifications / cancellations — with context requirements
    # "modification" requires nearby booking context
    # "cancel" requires nearby booking context
    # "report" removed (too many false positives — kept "postpone" and "décaler")
    (re.compile(
        r"(annuler\b|cancel\w*\s+.{0,20}\b(?:reservation|réservation|booking|séjour)\b"
        r"|modifier?\s+(?:ma\s+|my\s+)?réservation|change\s+(?:my\s+|the\s+)?booking"
        r"|\bmodification\b.{0,30}\b(?:reservation|réservation|booking|séjour)\b"
        r"|décaler|postpone|move\s+my\s+(?:booking|reservation))", re.IGNORECASE),
     EscalationReason.BOOKING_MODIFICATION,
     "Demande de modification/annulation"),

    # Payment issues — only genuine payment PROBLEMS (not generic "invoice" or "facture")
    (re.compile(
        r"\b(carte\s+(?:refus[eé]e|declined)|"
        r"lien\s+(?:cass[eé]|broken)|montant\s+(?:incorrect|wrong)|overcharg\w*|"
        r"d[eé]bit[eé]\s+(?:deux|twice|2)\s+fois|double\s+charge|trop\s+pay[eé]|overpaid|"
        r"paiement\s+(?:refus[eé]|echou[eé]|failed)|payment\s+(?:failed|declined|issue|problem))\b",
        re.IGNORECASE),
     EscalationReason.PAYMENT_ISSUE,
     "Problème de paiement détecté"),

    # Group / privatization
    (re.compile(
        r"(privatis|exclusive|entire\s+hotel|tout\s+l'hôtel|group\s+of\s+\d{2,}|"
        r"groupe\s+de\s+\d{2,}|séminaire|seminar|team\s+building|événement|"
        r"mariage.{0,20}(?:hôtel|hotel)|wedding.{0,20}(?:hotel|venue))", re.IGNORECASE),
     EscalationReason.PRIVATIZATION,
     "Privatisation ou événement détecté"),

    # Large groups (5+ people, 3+ families/couples, or 4+ rooms)
    (re.compile(
        r"(?:\b[5-9]\b|\b\d{2,}\b)\s*(?:personnes|persons|people|guests|adultes|adults|pax)|"
        r"(?:\b[3-9]\b|\b\d{2,}\b)\s*(?:familles|families|couples)|"
        r"(?:\b[4-9]\b|\b\d{2,}\b)\s*(?:chambres|rooms|suites|habitaciones|Zimmer)|"
        r"\b(?:quatre|cinq|six|sept|huit|neuf|dix)\s+(?:chambres|suites)|"
        r"\b(?:four|five|six|seven|eight|nine|ten)\s+(?:rooms|suites)",
        re.IGNORECASE),
     EscalationReason.GROUP_REQUEST,
     "Groupe de 5+ personnes ou 4+ chambres"),

    # Cancellation threats via OTA
    (re.compile(
        r"(cancel.{0,30}(?:expedia|booking\.com|airbnb|vrbo|hotels\.com|agoda)|"
        r"(?:expedia|booking\.com).{0,30}cancel|"
        r"dispute\s+(?:the\s+)?charge)", re.IGNORECASE),
     EscalationReason.BOOKING_MODIFICATION,
     "Menace d'annulation via OTA"),

    # Out of scope — only patterns NOT already caught by the skip filter
    # (job, press, ads, B2B are now skipped entirely in _should_skip)
]


def check_pre_escalation(email_body: str, email_subject: str = "") -> EscalationRequired | None:
    """Check if the email should be escalated BEFORE AI processing."""
    text = f"{email_subject} {email_body}"
    for pattern, reason, detail in _PRE_PATTERNS:
        match = pattern.search(text)
        if match and not _is_negated(text, match):
            log.warning("escalation.pre_detected", reason=reason.value, detail=detail)
            return EscalationRequired(reason=reason.value, details=detail)
    return None


# ---------------------------------------------------------------------------
# Post-AI escalation check
# ---------------------------------------------------------------------------

# Matches the AI explicitly requesting escalation to a human — NOT rock
# climbing ("escalade") or casual use of the word.
_POST_ESCALATION_RE = re.compile(
    r"(?:"
    r"\bescalad(?:e|er|ion)\b.{0,40}\b(?:emmanuel|équipe|team|humain|human)\b"
    r"|transférer\s+à\s+emmanuel"
    r"|forward\s+to\s+emmanuel"
    r")",
    re.IGNORECASE,
)


# Post-generation content checks — detect rule violations in the AI draft
_INTERNAL_ROOM_NAMES_RE = re.compile(
    r"\b(?:Suite\s+|Chambre\s+)?"
    r"(Marius|Marcelle|Pierre|René|Rene|Marthe|Georgette)\b",
    re.IGNORECASE,
)

_WALKABLE_RESTAURANT_RE = re.compile(
    r"(?:"
    r"\d+[- ]?min\w*\s+walk.{0,60}(?:restaurant|dinner|dining|lunch|dîner|déjeuner)"
    r"|(?:restaurant|dinner|dining|lunch|dîner|déjeuner).{0,60}\d+[- ]?min\w*\s+walk"
    r"|walk\w*\s+to\s+(?:several\s+)?(?:excellent\s+)?restaurant"
    r"|(?:restaurant|dîner)\s+à\s+pied"
    r"|(?:à|a)\s+\d+\s+min\w*\s+à\s+pied.{0,40}(?:restaurant|dîner)"
    r")",
    re.IGNORECASE,
)

_BED_TWINABLE_RE = re.compile(
    r"(?:"
    r"(?:configur|convert|split|separ|sépar).{0,40}(?:twin|single|individu|jumeau|jumelles)"
    r"|(?:twin|single)\s+bed\s+configur"
    r"|(?:lit|bed).{0,20}(?:séparab|separab)"
    r")",
    re.IGNORECASE,
)

_INVENTED_DISCOUNT_RE = re.compile(
    r"(?:"
    r"\d+%\s+(?:returning|loyalty|repeat|fidél)\w*\s+(?:guest\s+)?(?:discount|réduction|remise)"
    r"|(?:returning|loyalty|repeat|fidél)\w*\s+(?:guest\s+)?(?:discount|réduction|remise)\s+(?:of\s+)?\d+%"
    r")",
    re.IGNORECASE,
)

_META_COMMENTARY_RE = re.compile(
    r"(?:"
    r"(?:Cet|This)\s+(?:email|e-mail|message)\s+(?:est|is)\s+(?:un|une|a|an)"
    r"|BROUILLON\s+SUPERVIS[EÉ]"
    r"|Note\s+interne"
    r"|Aucune\s+r[eé]ponse\s+n(?:'|')est\s+n[eé]cessaire"
    r"|(?:doesn't|does not|don't)\s+appear\s+in\s+my\s+(?:database|system|data)"
    r"|(?:n'apparai|ne figure)\s+pas\s+dans\s+(?:ma|mes|la)\s+(?:base|donn)"
    r"|Je\s+(?:g[eé]n[eè]re|r[eé]dige)\s+un\s+brouillon"
    r"|draft\s+for\s+review"
    r"|Il\s+s'agit\s+d(?:'|')un"
    r"|Je\s+recommande\s+de\s+(?:le\s+)?transmettre"
    r")",
    re.IGNORECASE,
)

# Distances without specifying transport mode (e.g. "3 minutes away" without "by car")
_MISSING_TRANSPORT_RE = re.compile(
    r"\d+\s*min\w*\s*(away|d'ici|depuis|from)\b(?!.{0,20}\b(?:voiture|car|drive|taxi|bus|walk|pied|marche)\b)",
    re.IGNORECASE,
)

# Fabricated availability claims — AI should not claim "complet" without tool data
_FABRICATED_AVAILABILITY_RE = re.compile(
    r"(?:"
    r"\b(?:complet|complets|fully\s+booked|no\s+availability|aucune\s+disponibilit)"
    r"|nous\s+(?:sommes|serons)\s+(?:par\s+ailleurs\s+)?complets?"
    r"|(?:hotel|hôtel)\s+(?:is|est)\s+(?:fully?\s+)?(?:booked|complet)"
    r")",
    re.IGNORECASE,
)

# Markdown formatting that should never appear in a plain email
_MARKDOWN_RE = re.compile(
    r"(?:"
    r"\*\*\w"               # **bold text
    r"|^#{1,3}\s"           # # headings
    r"|\n[-*]\s"            # - bullet lists
    r"|\n\d+\.\s"          # 1. numbered lists
    r"|```"                 # code blocks
    r")",
    re.MULTILINE,
)

# Partner names that must NEVER appear in client-facing responses (commission risk)
_PARTNER_NAMES_RE = re.compile(
    r"\b(Scoobi\s*Too|Escale\s*Car\s*Rental|Hopfit(?:\s*Hope\s*Estate)?"
    r"|Bubble\s*Shop|Lottery\s*Farm|Great\s*Bay\s*Express)\b",
    re.IGNORECASE,
)


def check_post_escalation(
    response_text: str,
    confidence_score: float,
    threshold: float | None = None,
) -> EscalationRequired | None:
    """Check if the AI response should be escalated AFTER generation."""
    threshold = threshold or settings.escalation_confidence_threshold

    if confidence_score < threshold:
        log.warning(
            "escalation.low_confidence",
            score=confidence_score,
            threshold=threshold,
        )
        return EscalationRequired(
            reason=EscalationReason.LOW_CONFIDENCE.value,
            details=f"Score de confiance {confidence_score:.2f} < seuil {threshold}",
        )

    # Check if the AI itself flagged escalation (requiring human reference)
    if _POST_ESCALATION_RE.search(response_text):
        return EscalationRequired(
            reason=EscalationReason.OTHER.value,
            details="L'IA a recommandé une escalation dans sa réponse.",
        )

    # ── Content violation checks (log + warn, don't hard-block) ──
    violations: list[str] = []

    if _INTERNAL_ROOM_NAMES_RE.search(response_text):
        violations.append("Nom interne de chambre détecté (Marius/Marcelle/Pierre/René/Marthe/Georgette)")

    if _PARTNER_NAMES_RE.search(response_text):
        violations.append("Nom de partenaire détecté dans la réponse (risque perte de commission — Scoobi Too, Escale, Hopfit, etc.)")

    if _WALKABLE_RESTAURANT_RE.search(response_text):
        violations.append("Restaurant décrit comme accessible à pied depuis l'hôtel")

    if _BED_TWINABLE_RE.search(response_text):
        violations.append("Lit décrit comme séparable/configurable en twin")

    if _INVENTED_DISCOUNT_RE.search(response_text):
        violations.append("Réduction non standard détectée (ex: returning guest discount)")

    if _META_COMMENTARY_RE.search(response_text):
        violations.append("Meta-commentary détecté dans la réponse (l'IA parle d'elle-même au lieu d'écrire au client)")

    if _MISSING_TRANSPORT_RE.search(response_text):
        violations.append("Distance sans mode de transport ('X minutes away' sans préciser 'by car'/'en voiture')")

    if _MARKDOWN_RE.search(response_text):
        violations.append("Formatage markdown détecté (bold, titres, listes) — interdit dans un email")

    # Corporate formulas detection — Marion never uses these
    _CORPORATE_PHRASES = [
        "wonderful news", "what wonderful", "perfect timing",
        "i'm delighted", "happy to pull this together",
        "n'hésitez pas", "quel beau projet", "laissez-moi vous expliquer",
        "merci pour votre message", "je vous recommande de vous rapprocher",
    ]
    lower_response = response_text.lower()
    corporate_found = [p for p in _CORPORATE_PHRASES if p in lower_response]
    if len(corporate_found) >= 2:
        violations.append(f"Formules corporate détectées ({', '.join(corporate_found)})")

    # Fabricated availability — claiming "complet"/"fully booked" without tool evidence
    if _FABRICATED_AVAILABILITY_RE.search(response_text):
        log.warning("escalation.possible_availability_fabrication")
        violations.append("Affirmation 'complet/fully booked' détectée — vérifier si basée sur un appel outil")

    # Word count check (Marion writes short emails — 3-5 phrases)
    word_count = len(response_text.split())
    if word_count > 250:
        violations.append(f"Réponse trop longue ({word_count} mots, max 250)")
    elif word_count > 150:
        log.warning("escalation.response_long", word_count=word_count)

    if violations:
        detail = " | ".join(violations)
        log.warning("escalation.content_violations", violations=violations)
        return EscalationRequired(
            reason=EscalationReason.OTHER.value,
            details=f"Violations de contenu : {detail}",
        )

    return None


# ---------------------------------------------------------------------------
# Notification
# ---------------------------------------------------------------------------

async def notify_team_action(
    *,
    conversation_id: str,
    client_email: str,
    client_name: str,
    action: str,
    partner_name: str = "",
    urgency: str = "normal",
    original_email: str = "",
    ai_draft: str = "",
) -> None:
    """Send a team action notification email to Emmanuel.

    Includes the full context: action requested, AI draft response,
    and the original client email so Emmanuel doesn't have to search.
    """
    safe_name = html.escape(client_name or "")
    safe_email = html.escape(client_email or "")
    safe_action = html.escape(action)
    safe_partner = html.escape(partner_name)
    safe_conv_id = html.escape(conversation_id)

    urgency_label = "URGENT" if urgency == "urgent" else "ACTION"
    partner_line = f"<p><strong>Partenaire :</strong> {safe_partner}</p>" if safe_partner else ""

    # AI draft section
    ai_draft_section = ""
    if ai_draft:
        safe_draft = html.escape(ai_draft[:3000])
        ai_draft_section = f"""
    <h3>Brouillon IA (réponse au client) :</h3>
    <blockquote style="border-left:3px solid #2196F3;padding:8px 12px;margin:8px 0;background:#f5f5f5;">{safe_draft}</blockquote>
    """

    # Original client email section
    original_section = ""
    if original_email:
        safe_original = html.escape(original_email[:3000])
        original_section = f"""
    <h3>Email original du client :</h3>
    <blockquote style="border-left:3px solid #FF9800;padding:8px 12px;margin:8px 0;background:#fff8e1;">{safe_original}</blockquote>
    """

    subject = f"[{urgency_label} IA] {action[:60]} — {client_name or client_email}"
    body = f"""
    <h2>{urgency_label} requise — Le Martin Boutique Hotel</h2>
    <p><strong>Action :</strong> {safe_action}</p>
    {partner_line}
    <hr>
    <p><strong>Client :</strong> {safe_name} ({safe_email})</p>
    <p><strong>Conversation ID :</strong> {safe_conv_id}</p>
    <hr>
    {ai_draft_section}
    {original_section}
    <hr>
    <p><em>L'IA a rédigé un brouillon de réponse au client. Cette notification vous signale une action complémentaire à effectuer.</em></p>
    """
    try:
        for recipient in settings.escalation_emails:
            await outlook.send_email(
                to=recipient,
                subject=subject,
                body_html=body,
            )
        log.info("team_action.notified", to=settings.escalation_emails, action=action)
    except Exception as exc:
        log.error("team_action.notify_failed", error=str(exc))


async def notify_escalation(
    *,
    conversation_id: str,
    client_email: str,
    client_name: str,
    reason: str,
    details: str,
    original_email: str,
    ai_draft: str = "",
) -> None:
    """Send an escalation notification email to Emmanuel.

    Includes the original client email and, when available, the AI draft
    response so Emmanuel has full context without searching.
    """
    # HTML-escape all user-supplied strings to prevent injection
    safe_name = html.escape(client_name or "")
    safe_email = html.escape(client_email or "")
    safe_reason = html.escape(reason)
    safe_details = html.escape(details)
    safe_original = html.escape(original_email[:3000])
    safe_conversation_id = html.escape(conversation_id)

    # AI draft section (available for deferred escalations and post-escalations)
    ai_draft_section = ""
    if ai_draft:
        safe_draft = html.escape(ai_draft[:3000])
        ai_draft_section = f"""
    <h3>Brouillon IA (réponse au client) :</h3>
    <blockquote style="border-left:3px solid #2196F3;padding:8px 12px;margin:8px 0;background:#f5f5f5;">{safe_draft}</blockquote>
    """

    subject = f"[ESCALATION IA] {reason} — {client_name or client_email}"
    body = f"""
    <h2>Escalation IA — Le Martin Boutique Hotel</h2>
    <p><strong>Raison :</strong> {safe_reason}</p>
    <p><strong>Détails :</strong> {safe_details}</p>
    <hr>
    <p><strong>Client :</strong> {safe_name} ({safe_email})</p>
    <p><strong>Conversation ID :</strong> {safe_conversation_id}</p>
    <hr>
    {ai_draft_section}
    <h3>Email original du client :</h3>
    <blockquote style="border-left:3px solid #FF9800;padding:8px 12px;margin:8px 0;background:#fff8e1;">{safe_original}</blockquote>
    <hr>
    <p><em>Ce message a été généré automatiquement par le système IA concierge.</em></p>
    """
    try:
        for recipient in settings.escalation_emails:
            await outlook.send_email(
                to=recipient,
                subject=subject,
                body_html=body,
            )
        log.info("escalation.notified", to=settings.escalation_emails, reason=reason)
    except Exception as exc:
        log.error("escalation.notify_failed", error=str(exc))
