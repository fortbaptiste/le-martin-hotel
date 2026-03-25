"""Select 2-3 most relevant few-shot examples from the email_examples table."""

from __future__ import annotations

import logging
import re

from src.models.knowledge import EmailExample

logger = logging.getLogger(__name__)

# Category keywords mapping for matching
_CATEGORY_KEYWORDS: dict[str, list[str]] = {
    "reservation_inquiry": [
        "disponib", "availab", "book", "réserv", "dates", "price", "prix", "tarif",
        "rate", "room", "chambre", "suite", "nuit", "night", "stay", "séjour",
    ],
    "concierge_restaurant": [
        "restaurant", "dîner", "dinner", "lunch", "déjeuner", "manger", "eat",
        "cuisine", "gastronomie", "table", "réservation restaurant",
    ],
    "concierge_transport": [
        "transfer", "transport", "taxi", "ferry", "navette", "shuttle", "aéroport",
        "airport", "voiture", "car rental", "location", "flight",
    ],
    "special_occasion": [
        "honeymoon", "lune de miel", "anniversaire", "birthday", "wedding",
        "mariage", "romantic", "romantique", "celebration", "surprise",
        "anniversary",
    ],
    "car_rental": [
        "voiture", "car", "rental", "location", "conduite", "driving", "véhicule",
    ],
    "modification": [
        "modif", "chang", "annul", "cancel", "report", "décaler",
    ],
    "pre_arrival": [
        "arrivée", "arrival", "check-in", "checkin", "avant le séjour",
        "before the stay", "préparer", "prepare",
    ],
    "post_stay": [
        "merci", "thank", "retour", "feedback", "review", "avis", "séjour passé",
    ],
    "group": [
        "groupe", "group", "privatis", "événement", "event", "mariage", "wedding",
        "séminaire", "seminar", "team building", "familles", "families",
        "chambres", "rooms", "entire", "tout l'hôtel", "whole hotel",
    ],
}


def _keyword_matches(keyword: str, text: str) -> bool:
    """Check if keyword matches in text using word-start boundary.

    Uses a word boundary at the START to prevent false matches like
    'eat' in 'weather', but allows prefix matching so 'activit'
    matches 'activities' and 'snorkel' matches 'snorkeling'.
    """
    return bool(re.search(r'\b' + re.escape(keyword), text))


def select_few_shot_examples(
    email_body: str,
    available_examples: list[dict],
    language: str = "en",
    max_examples: int = 3,
) -> list[EmailExample]:
    """Pick the most relevant examples for the current email."""
    body_lower = email_body.lower()

    # Score each category by keyword matches
    category_scores: dict[str, int] = {}
    for category, keywords in _CATEGORY_KEYWORDS.items():
        score = sum(1 for kw in keywords if _keyword_matches(kw, body_lower))
        if score > 0:
            category_scores[category] = score

    # Sort categories by relevance
    ranked_categories = sorted(category_scores, key=category_scores.get, reverse=True)  # type: ignore[arg-type]

    # Pick examples from top categories, preferring matching language.
    # Two passes: first same-language examples, then any language as fallback.
    selected: list[EmailExample] = []
    seen_ids: set[str] = set()

    for category in ranked_categories:
        if len(selected) >= max_examples:
            break

        # Pass 1: same language
        for ex_dict in available_examples:
            if ex_dict.get("category") != category:
                continue
            if ex_dict["id"] in seen_ids:
                continue
            if ex_dict.get("language", "en") == language:
                selected.append(EmailExample(**ex_dict))
                seen_ids.add(ex_dict["id"])
                if len(selected) >= max_examples:
                    break

        if len(selected) >= max_examples:
            break

        # Pass 2: any language (fallback for this category)
        for ex_dict in available_examples:
            if ex_dict.get("category") != category:
                continue
            if ex_dict["id"] in seen_ids:
                continue
            selected.append(EmailExample(**ex_dict))
            seen_ids.add(ex_dict["id"])
            if len(selected) >= max_examples:
                break

    # Fallback: if we have fewer than 2 examples, pick any available
    if len(selected) < 2:
        for ex_dict in available_examples:
            if ex_dict["id"] in seen_ids:
                continue
            if ex_dict.get("language", "en") == language:
                selected.append(EmailExample(**ex_dict))
                seen_ids.add(ex_dict["id"])
                if len(selected) >= max_examples:
                    break

    if not selected:
        logger.warning(
            "No few-shot examples selected for email (body length=%d, language=%s). "
            "Check that email_examples are seeded in the database.",
            len(email_body),
            language,
        )

    return selected[:max_examples]


def format_few_shot_messages(examples: list[EmailExample]) -> list[dict]:
    """Format selected examples as Claude user/assistant message pairs."""
    messages: list[dict] = []
    for ex in examples:
        messages.append({
            "role": "user",
            "content": f"[Exemple — {ex.title}]\n\n{ex.client_message}",
        })
        messages.append({
            "role": "assistant",
            "content": ex.marion_response,
        })
    return messages
