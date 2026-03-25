"""Language detection — pattern-based FR/EN/ES/NL/DE/IT detection."""

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

# Spanish markers
_ES_PATTERNS = [
    r"\bhola\b", r"\bgracias\b", r"\bpor favor\b", r"\bbuenos?\b", r"\btardes\b",
    r"\bhabitaci[oó]n\b", r"\breserva\b", r"\bdisponibilidad\b", r"\bnoches?\b",
    r"\bquiero\b", r"\bnecesito\b", r"\bestamos\b", r"\btenemos\b",
    r"\bprecio\b", r"\bcuánto\b", r"\bplaya\b", r"\brestaurante\b",
    r"\bqueremos\b", r"\bnuestro\b", r"\bdesde\b",
    r"[ñáéíóú¿¡]",
]

# Dutch markers
_NL_PATTERNS = [
    r"\bhallo\b", r"\bbedankt\b", r"\balstublieft\b", r"\bkamer\b",
    r"\bbeschikbaar\b", r"\breservering\b", r"\bnachten?\b", r"\bstrand\b",
    r"\bwij\b", r"\bhet\b", r"\been\b", r"\bvan\b", r"\bvoor\b",
    r"\bgraag\b", r"\bkunnen\b", r"\bwillen\b", r"\bprijs\b",
    r"\b(?:ij|oe|ui|eu|aa|oo|ee)\b",
]

# German markers
_DE_PATTERNS = [
    r"\bhallo\b", r"\bdanke\b", r"\bbitte\b", r"\bzimmer\b",
    r"\bverfügbar\b", r"\breservierung\b", r"\bnächte?\b", r"\bstrand\b",
    r"\bwir\b", r"\bdas\b", r"\bein\b", r"\bvon\b", r"\bfür\b",
    r"\bmöchten?\b", r"\bkönn(?:en|ten)\b", r"\bpreis\b",
    r"[äöüß]",
]

# Italian markers
_IT_PATTERNS = [
    r"\bciao\b", r"\bgrazie\b", r"\bper favore\b", r"\bbuongiorno\b",
    r"\bcamera\b", r"\bprenotazione\b", r"\bdisponibilità\b", r"\bnotti?\b",
    r"\bvorrei\b", r"\babbiamo\b", r"\bsiamo\b", r"\bnostro\b",
    r"\bprezzo\b", r"\bspiaggia\b", r"\bristorante\b",
    r"[àèéìíòóùú]",
]

# Portuguese markers
_PT_PATTERNS = [
    r"\bolá\b", r"\bobrigad[oa]\b", r"\bpor favor\b", r"\bbom dia\b",
    r"\bquarto\b", r"\breserva\b", r"\bdisponibilidade\b", r"\bnoites?\b",
    r"\bpraia\b", r"\brestaurante\b", r"\bpreço\b", r"\bgostaría\b",
    r"\bnós\b", r"\bnosso\b", r"\bpreciso\b", r"\bqueremos\b",
    r"\btemos\b", r"\bestamos\b", r"\bdesde\b",
    r"[ãõçâêô]",
]

_LANG_MAP = {
    "fr": _FR_PATTERNS,
    "en": _EN_PATTERNS,
    "es": _ES_PATTERNS,
    "nl": _NL_PATTERNS,
    "de": _DE_PATTERNS,
    "it": _IT_PATTERNS,
    "pt": _PT_PATTERNS,
}


def detect_language(text: str) -> str:
    """Detect the primary language of the text.

    Returns one of: 'fr', 'en', 'es', 'nl', 'de', 'it'.
    Defaults to 'en' if no clear winner.
    """
    if not text:
        return "en"

    text_lower = text.lower()

    scores: dict[str, int] = {}
    for lang, patterns in _LANG_MAP.items():
        scores[lang] = sum(1 for p in patterns if re.search(p, text_lower))

    best_lang = max(scores, key=scores.get)  # type: ignore[arg-type]
    best_score = scores[best_lang]

    # Require minimum score to claim a non-EN/FR language
    if best_score == 0:
        return "en"

    return best_lang
