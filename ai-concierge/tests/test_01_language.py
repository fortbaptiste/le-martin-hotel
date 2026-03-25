"""Test language detection."""

from src.services.language import detect_language


class TestLanguageDetection:
    def test_french_email(self):
        assert detect_language("Bonjour, je souhaite réserver une chambre pour 3 nuits.") == "fr"

    def test_english_email(self):
        assert detect_language("Hello, I would like to book a room for 3 nights.") == "en"

    def test_french_with_accents(self):
        assert detect_language("Nous sommes intéressés par un séjour en août.") == "fr"

    def test_english_availability(self):
        assert detect_language("Is there availability for March 15 to 20?") == "en"

    def test_empty_defaults_to_english(self):
        assert detect_language("") == "en"

    def test_mixed_defaults_reasonably(self):
        # Short ambiguous text
        result = detect_language("OK merci")
        assert result in ("fr", "en")

    def test_french_formal(self):
        assert detect_language(
            "Madame, Monsieur, nous souhaiterions avoir des informations sur vos tarifs."
        ) == "fr"

    def test_english_honeymoon(self):
        assert detect_language(
            "We are planning our honeymoon and would love to stay at your hotel."
        ) == "en"
