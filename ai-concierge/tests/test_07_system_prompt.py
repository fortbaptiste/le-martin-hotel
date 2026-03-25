"""Test system prompt builder — verify all critical rules are present."""

from src.prompts.system import build_system_prompt
from src.models.ai import AIRule


def _build(**kwargs) -> str:
    return build_system_prompt(rules=kwargs.pop("rules", []), **kwargs)


class TestSystemPromptContent:
    """Verify the system prompt contains all mandatory business rules."""

    def test_identity_is_marion(self):
        prompt = _build()
        assert "Marion" in prompt

    def test_hotel_name_present(self):
        prompt = _build()
        assert "Le Martin" in prompt

    def test_prompt_injection_defense(self):
        prompt = _build()
        assert "injection" in prompt.lower() or "NON FIABLE" in prompt

    def test_no_internal_room_names_rule(self):
        prompt = _build()
        assert "JAMAIS" in prompt
        # Verify the rule mentions not using internal names
        assert "noms internes" in prompt.lower() or "catégories publiques" in prompt.lower()

    def test_public_categories_listed(self):
        prompt = _build()
        assert "Suite Deluxe vue mer" in prompt or "Deluxe Sea View" in prompt

    def test_beds_not_separable(self):
        prompt = _build()
        assert "séparables" in prompt.lower() or "twin" in prompt.lower()
        # Price now comes from get_hotel_services tool, not hardcoded
        assert "get_hotel_services" in prompt

    def test_no_restaurant_without_tool(self):
        prompt = _build()
        assert "search_restaurants" in prompt

    def test_no_walkable_restaurant(self):
        prompt = _build()
        assert "pied" in prompt.lower()  # mentions walking distance
        assert "AUCUN restaurant" in prompt or "aucun restaurant" in prompt.lower()

    def test_reservation_link(self):
        prompt = _build()
        assert "lemartinhotel.thais-hotel.com/direct-booking/calendar" in prompt

    def test_two_rate_types(self):
        prompt = _build()
        assert "Best Flexible" in prompt
        assert "Advance Purchase" in prompt

    def test_airport_distance(self):
        prompt = _build()
        assert "1 heure" in prompt or "1h" in prompt.lower()  # SXM = 1 hour
        assert "10 minutes" in prompt or "10 min" in prompt.lower()  # SFG = 10 min

    def test_pinel_dock_distinction(self):
        prompt = _build()
        assert "dock" in prompt.lower() or "Dock" in prompt
        assert "Pinel" in prompt

    def test_signature_block(self):
        prompt = _build()
        assert "Chaleureusement" in prompt
        assert "Marion & Emmanuel" in prompt
        assert "Cul de Sac" in prompt

    def test_confidence_category_format(self):
        prompt = _build()
        assert "CONFIDENCE:" in prompt
        assert "CATEGORY:" in prompt

    def test_attachment_handling(self):
        prompt = _build()
        assert "pièce jointe" in prompt.lower() or "pi\u00e8ce jointe" in prompt.lower()

    def test_lookup_reservation_rule(self):
        prompt = _build()
        assert "lookup_reservation" in prompt

    def test_language_instruction_french(self):
        prompt = _build(detected_language="fr")
        assert "fran\u00e7ais" in prompt.lower() or "Vouvoiement" in prompt

    def test_language_instruction_english(self):
        prompt = _build(detected_language="en")
        assert "English" in prompt

    def test_client_context_injected(self):
        prompt = _build(client_context={
            "first_name": "Jean", "last_name": "Dupont",
            "email": "jean@test.com", "vip_score": 8,
        })
        assert "Jean" in prompt
        assert "Dupont" in prompt
        assert "8" in prompt  # VIP score

    def test_rules_injected(self):
        rules = [
            AIRule(
                id="r1", rule_name="Test rule", rule="escalation",
                condition_text="si plainte", action_text="escalader",
            ),
        ]
        prompt = _build(rules=rules)
        assert "Test rule" in prompt
        assert "si plainte" in prompt
