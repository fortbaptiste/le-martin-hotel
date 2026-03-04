"""Language detection — simple pattern-based FR/EN detection."""

from __future__ import annotations

import re

# French markers (frequent words, accented chars, patterns)
_FR_PATTERNS = [
    r"\bbonjour\b", r"\bmerci\b", r"\bcordialement\b", r"\bje\b", r"\bnous\b",
    r"\bvous\b", r"\bl['']hôtel\b", r"\bréserv", r"\bdisponib", r"\bchambre\b",
    r"\bséjour\b", r"\bprix\b", r"\bpour\b", r"\bune?\b", r"\bdes\b",
    r"\baussi\b", r"\bavec\b", r"\bchez\b", r"\bsommes\b", r"\bêtes\b",
    r"\bsouhait", r"\bs'il vous plaît\b", r"\bbien\b", r"\bcher\b",
    r"\bjour\b", r"\bbon\b", r"\bcomment\b", r"\bquand\b",
    r"[àâäéèêëïîôùûüÿç]",
]

# English markers
_EN_PATTERNS = [
    r"\bhello\b", r"\bthanks?\b", r"\bplease\b", r"\bwould\b", r"\bcould\b",
    r"\broom\b", r"\bavailab", r"\bbook", r"\bstay\b", r"\bprice\b",
    r"\bcheck.?in\b", r"\bcheck.?out\b", r"\bhotel\b", r"\bbeach\b",
    r"\bthe\b", r"\bis\b", r"\bare\b", r"\bwas\b", r"\bhave\b",
    r"\bwe\b", r"\bour\b", r"\byour\b", r"\bwith\b", r"\bfor\b",
    r"\bfrom\b", r"\bthat\b", r"\bthis\b", r"\bwill\b", r"\bcan\b",
]


def detect_language(text: str) -> str:
    """Detect whether the text is French or English. Returns 'fr' or 'en'."""
    if not text:
        return "en"

    text_lower = text.lower()

    fr_score = sum(1 for p in _FR_PATTERNS if re.search(p, text_lower))
    en_score = sum(1 for p in _EN_PATTERNS if re.search(p, text_lower))

    return "fr" if fr_score > en_score else "en"
