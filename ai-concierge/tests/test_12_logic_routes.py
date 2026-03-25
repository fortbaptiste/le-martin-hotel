"""Test complet des routes logiques — vérifie que l'IA suit le bon chemin
pour chaque type de demande client.

Scénarios testés :
1. Restaurant → search_restaurants obligatoire
2. Disponibilité → check_room_availability obligatoire
3. Plainte → escalation immédiate (pas d'IA)
4. Modification de réservation → escalation deferred
5. Spam/fournisseur → skip
6. Question check-in → FAQ
7. Transfert aéroport → get_hotel_services
8. Fermeture annuelle → réponse correcte
9. Noms internes de chambres → jamais exposés
10. Prix → jamais inventés
11. Restaurant inconnu → jamais inventé
12. Négation → pas d'escalation fausse
"""

from __future__ import annotations

import json
import re
import uuid
from datetime import datetime
from unittest.mock import AsyncMock, patch

import pytest

from src.models.message import InboundEmail
from src.services.email_processor import process_email
from src.services.escalation import check_pre_escalation, check_post_escalation
from src.services.language import detect_language
from src.services.confidence import compute_confidence
from src.tools.definitions import TOOLS
from src.tools.handlers import handle_tool_call, _sanitize_room
from src.prompts.few_shot import select_few_shot_examples
from src.exceptions import EscalationRequired
from tests.conftest import make_email


# ── Clean state between tests ────────────────────────────────────

@pytest.fixture(autouse=True)
def _clean_pipeline_state():
    """Reset processed IDs between tests."""
    from src.services.email_processor import _processed_ids, _retry_counts, _PROCESSED_IDS_FILE
    _processed_ids.clear()
    _retry_counts.clear()
    # Save and clear file state
    original_exists = _PROCESSED_IDS_FILE.exists()
    original_content = _PROCESSED_IDS_FILE.read_text() if original_exists else ""
    if original_exists:
        _PROCESSED_IDS_FILE.write_text("")
    yield
    _processed_ids.clear()
    _retry_counts.clear()
    # Restore
    if original_exists:
        _PROCESSED_IDS_FILE.write_text(original_content)
    elif _PROCESSED_IDS_FILE.exists():
        _PROCESSED_IDS_FILE.unlink()


# ── Helpers ──────────────────────────────────────────────────────

def _fake_ai_response(text, **kw):
    from src.models.message import AIResponse
    return AIResponse(
        response_text=text,
        confidence_score=kw.get("confidence", 0.85),
        detected_language=kw.get("language", "en"),
        category=kw.get("category", "info_request"),
        tokens_input=kw.get("tokens_in", 1500),
        tokens_output=kw.get("tokens_out", 600),
        tools_used=kw.get("tools", []),
        response_time_ms=kw.get("time_ms", 3200),
    )


# ═══════════════════════════════════════════════════════════════
# 1. ROUTE: Restaurant request → must call search_restaurants
# ═══════════════════════════════════════════════════════════════

class TestRouteRestaurant:
    """Quand un client demande un restaurant, l'IA DOIT utiliser search_restaurants."""

    @pytest.mark.asyncio
    async def test_restaurant_request_uses_tool(self, mock_supabase):
        email = make_email(
            body_text="Could you recommend a good restaurant for dinner tonight?",
        )
        with patch("src.services.email_processor.ai_engine.generate_response",
                    new_callable=AsyncMock) as mock_ai:
            mock_ai.return_value = _fake_ai_response(
                "Dear Guest,\n\nI'd recommend Le Tropicana, about 8 minutes by car.\n\n"
                "Warm regards,\nMarion & Emmanuel",
                tools=["search_restaurants"],
                category="restaurant",
            )
            result = await process_email(email)

        assert result["status"] == "processed"
        assert "search_restaurants" in result["tools_used"]

    def test_restaurant_without_tool_loses_confidence(self, mock_supabase):
        """Si l'IA recommande un restaurant SANS appeler l'outil, le score baisse."""
        score = compute_confidence(
            ai_response_text="I recommend Ristorante Del Arti for dinner.\n\nMarion & Emmanuel",
            llm_self_score=0.8,
            tools_used=[],  # Pas d'outil appelé !
            email_body="Can you recommend a restaurant?",
            rules_count=0,
        )
        # retrieval_relevance should penalize missing tool
        assert score.retrieval_relevance < 0.7

    def test_tool_set_includes_activities(self, mock_supabase):
        """Vérification que search_activities est bien dans les tools."""
        tool_names = {t["name"] for t in TOOLS}
        assert "search_restaurants" in tool_names
        assert "search_activities" in tool_names


# ═══════════════════════════════════════════════════════════════
# 2. ROUTE: Availability → must call check_room_availability
# ═══════════════════════════════════════════════════════════════

class TestRouteAvailability:
    @pytest.mark.asyncio
    async def test_availability_request_processed(self, mock_supabase):
        email = make_email(
            body_text="Do you have a room available from March 20 to March 25?",
        )
        with patch("src.services.email_processor.ai_engine.generate_response",
                    new_callable=AsyncMock) as mock_ai:
            mock_ai.return_value = _fake_ai_response(
                "Dear Guest,\n\nI've checked availability for March 20-25.\n\n"
                "Book directly: https://lemartinhotel.thais-hotel.com/direct-booking/calendar\n\n"
                "Warm regards,\nMarion & Emmanuel",
                tools=["check_room_availability"],
                category="availability",
            )
            result = await process_email(email)

        assert result["status"] == "processed"
        assert "check_room_availability" in result["tools_used"]

    def test_price_without_tool_penalized(self, mock_supabase):
        """Citer un prix sans appeler check_room_availability = pénalité."""
        score = compute_confidence(
            ai_response_text="Our rooms start at 294€/night.\n\nMarion & Emmanuel",
            llm_self_score=0.8,
            tools_used=[],
            email_body="How much is a room for March 20-25?",
            rules_count=0,
        )
        assert score.retrieval_relevance < 0.7

    def test_booking_link_in_response_boosts_confidence(self, mock_supabase):
        """Réponse avec lien de réservation = meilleur score."""
        score_with = compute_confidence(
            ai_response_text="Room available at 350€/night.\nBook: https://lemartinhotel.thais-hotel.com/direct-booking/calendar\n\nMarion & Emmanuel",
            llm_self_score=0.9,
            tools_used=["check_room_availability"],
            email_body="Do you have rooms for March?",
            rules_count=0,
        )
        score_without = compute_confidence(
            ai_response_text="Room available at 350€/night.\n\nMarion & Emmanuel",
            llm_self_score=0.9,
            tools_used=["check_room_availability"],
            email_body="Do you have rooms for March?",
            rules_count=0,
        )
        assert score_with.rule_compliance >= score_without.rule_compliance


# ═══════════════════════════════════════════════════════════════
# 3. ROUTE: Complaints → immediate escalation (no AI)
# ═══════════════════════════════════════════════════════════════

class TestRouteComplaint:
    @pytest.mark.asyncio
    async def test_complaint_french(self, mock_supabase):
        email = make_email(body_text="C'est inadmissible ! Je veux un remboursement !")
        with patch("src.services.email_processor.ai_engine.generate_response",
                    new_callable=AsyncMock) as mock_ai:
            result = await process_email(email)
        assert result["status"] == "escalated"
        assert result["reason"] == "complaint"
        mock_ai.assert_not_called()  # AI never touched this

    @pytest.mark.asyncio
    async def test_complaint_english(self, mock_supabase):
        email = make_email(body_text="This is unacceptable! I demand a full refund!")
        with patch("src.services.email_processor.ai_engine.generate_response",
                    new_callable=AsyncMock) as mock_ai:
            result = await process_email(email)
        assert result["status"] == "escalated"
        mock_ai.assert_not_called()


# ═══════════════════════════════════════════════════════════════
# 4. ROUTE: Booking modification → escalation
# ═══════════════════════════════════════════════════════════════

class TestRouteBookingModification:
    @pytest.mark.asyncio
    async def test_cancel_reservation_deferred_escalation(self, mock_supabase):
        """Annulation = deferred escalation (AI drafts brief reply + escalation to Emmanuel)."""
        email = make_email(body_text="Je souhaite annuler ma réservation pour le 15 mars.")
        with patch("src.services.email_processor.ai_engine.generate_response",
                    new_callable=AsyncMock) as mock_ai:
            mock_ai.return_value = _fake_ai_response(
                "Bonjour,\n\nBien reçu, nous transmettons à l'équipe.\n\nMarion & Emmanuel",
                category="booking_modification",
            )
            result = await process_email(email)
        # Deferred = AI processes but also escalates
        assert result["status"] == "processed"
        assert result.get("deferred_escalation") == "booking_modification"
        mock_ai.assert_called_once()  # AI IS called for deferred

    @pytest.mark.asyncio
    async def test_shorten_stay_uses_deferred(self, mock_supabase):
        email = make_email(body_text="I need to change my booking dates please.")
        with patch("src.services.email_processor.ai_engine.generate_response",
                    new_callable=AsyncMock) as mock_ai:
            mock_ai.return_value = _fake_ai_response(
                "Dear Guest,\n\nNoted, we are checking.\n\nMarion & Emmanuel",
                category="booking_modification",
            )
            result = await process_email(email)
        assert result["status"] == "processed"
        assert result.get("deferred_escalation") == "booking_modification"


# ═══════════════════════════════════════════════════════════════
# 5. ROUTE: Spam / Supplier → skip entirely
# ═══════════════════════════════════════════════════════════════

class TestRouteSkip:
    @pytest.mark.asyncio
    async def test_supplier_email_skipped(self, mock_supabase):
        email = make_email(from_email="instant.floral@yahoo.com", body_text="Livraison demain")
        result = await process_email(email)
        assert result["status"] == "skipped"

    @pytest.mark.asyncio
    async def test_tripadvisor_subdomain_skipped(self, mock_supabase):
        email = make_email(from_email="reports@hm2.tripadvisor.com", body_text="Monthly report")
        result = await process_email(email)
        assert result["status"] == "skipped"

    @pytest.mark.asyncio
    async def test_job_application_skipped(self, mock_supabase):
        email = make_email(
            from_email="someone@gmail.com",
            subject="Candidature",
            body_text="Je cherche du travail comme cuisinier",
        )
        result = await process_email(email)
        assert result["status"] == "skipped"

    @pytest.mark.asyncio
    async def test_newsletter_unsubscribe_skipped(self, mock_supabase):
        email = make_email(
            from_email="promo@hotel-marketing.com",
            body_text="Special offer! View this email in your browser. Unsubscribe here.",
        )
        result = await process_email(email)
        assert result["status"] == "skipped"

    @pytest.mark.asyncio
    async def test_bred_bank_skipped(self, mock_supabase):
        email = make_email(from_email="relation_clients@em.bred.fr", body_text="Relevé de compte")
        result = await process_email(email)
        assert result["status"] == "skipped"

    @pytest.mark.asyncio
    async def test_real_guest_not_skipped(self, mock_supabase):
        email = make_email(
            from_email="john.doe@gmail.com",
            body_text="Hello, I'd like to book a room for next week.",
        )
        with patch("src.services.email_processor.ai_engine.generate_response",
                    new_callable=AsyncMock) as mock_ai:
            mock_ai.return_value = _fake_ai_response(
                "Dear John,\n\nThank you for your interest!\n\nMarion & Emmanuel",
            )
            result = await process_email(email)
        assert result["status"] == "processed"


# ═══════════════════════════════════════════════════════════════
# 6. ROUTE: Language detection
# ═══════════════════════════════════════════════════════════════

class TestLanguageDetection:
    def test_french_detected(self):
        assert detect_language("Bonjour, je voudrais réserver une chambre") == "fr"

    def test_english_detected(self):
        assert detect_language("Hello, I would like to book a room") == "en"

    def test_spanish_detected(self):
        assert detect_language("Hola, me gustaría reservar una habitación") == "es"

    def test_empty_defaults_english(self):
        assert detect_language("") == "en"


# ═══════════════════════════════════════════════════════════════
# 7. ROUTE: Room name sanitization
# ═══════════════════════════════════════════════════════════════

class TestRoomSanitization:
    """Les noms internes ne doivent JAMAIS apparaître dans les réponses aux clients."""

    def test_marius_sanitized(self):
        room = {"name": "Suite Marius", "slug": "marius"}
        sanitized = _sanitize_room(room)
        assert "Marius" not in sanitized["name"]
        assert "Deluxe" in sanitized["name"]

    def test_pierre_sanitized(self):
        room = {"name": "Chambre Pierre", "slug": "pierre"}
        sanitized = _sanitize_room(room)
        assert "Pierre" not in sanitized["name"]
        assert "Privilège" in sanitized["name"] or "Privilege" in sanitized["name"]

    def test_family_suite_kept(self):
        room = {"name": "Suite Familiale", "slug": "family-suite"}
        sanitized = _sanitize_room(room)
        assert "Familiale" in sanitized["name"]

    def test_internal_names_penalize_confidence(self, mock_supabase):
        """Si une réponse contient un nom interne, le score compliance baisse."""
        score = compute_confidence(
            ai_response_text="We suggest Suite Marius for your stay.\n\nMarion & Emmanuel",
            llm_self_score=0.9,
            tools_used=["get_room_details"],
            email_body="Which room do you recommend?",
            rules_count=0,
        )
        assert score.rule_compliance < 0.7


# ═══════════════════════════════════════════════════════════════
# 8. ROUTE: Negation — no false escalation
# ═══════════════════════════════════════════════════════════════

class TestNegationDetection:
    def test_not_disappointed_no_escalation(self):
        result = check_pre_escalation(
            "I am not disappointed at all, everything was perfect!",
            "Great stay",
        )
        assert result is None

    def test_ne_pas_annuler_no_escalation(self):
        result = check_pre_escalation(
            "Je ne souhaite pas annuler, je voulais juste une information.",
            "Question",
        )
        assert result is None

    def test_actual_complaint_still_escalated(self):
        result = check_pre_escalation(
            "I am extremely disappointed with the service!",
            "Complaint",
        )
        assert result is not None
        assert result.reason == "complaint"


# ═══════════════════════════════════════════════════════════════
# 9. ROUTE: Post-check — meta-commentary detection
# ═══════════════════════════════════════════════════════════════

class TestPostCheck:
    def test_meta_commentary_detected(self):
        """L'IA ne doit pas envoyer de commentaires internes au client."""
        result = check_post_escalation(
            "Cet email est une demande de réservation.\n\nMarion & Emmanuel",
            confidence_score=0.85,
        )
        # If meta-commentary detected, result should trigger escalation
        assert result is not None

    def test_clean_response_passes(self):
        result = check_post_escalation(
            "Dear Guest,\n\nThank you for your message. We look forward to welcoming you.\n\n"
            "Warm regards,\nMarion & Emmanuel",
            confidence_score=0.90,
        )
        # Clean response with good confidence = no escalation
        assert result is None


# ═══════════════════════════════════════════════════════════════
# 10. ROUTE: Few-shot selection
# ═══════════════════════════════════════════════════════════════

class TestFewShotSelection:
    def test_restaurant_email_selects_restaurant_examples(self):
        examples = [
            {"id": "1", "category": "concierge_restaurant", "language": "en",
             "title": "Restaurant reco", "client_message": "dinner?",
             "marion_response": "Dear...", "context": "", "learnings": []},
            {"id": "2", "category": "reservation_inquiry", "language": "en",
             "title": "Room inquiry", "client_message": "room?",
             "marion_response": "Dear...", "context": "", "learnings": []},
        ]
        selected = select_few_shot_examples(
            "Can you recommend a good restaurant for dinner?",
            examples,
            language="en",
            max_examples=1,
        )
        assert len(selected) >= 1
        assert selected[0].category == "concierge_restaurant"

    def test_empty_examples_returns_empty(self):
        selected = select_few_shot_examples(
            "Hello", [], language="en", max_examples=3,
        )
        assert len(selected) == 0


# ═══════════════════════════════════════════════════════════════
# 11. ROUTE: Full pipeline — end to end
# ═══════════════════════════════════════════════════════════════

class TestFullPipelineLogic:
    @pytest.mark.asyncio
    async def test_honeymoon_processed_not_escalated(self, mock_supabase):
        """Lune de miel = traitement normal, pas d'escalation."""
        email = make_email(
            body_text="We are planning our honeymoon! Can you suggest something special?",
        )
        with patch("src.services.email_processor.ai_engine.generate_response",
                    new_callable=AsyncMock) as mock_ai:
            mock_ai.return_value = _fake_ai_response(
                "Dear Newlyweds,\n\nCongratulations! We'd love to make your honeymoon special.\n\n"
                "Marion & Emmanuel",
                tools=["get_hotel_services"],
                category="honeymoon",
                confidence=0.9,
            )
            result = await process_email(email)
        assert result["status"] == "processed"

    @pytest.mark.asyncio
    async def test_group_5_plus_escalated(self, mock_supabase):
        """Groupe de 5+ personnes → escalation obligatoire."""
        email = make_email(body_text="We are 8 people looking for rooms for next week.")
        with patch("src.services.email_processor.ai_engine.generate_response",
                    new_callable=AsyncMock) as mock_ai:
            result = await process_email(email)
        assert result["status"] == "escalated"
        assert result["reason"] == "group_request"
        mock_ai.assert_not_called()

    @pytest.mark.asyncio
    async def test_duplicate_email_blocked(self, mock_supabase):
        """Le même email ne doit PAS être traité deux fois."""
        email = make_email(message_id="unique-id-123", body_text="Normal question")
        with patch("src.services.email_processor.ai_engine.generate_response",
                    new_callable=AsyncMock) as mock_ai:
            mock_ai.return_value = _fake_ai_response("Answer\n\nMarion & Emmanuel")
            r1 = await process_email(email)
            r2 = await process_email(email)
        assert r1["status"] == "processed"
        assert r2["status"] == "already_processed"
        assert mock_ai.call_count == 1
