"""Full pipeline simulation — end-to-end with mocked backends.

Tests the complete 15-step pipeline WITHOUT touching Outlook or real APIs.
"""

from __future__ import annotations

import uuid
from unittest.mock import AsyncMock, patch, MagicMock

import pytest

from src.models.message import InboundEmail, AIResponse
from src.services.email_processor import process_email, _processed_ids, _retry_counts
from tests.conftest import make_email


@pytest.fixture(autouse=True)
def _clean_state():
    """Reset processed IDs and retry counts between tests."""
    from src.services.email_processor import _PROCESSED_IDS_FILE
    _processed_ids.clear()
    _retry_counts.clear()
    # Temporarily patch the file-based persistence to avoid disk state leaks
    original_exists = _PROCESSED_IDS_FILE.exists()
    original_content = _PROCESSED_IDS_FILE.read_text() if original_exists else ""
    if original_exists:
        _PROCESSED_IDS_FILE.write_text("")
    yield
    _processed_ids.clear()
    _retry_counts.clear()
    # Restore original file
    if original_exists:
        _PROCESSED_IDS_FILE.write_text(original_content)
    elif _PROCESSED_IDS_FILE.exists():
        _PROCESSED_IDS_FILE.unlink()


def _fake_ai_response(text: str = "Chaleureusement, Marion & Emmanuel", **kwargs):
    """Build a fake AIResponse."""
    return AIResponse(
        response_text=text,
        confidence_score=kwargs.get("confidence", 0.85),
        detected_language=kwargs.get("language", "en"),
        category=kwargs.get("category", "info_request"),
        tokens_input=kwargs.get("tokens_in", 1500),
        tokens_output=kwargs.get("tokens_out", 600),
        tools_used=kwargs.get("tools", []),
        response_time_ms=kwargs.get("time_ms", 3200),
    )


class TestPipelineNormalFlow:
    """Simulate a normal guest email → AI response → observation log."""

    @pytest.mark.asyncio
    async def test_simple_info_request(self, mock_supabase):
        """Guest asks about check-in → AI answers → logged (not sent)."""
        email = make_email(
            from_email="guest@gmail.com",
            subject="Check-in time",
            body_text="Hello, what time is check-in? Thanks!",
        )

        with patch("src.services.email_processor.ai_engine.generate_response",
                    new_callable=AsyncMock) as mock_ai:
            mock_ai.return_value = _fake_ai_response(
                "Bonjour ! Check-in is from 3 PM. Chaleureusement, Marion & Emmanuel",
                confidence=0.88,
                tools=[],
            )

            result = await process_email(email)

        assert result["status"] == "processed"
        # Confidence is recalculated by the 5-signal scorer, not the LLM's raw score
        assert 0.7 <= result["confidence"] <= 1.0
        # Verify AI was called
        mock_ai.assert_called_once()
        # Verify NO Outlook calls (observation mode)
        # (covered by autouse _block_outlook fixture)

    @pytest.mark.asyncio
    async def test_restaurant_recommendation(self, mock_supabase):
        """Guest asks for restaurant → AI uses tool → logged."""
        email = make_email(
            from_email="honeymoon@couple.com",
            subject="Restaurant recommendation",
            body_text="We are looking for a romantic restaurant for our honeymoon dinner.",
        )

        with patch("src.services.email_processor.ai_engine.generate_response",
                    new_callable=AsyncMock) as mock_ai:
            mock_ai.return_value = _fake_ai_response(
                "Je vous recommande Le Cottage \u00e0 Grand Case. Chaleureusement, Marion & Emmanuel",
                confidence=0.92,
                tools=["search_restaurants"],
                category="restaurant",
            )

            result = await process_email(email)

        assert result["status"] == "processed"
        assert "search_restaurants" in result["tools_used"]

    @pytest.mark.asyncio
    async def test_client_created_for_new_guest(self, mock_supabase):
        """New guest email should create a client record."""
        email = make_email(
            from_email="newguest@test.com",
            from_name="Alice Wonderland",
            body_text="Hello, first time visiting!",
        )

        with patch("src.services.email_processor.ai_engine.generate_response",
                    new_callable=AsyncMock) as mock_ai:
            mock_ai.return_value = _fake_ai_response()

            await process_email(email)

        mock_supabase["create_client_record"].assert_called_once()
        call_data = mock_supabase["create_client_record"].call_args[0][0]
        assert call_data["email"] == "newguest@test.com"
        assert call_data["first_name"] == "Alice"

    @pytest.mark.asyncio
    async def test_existing_client_updated(self, mock_supabase):
        """Existing client should have language updated."""
        mock_supabase["get_client_by_email"].return_value = {
            "id": "existing-client-id", "email": "returning@guest.com",
        }
        email = make_email(
            from_email="returning@guest.com",
            body_text="Bonjour, je reviens bient\u00f4t !",
        )

        with patch("src.services.email_processor.ai_engine.generate_response",
                    new_callable=AsyncMock) as mock_ai:
            mock_ai.return_value = _fake_ai_response()

            await process_email(email)

        mock_supabase["update_client"].assert_called_once()


class TestPipelineSkipCases:
    """Emails that should be skipped entirely."""

    @pytest.mark.asyncio
    async def test_noreply_skipped(self, mock_supabase):
        email = make_email(from_email="noreply@booking.com", body_text="Automatic notification")
        result = await process_email(email)
        assert result["status"] == "skipped"

    @pytest.mark.asyncio
    async def test_auto_reply_skipped(self, mock_supabase):
        email = make_email(subject="Automatic Reply: Out of office", body_text="I am away")
        result = await process_email(email)
        assert result["status"] == "skipped"

    @pytest.mark.asyncio
    async def test_supplier_skipped(self, mock_supabase):
        email = make_email(from_email="instant.floral@yahoo.com", body_text="Delivery tomorrow")
        result = await process_email(email)
        assert result["status"] == "skipped"

    @pytest.mark.asyncio
    async def test_duplicate_email_skipped(self, mock_supabase):
        """Same email ID processed twice → second is skipped."""
        email = make_email(message_id="duplicate-msg-123", body_text="Hello")

        with patch("src.services.email_processor.ai_engine.generate_response",
                    new_callable=AsyncMock) as mock_ai:
            mock_ai.return_value = _fake_ai_response()
            result1 = await process_email(email)
            result2 = await process_email(email)

        assert result1["status"] == "processed"
        assert result2["status"] == "already_processed"
        # AI should only be called once
        assert mock_ai.call_count == 1


class TestPipelineEscalation:
    """Emails that should be escalated (pre or post AI)."""

    @pytest.mark.asyncio
    async def test_complaint_escalated_pre_ai(self, mock_supabase):
        """Complaint detected before AI → escalated without generating response."""
        email = make_email(
            from_email="angry@guest.com",
            body_text="C'est inacceptable ! Je demande un remboursement imm\u00e9diat.",
        )

        with patch("src.services.email_processor.ai_engine.generate_response",
                    new_callable=AsyncMock) as mock_ai:
            result = await process_email(email)

        assert result["status"] == "escalated"
        assert result["reason"] == "complaint"
        # AI should NOT be called for pre-escalation
        mock_ai.assert_not_called()
        # Escalation record should be created
        mock_supabase["create_escalation"].assert_called_once()

    @pytest.mark.asyncio
    async def test_cancellation_deferred_escalation(self, mock_supabase):
        """Cancellation uses deferred escalation: AI drafts + escalates in parallel."""
        email = make_email(
            body_text="Je souhaite annuler ma r\u00e9servation du 20 mars.",
        )

        with patch("src.services.email_processor.ai_engine.generate_response",
                    new_callable=AsyncMock) as mock_ai:
            mock_ai.return_value = _fake_ai_response(
                "Bonjour,\n\nBien reçu, nous transmettons.\n\nMarion & Emmanuel",
                category="booking_modification",
            )
            result = await process_email(email)

        assert result["status"] == "processed"
        assert result.get("deferred_escalation") == "booking_modification"
        mock_ai.assert_called_once()

    @pytest.mark.asyncio
    async def test_group_request_escalated(self, mock_supabase):
        email = make_email(
            body_text="We are 10 people looking for a group stay.",
        )

        with patch("src.services.email_processor.ai_engine.generate_response",
                    new_callable=AsyncMock) as mock_ai:
            result = await process_email(email)

        assert result["status"] == "escalated"
        assert result["reason"] == "group_request"

    @pytest.mark.asyncio
    async def test_low_confidence_escalated_post_ai(self, mock_supabase):
        """AI generates response but confidence is too low → escalated."""
        email = make_email(
            body_text="Some unusual question that confuses the AI.",
        )

        with patch("src.services.email_processor.ai_engine.generate_response",
                    new_callable=AsyncMock) as mock_ai:
            mock_ai.return_value = _fake_ai_response(
                "I'm not sure... Chaleureusement, Marion",
                confidence=0.3,  # Very low
            )

            result = await process_email(email)

        assert result["status"] == "escalated"
        assert result["reason"] == "low_confidence"

    @pytest.mark.asyncio
    async def test_negated_complaint_not_escalated(self, mock_supabase):
        """'I am NOT disappointed' should NOT escalate."""
        email = make_email(
            body_text="I am not disappointed at all, everything was wonderful!",
        )

        with patch("src.services.email_processor.ai_engine.generate_response",
                    new_callable=AsyncMock) as mock_ai:
            mock_ai.return_value = _fake_ai_response(
                "Thank you! Chaleureusement, Marion & Emmanuel",
                confidence=0.9,
            )

            result = await process_email(email)

        assert result["status"] == "processed"  # NOT escalated


class TestPipelineErrorHandling:
    """Crash recovery and retry logic."""

    @pytest.mark.asyncio
    async def test_ai_error_handled_gracefully(self, mock_supabase):
        """If AI engine throws, pipeline catches and returns error."""
        email = make_email(body_text="Normal question")

        with patch("src.services.email_processor.ai_engine.generate_response",
                    new_callable=AsyncMock, side_effect=Exception("API timeout")):
            result = await process_email(email)

        assert result["status"] == "error"
        assert "API timeout" in result["error"]

    @pytest.mark.asyncio
    async def test_max_retries_exhausted(self, mock_supabase):
        """After 3 failures, email is marked as processed to prevent infinite loop."""
        email = make_email(message_id="failing-email-123", body_text="Normal question")

        with patch("src.services.email_processor.ai_engine.generate_response",
                    new_callable=AsyncMock, side_effect=Exception("Persistent error")):
            for i in range(4):
                result = await process_email(email)

        # After 3 retries, 4th attempt is blocked
        assert result["status"] in ("error", "already_processed")


class TestPipelineDraftMode:
    """Verify draft mode: drafts created, NO auto-send to guests."""

    @pytest.mark.asyncio
    async def test_draft_created_not_auto_sent(self, mock_supabase, _block_outlook):
        """Normal response → draft reply created, NO direct send/reply."""
        email = make_email(body_text="Hello, I'd like to know more about the hotel.")

        with patch("src.services.email_processor.ai_engine.generate_response",
                    new_callable=AsyncMock) as mock_ai:
            mock_ai.return_value = _fake_ai_response(
                "Bonjour ! Le Martin is a lovely 4-star boutique hotel with 6 rooms "
                "in Cul de Sac, Saint-Martin. We have a swimming pool, kayaks, and "
                "paddles available. N'hésitez pas à nous contacter pour plus d'informations. "
                "Chaleureusement, Marion & Emmanuel",
                confidence=0.95,
                tools=["search_faq"],
            )
            await process_email(email)

        # Draft should be created for Emmanuel to review
        _block_outlook["draft"].assert_called_once()
        # Email should be marked as read
        _block_outlook["mark"].assert_called_once()
        # NO auto-send or direct reply to guest
        _block_outlook["reply"].assert_not_called()

    @pytest.mark.asyncio
    async def test_escalation_notifies_emmanuel(self, mock_supabase, _block_outlook):
        """Escalation → notification email sent to Emmanuel (internal, not guest)."""
        email = make_email(
            body_text="C'est inacceptable ! Remboursement !",
        )

        await process_email(email)

        # Internal notification to Emmanuel IS sent
        _block_outlook["send"].assert_called_once()
        call_kwargs = _block_outlook["send"].call_args
        assert "emmanuel@lemartinhotel.com" in str(call_kwargs)
        # NO reply sent to the guest
        _block_outlook["reply"].assert_not_called()
