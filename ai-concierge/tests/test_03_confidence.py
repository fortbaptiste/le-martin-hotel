"""Test confidence scoring — the 5-signal weighted system."""

import pytest

from src.services.confidence import compute_confidence


def _score(**kwargs) -> float:
    """Shortcut returning the weighted score."""
    return compute_confidence(**kwargs).weighted_score


class TestConfidenceRetrieval:
    """Signal 1: Did the AI use the right tools for the topic?"""

    def test_restaurant_with_correct_tool(self):
        c = compute_confidence(
            ai_response_text="Voici nos recommandations. Chaleureusement, Marion",
            llm_self_score=0.9, tools_used=["search_restaurants"],
            email_body="Could you recommend a restaurant for dinner?",
            rules_count=5,
        )
        assert c.retrieval_relevance >= 0.9

    def test_restaurant_without_tool(self):
        c = compute_confidence(
            ai_response_text="Voici nos recommandations. Chaleureusement, Marion",
            llm_self_score=0.9, tools_used=[],
            email_body="Could you recommend a restaurant for dinner?",
            rules_count=5,
        )
        assert c.retrieval_relevance <= 0.4

    def test_availability_with_correct_tool(self):
        c = compute_confidence(
            ai_response_text="La chambre est disponible. Chaleureusement, Marion",
            llm_self_score=0.9, tools_used=["check_room_availability"],
            email_body="What are your rates for March 15-20?",
            rules_count=5,
        )
        assert c.retrieval_relevance >= 0.9

    def test_simple_greeting_no_tools_ok(self):
        c = compute_confidence(
            ai_response_text="Bonjour ! Chaleureusement, Marion",
            llm_self_score=0.9, tools_used=[],
            email_body="Bonjour !",
            rules_count=5,
        )
        assert c.retrieval_relevance >= 0.6


class TestConfidenceCompliance:
    """Signal 4: Rule compliance checks."""

    def test_signature_present(self):
        c = compute_confidence(
            ai_response_text="Blah blah. Chaleureusement, Marion & Emmanuel, Le Martin",
            llm_self_score=0.9, tools_used=[], email_body="Hello",
            rules_count=5,
        )
        assert c.rule_compliance >= 0.9

    def test_signature_missing_penalized(self):
        c = compute_confidence(
            ai_response_text="Here is your information, goodbye.",
            llm_self_score=0.9, tools_used=[], email_body="Hello",
            rules_count=5,
        )
        assert c.rule_compliance <= 0.7

    def test_internal_room_name_leak(self):
        """CRITICAL: internal names like 'Suite Marius' must be penalized."""
        c = compute_confidence(
            ai_response_text="La Suite Marius est disponible. Chaleureusement, Le Martin",
            llm_self_score=0.9, tools_used=["check_room_availability"],
            email_body="Is there availability?",
            rules_count=5,
        )
        assert c.rule_compliance <= 0.7

    def test_all_internal_names_detected(self):
        internal_names = [
            "Marius", "Marcelle", "Pierre", "René",
            "Marthe", "Georgette",
        ]
        for name in internal_names:
            c = compute_confidence(
                ai_response_text=f"La chambre {name} est magnifique. Chaleureusement, Marion",
                llm_self_score=0.9, tools_used=[], email_body="Info please",
                rules_count=5,
            )
            assert c.rule_compliance <= 0.7, f"Internal name '{name}' was not detected"

    def test_price_without_availability_tool(self):
        c = compute_confidence(
            ai_response_text="Le tarif est de 350 \u20ac par nuit. Chaleureusement, Marion",
            llm_self_score=0.9, tools_used=[],
            email_body="What is the price?",
            rules_count=5,
        )
        # Price pattern detected without check_room_availability → penalty
        assert c.rule_compliance < 1.0


class TestConfidenceWeights:
    """Verify the weighted formula sums correctly."""

    def test_perfect_score(self):
        from src.models.ai import ConfidenceBreakdown
        b = ConfidenceBreakdown(
            retrieval_relevance=1.0,
            context_completeness=1.0,
            llm_self_assessment=1.0,
            rule_compliance=1.0,
            template_match=1.0,
        )
        assert abs(b.weighted_score - 1.0) < 0.001

    def test_zero_score(self):
        from src.models.ai import ConfidenceBreakdown
        b = ConfidenceBreakdown()
        assert b.weighted_score == 0.0

    def test_weights_sum_to_one(self):
        """0.25 + 0.20 + 0.15 + 0.25 + 0.15 = 1.00"""
        assert abs(0.25 + 0.20 + 0.15 + 0.25 + 0.15 - 1.0) < 0.001


class TestConfidenceTemplateMatch:
    """Signal 5: Marion's warm tone detection."""

    def test_warm_tone_boosted(self):
        c = compute_confidence(
            ai_response_text="Avec plaisir ! N'h\u00e9sitez pas. Chaleureusement, Marion",
            llm_self_score=0.9, tools_used=[], email_body="Merci",
            rules_count=5,
        )
        assert c.template_match >= 0.7

    def test_cold_tone_lower(self):
        c = compute_confidence(
            ai_response_text="Information noted. Regards.",
            llm_self_score=0.9, tools_used=[], email_body="Hello",
            rules_count=5,
        )
        # Cold tone should score lower than warm tone
        c_warm = compute_confidence(
            ai_response_text="Je serai ravie de vous aider pour votre séjour. Marion",
            llm_self_score=0.9, tools_used=[], email_body="Hello",
            rules_count=5,
        )
        assert c.template_match <= c_warm.template_match
