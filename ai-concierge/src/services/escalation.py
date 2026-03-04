"""Pre/post escalation detection + notification email to Emmanuel."""

from __future__ import annotations

import re

import structlog

from src.config import settings
from src.exceptions import EscalationRequired
from src.models.enums import EscalationReason
from src.services import outlook

log = structlog.get_logger()

# ---------------------------------------------------------------------------
# Pre-AI escalation patterns (applied BEFORE generating a response)
# ---------------------------------------------------------------------------

_PRE_PATTERNS: list[tuple[re.Pattern, EscalationReason, str]] = [
    # Complaints / disputes
    (re.compile(
        r"(plainte|réclamation|remboursement|refund|complain|dispute|déçu|disappointed|"
        r"unacceptable|inacceptable|terrible|worst|horrible|furious|furieux|avocat|lawyer|"
        r"litige|procès|arnaque|scam)", re.IGNORECASE),
     EscalationReason.COMPLAINT,
     "Plainte ou litige détecté"),

    # Booking modifications / cancellations
    (re.compile(
        r"(annuler|cancel|modifier? (ma |my )?réservation|change (my |the )?booking|"
        r"modification|décaler|report|postpone|move my (booking|reservation))", re.IGNORECASE),
     EscalationReason.BOOKING_MODIFICATION,
     "Demande de modification/annulation"),

    # Payment issues
    (re.compile(
        r"(paiement|payment|facture|invoice|carte (refusée|declined)|"
        r"lien (cassé|broken)|montant (incorrect|wrong)|overcharg|"
        r"débité|charged|trop payé|overpaid)", re.IGNORECASE),
     EscalationReason.PAYMENT_ISSUE,
     "Problème de paiement détecté"),

    # Group / privatization
    (re.compile(
        r"(privatis|exclusive|entire hotel|tout l'hôtel|group of \d{2,}|"
        r"groupe de \d{2,}|séminaire|seminar|team building|event|événement|"
        r"mariage.{0,20}(hôtel|hotel)|wedding.{0,20}(hotel|venue))", re.IGNORECASE),
     EscalationReason.PRIVATIZATION,
     "Privatisation ou événement détecté"),

    # Large groups (5+ people)
    (re.compile(
        r"(\b[5-9]\b|\b\d{2,}\b)\s*(personnes|persons|people|guests|adultes|adults|pax)",
        re.IGNORECASE),
     EscalationReason.GROUP_REQUEST,
     "Groupe de 5+ personnes"),

    # Out of scope
    (re.compile(
        r"(partenariat|partnership|sponsor|presse|press|journaliste|journalist|"
        r"emploi|job|recrutement|recruitment|candidature|application|"
        r"commercial|b2b|wholesale)", re.IGNORECASE),
     EscalationReason.OUT_OF_SCOPE,
     "Sujet hors périmètre hôtelier"),
]


def check_pre_escalation(email_body: str, email_subject: str = "") -> EscalationRequired | None:
    """Check if the email should be escalated BEFORE AI processing."""
    text = f"{email_subject} {email_body}"
    for pattern, reason, detail in _PRE_PATTERNS:
        if pattern.search(text):
            log.warning("escalation.pre_detected", reason=reason.value, detail=detail)
            return EscalationRequired(reason=reason.value, details=detail)
    return None


# ---------------------------------------------------------------------------
# Post-AI escalation check
# ---------------------------------------------------------------------------

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

    # Check if the AI itself flagged escalation
    if re.search(r"(escalad|transférer à emmanuel|forward to emmanuel)", response_text, re.IGNORECASE):
        return EscalationRequired(
            reason=EscalationReason.OTHER.value,
            details="L'IA a recommandé une escalation dans sa réponse.",
        )

    return None


# ---------------------------------------------------------------------------
# Notification
# ---------------------------------------------------------------------------

async def notify_escalation(
    *,
    conversation_id: str,
    client_email: str,
    client_name: str,
    reason: str,
    details: str,
    original_email: str,
) -> None:
    """Send an escalation notification email to Emmanuel."""
    subject = f"[ESCALATION IA] {reason} — {client_name or client_email}"
    body = f"""
    <h2>Escalation IA — Le Martin Boutique Hotel</h2>
    <p><strong>Raison :</strong> {reason}</p>
    <p><strong>Détails :</strong> {details}</p>
    <hr>
    <p><strong>Client :</strong> {client_name} ({client_email})</p>
    <p><strong>Conversation ID :</strong> {conversation_id}</p>
    <hr>
    <h3>Email original du client :</h3>
    <blockquote>{original_email[:2000]}</blockquote>
    <hr>
    <p><em>Ce message a été généré automatiquement par le système IA concierge.</em></p>
    """
    try:
        await outlook.send_email(
            to=settings.escalation_email,
            subject=subject,
            body_html=body,
        )
        log.info("escalation.notified", to=settings.escalation_email, reason=reason)
    except Exception as exc:
        log.error("escalation.notify_failed", error=str(exc))
