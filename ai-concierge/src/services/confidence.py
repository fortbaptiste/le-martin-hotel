"""Confidence scoring — 5 weighted signals."""

from __future__ import annotations

import re

import structlog

from src.models.ai import ConfidenceBreakdown

log = structlog.get_logger()


def compute_confidence(
    *,
    ai_response_text: str,
    llm_self_score: float,
    tools_used: list[str],
    email_body: str,
    rules_count: int,
    template_used: bool = False,
) -> ConfidenceBreakdown:
    """Compute the 5-signal weighted confidence score."""

    # 1. Retrieval relevance (0.20) — did the AI use tools to fetch data?
    retrieval = _score_retrieval(tools_used, email_body)

    # 2. Context completeness (0.20) — are all questions in the email addressed?
    completeness = _score_completeness(ai_response_text, email_body)

    # 3. LLM self-assessment (0.25) — Claude's own confidence
    llm_score = min(1.0, max(0.0, llm_self_score))

    # 4. Rule compliance (0.20) — signature present, no invented prices, etc.
    compliance = _score_rule_compliance(ai_response_text, rules_count)

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


def _score_retrieval(tools_used: list[str], email_body: str) -> float:
    """Did the AI retrieve relevant data?"""
    if not tools_used:
        # No tools used — might be fine for simple greetings
        body_lower = email_body.lower()
        is_simple = any(w in body_lower for w in ["merci", "thank", "bonjour", "hello", "hi"])
        return 0.7 if is_simple else 0.3

    # More tools = better retrieval (up to a point)
    return min(1.0, 0.5 + len(tools_used) * 0.1)


def _score_completeness(response: str, email_body: str) -> float:
    """Check if the response addresses question marks in the email."""
    questions = email_body.count("?")
    if questions == 0:
        return 0.9

    # Simple heuristic: response length relative to number of questions
    words = len(response.split())
    expected_min = questions * 30
    if words >= expected_min:
        return 0.9
    return max(0.4, words / expected_min)


def _score_rule_compliance(response: str, rules_count: int) -> float:
    """Check basic rule compliance."""
    score = 1.0

    # Must have signature
    has_signature = any(
        s in response.lower()
        for s in ["marion", "le martin", "chaleureusement", "warm regards", "best regards"]
    )
    if not has_signature:
        score -= 0.3

    # Should not contain fabricated price patterns without tool usage context
    # (The pipeline should have caught this, but double-check)
    price_pattern = re.search(r"\b\d{3,4}\s*€", response)
    if price_pattern and "check_room_availability" not in response:
        score -= 0.1

    return max(0.0, score)


def _score_template_match(response: str) -> float:
    """Basic style matching — Marion's warm, personal tone."""
    score = 0.5

    # Positive signals
    warm_markers = [
        "chaleureusement", "warm regards", "avec plaisir", "n'hésitez pas",
        "don't hesitate", "we look forward", "au plaisir", "with pleasure",
        "ravi", "delighted", "happy to help",
    ]
    for marker in warm_markers:
        if marker in response.lower():
            score += 0.1

    return min(1.0, score)
