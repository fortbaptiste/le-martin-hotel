"""Confidence scoring — 5 weighted signals."""

from __future__ import annotations

import re

import structlog

from src.models.ai import ConfidenceBreakdown

log = structlog.get_logger()

# Internal room names that must NEVER appear in responses
_INTERNAL_ROOM_NAMES = re.compile(
    r"\b(?:Suite\s+|Chambre\s+)?"
    r"(Marius|Marcelle|Pierre|René|Rene|Marthe|Georgette)\b",
    re.IGNORECASE,
)

# Partner names that must NEVER appear in client-facing responses (commission risk)
_PARTNER_NAMES = re.compile(
    r"\b(Scoobi\s*Too|Escale\s*Car\s*Rental|Hopfit(?:\s*Hope\s*Estate)?"
    r"|Bubble\s*Shop|Lottery\s*Farm|Great\s*Bay\s*Express)\b",
    re.IGNORECASE,
)


def compute_confidence(
    *,
    ai_response_text: str,
    llm_self_score: float,
    tools_used: list[str],
    email_body: str,
    rules_count: int,
    template_used: bool = False,
) -> ConfidenceBreakdown:
    """Compute the 5-signal weighted confidence score.

    Weights (must match ConfidenceBreakdown.weighted_score):
        retrieval_relevance:   0.25
        context_completeness:  0.20
        llm_self_assessment:   0.15
        rule_compliance:       0.25
        template_match:        0.15
    """

    # 1. Retrieval relevance (0.25) — did the AI use the RIGHT tools?
    retrieval = _score_retrieval(tools_used, email_body)

    # 2. Context completeness (0.20) — are all questions in the email addressed?
    completeness = _score_completeness(ai_response_text, email_body)

    # 3. LLM self-assessment (0.15) — Claude's own confidence
    llm_score = min(1.0, max(0.0, llm_self_score))

    # 4. Rule compliance (0.25) — signature present, no internal names, etc.
    compliance = _score_rule_compliance(ai_response_text, rules_count, tools_used)

    # 5. Template match (0.15) — closeness to Marion's style
    template = 0.8 if template_used else _score_template_match(ai_response_text)

    breakdown = ConfidenceBreakdown(
        retrieval_relevance=round(retrieval, 2),
        context_completeness=round(completeness, 2),
        llm_self_assessment=round(llm_score, 2),
        rule_compliance=round(compliance, 2),
        template_match=round(template, 2),
    )

    log.info(
        "confidence.computed",
        score=round(breakdown.weighted_score, 2),
        retrieval=breakdown.retrieval_relevance,
        completeness=breakdown.context_completeness,
        llm=breakdown.llm_self_assessment,
        compliance=breakdown.rule_compliance,
        template=breakdown.template_match,
    )
    return breakdown


# ---------------------------------------------------------------------------
# Signal scorers
# ---------------------------------------------------------------------------

# Topic keywords → relevant tools mapping
_TOPIC_TOOL_MAP: dict[re.Pattern, set[str]] = {
    re.compile(r"\b(price|prix|tarif|rate|availab|disponi|date|nuit|night)\b", re.I): {
        "check_room_availability",
    },
    re.compile(r"\b(restaurant|dîner|dinner|lunch|déjeuner|manger|eat|cuisine)\b", re.I): {
        "search_restaurants",
    },
    re.compile(r"\b(activit|excursion|plage|beach|plongée|diving|snorkel|boat|bateau)\b", re.I): {
        "search_beaches",
        "search_activities",
    },
    re.compile(r"\b(transfer|navette|shuttle|airport|aéroport|taxi)\b", re.I): {
        "get_hotel_services",
        "get_transport_schedules",
        "get_partner_info",
    },
    re.compile(r"\b(room|chambre|suite|family|famille|bed|lit|upgrade|extend|prolonger)\b", re.I): {
        "check_room_availability",
        "get_room_details",
    },
    re.compile(r"\b(spa|massage|yoga|pilates|coaching|facial|wellness|bien.?être|soin)\b", re.I): {
        "get_hotel_services",
    },
}


def _score_retrieval(tools_used: list[str], email_body: str) -> float:
    """Score based on whether the right tools were used for the topic."""
    body_lower = email_body.lower()
    tools_set = set(tools_used)

    # Determine which tools should have been used based on email content
    needed_tools: set[str] = set()
    for topic_re, expected_tools in _TOPIC_TOOL_MAP.items():
        if topic_re.search(body_lower):
            needed_tools.update(expected_tools)

    # Case 1: No tools needed (simple greeting / thank you)
    if not needed_tools:
        is_simple = bool(re.search(
            r"\b(merci|thank|bonjour|hello|hi|salut|hey|bonsoir|good\s+morning|good\s+evening)\b",
            body_lower,
        ))
        if tools_used:
            return 0.9  # Used tools proactively — good
        return 0.7 if is_simple else 0.3

    # Case 2: Tools were needed
    if not tools_set:
        return 0.3  # Needed tools but didn't use any

    matched = needed_tools & tools_set
    if matched:
        # Used at least one relevant tool
        ratio = len(matched) / len(needed_tools)
        return min(1.0, 0.7 + ratio * 0.3)

    # Used some tools, but not the most relevant ones
    return min(1.0, 0.5 + len(tools_used) * 0.1)


def _count_question_sentences(text: str) -> int:
    """Count question sentences — lines or segments ending with '?'."""
    # Split on newlines and common sentence boundaries, then count those ending with ?
    sentences = re.split(r"[.\n!]", text)
    return sum(1 for s in sentences if s.strip().endswith("?"))


def _score_completeness(response: str, email_body: str) -> float:
    """Check if the response addresses questions in the email."""
    questions = _count_question_sentences(email_body)
    if questions == 0:
        return 0.9

    # Simple heuristic: response length relative to number of questions
    words = len(response.split())
    expected_min = questions * 30
    if words >= expected_min:
        return 0.9
    return max(0.6, words / expected_min)


def _score_rule_compliance(
    response: str, rules_count: int, tools_used: list[str]
) -> float:
    """Check basic rule compliance."""
    score = 1.0

    # Must have signature
    has_signature = "marion" in response.lower()
    if not has_signature:
        score -= 0.3

    # Should not contain fabricated price patterns without having used a pricing tool
    price_pattern = re.search(r"\b\d{2,4}\s*€", response)
    pricing_tools = {"check_room_availability", "get_hotel_services", "search_activities"}
    if price_pattern and not (pricing_tools & set(tools_used)):
        score -= 0.15  # Citing price without calling any pricing tool

    # CRITICAL: must never leak internal room names
    if _INTERNAL_ROOM_NAMES.search(response):
        score -= 0.3

    # CRITICAL: must never leak partner names (commission risk)
    if _PARTNER_NAMES.search(response):
        score -= 0.3

    # Should not repeat booking details back unnecessarily (verbose echo)
    booking_echo = re.search(
        r"(?:breakfast\s+included|petit[- ]déjeuner\s+inclus).{0,50}"
        r"(?:february|march|april|may|june|july|august|september|october|november|december"
        r"|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre)",
        response, re.IGNORECASE,
    )
    if booking_echo:
        score -= 0.05  # Minor penalty for unnecessary repetition

    return max(0.0, score)


def _score_template_match(response: str) -> float:
    """Style matching — Marion's real tone: short, warm, direct."""
    lower = response.lower()
    score = 0.7

    # Positive: brevity (short responses are closer to Marion's style)
    word_count = len(response.split())
    if word_count <= 80:
        score += 0.2  # Short and punchy — Marion style
    elif word_count <= 150:
        score += 0.1
    elif word_count > 250:
        score -= 0.2  # Too verbose — not Marion

    # Negative: corporate formulas Marion never uses
    corporate = [
        # EN
        "warm regards", "we look forward", "don't hesitate",
        "looking forward to welcoming", "please let me know if",
        "complete freedom", "at your own pace",
        "i'm delighted", "wonderful news", "what wonderful",
        "perfect timing", "happy to pull this together",
        "let me put this together",
        # FR
        "n'hésitez pas", "je reste à votre disposition",
        "je reste disponible", "avec grand plaisir",
        "je me permets de", "quel beau projet",
        "les chambres partent", "période très demandée",
        "laissez-moi vous expliquer", "merci pour votre message",
        "je vous recommande de vous rapprocher",
    ]
    corporate_hits = 0
    for marker in corporate:
        if marker in lower:
            corporate_hits += 1
    # -0.15 per formula (was -0.1) — 2 hits = -0.30, enough to trigger review
    score -= corporate_hits * 0.15

    # Negative: overly casual/familiar phrases — not Marion's elegant style
    casual = [
        "happy birthday", "sounds great", "that works",
        "two great options", "let us know what appeals",
        "we'll put it all together", "sounds like a plan",
        "awesome", "a great fit", "happy to help with that",
        "both work well", "cool", "let me know what works",
        "super !", "ça marche", "trop bien", "pas de souci",
        "c'est top",
    ]
    casual_hits = sum(1 for marker in casual if marker in lower)
    score -= casual_hits * 0.15

    return max(0.0, min(1.0, score))
