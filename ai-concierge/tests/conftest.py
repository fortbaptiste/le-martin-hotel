"""Shared fixtures — mock Outlook, mock Supabase, fake emails."""

from __future__ import annotations

import uuid
from datetime import datetime
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.models.message import InboundEmail


# ── Disable real Outlook & Supabase everywhere ───────────────────────


@pytest.fixture(autouse=True)
def _block_outlook():
    """Prevent ANY real Outlook call in all tests."""
    with patch("src.services.outlook.send_email", new_callable=AsyncMock) as send, \
         patch("src.services.outlook.create_draft_reply", new_callable=AsyncMock) as draft, \
         patch("src.services.outlook.send_reply", new_callable=AsyncMock) as reply, \
         patch("src.services.outlook.fetch_unread_emails", new_callable=AsyncMock, return_value=[]) as fetch, \
         patch("src.services.outlook.mark_as_read", new_callable=AsyncMock) as mark:
        send.return_value = {"id": "mock-sent"}
        draft.return_value = "mock-draft-id"
        reply.return_value = None
        yield {
            "send": send,
            "draft": draft,
            "reply": reply,
            "fetch": fetch,
            "mark": mark,
        }


@pytest.fixture()
def mock_supabase():
    """Provide a dict of AsyncMock Supabase functions."""
    fakes = {
        "get_client_by_email": AsyncMock(return_value=None),
        "create_client_record": AsyncMock(side_effect=lambda d: {
            "id": str(uuid.uuid4()), **d,
        }),
        "update_client": AsyncMock(return_value={}),
        "get_conversation_by_thread": AsyncMock(return_value=None),
        "create_conversation": AsyncMock(side_effect=lambda d: {
            "id": str(uuid.uuid4()), **d,
        }),
        "update_conversation": AsyncMock(return_value={}),
        "create_message": AsyncMock(side_effect=lambda d: {
            "id": str(uuid.uuid4()), **d,
        }),
        "update_message": AsyncMock(return_value={}),
        "get_conversation_messages": AsyncMock(return_value=[]),
        "create_escalation": AsyncMock(return_value={"id": str(uuid.uuid4())}),
        "get_active_rules": AsyncMock(return_value=[]),
        "get_rooms": AsyncMock(return_value=[
            {
                "id": "r1", "slug": "deluxe-vue-mer", "name": "Suite Deluxe",
                "category": "deluxe",
                "public_category_fr": "Suite Deluxe vue mer",
                "public_category_en": "Deluxe Sea View Suite",
                "size_m2": 45, "bed_type": "Queen", "bed_twinable": False,
                "extra_bed_price": 115.0, "child_supplement": 150.0,
                "view_fr": "Vue mer panoramique", "view_en": "Panoramic sea view",
                "floor": "1er étage", "capacity_adults": 2, "capacity_children": 0,
                "amenities": ["wifi", "minibar", "safe"],
            },
        ]),
        "get_room_by_slug": AsyncMock(return_value=None),
        "search_restaurants": AsyncMock(return_value=[
            {
                "id": "rest1", "name": "Le Tropicana", "area": "Orient Bay",
                "cuisine": "Français élégant", "price": "€€",
                "driving_time_min": 8, "walkable": False,
                "access_note_fr": "8 min en voiture depuis l'hôtel",
                "best_for": ["lunch", "casual", "returning_guests"],
                "description_fr": "Restaurant apprécié des habitués.",
            },
        ]),
        "search_beaches": AsyncMock(return_value=[
            {
                "id": "b1", "name": "Anse Marcel", "side": "french",
                "driving_time_min": 10, "best_for": ["quiet", "family"],
            },
        ]),
        "get_hotel_services": AsyncMock(return_value=[]),
        "search_activities": AsyncMock(return_value=[]),
        "get_faq": AsyncMock(return_value=[]),
        "get_practical_info": AsyncMock(return_value=[]),
        "get_partners": AsyncMock(return_value=[]),
        "get_transport_schedules": AsyncMock(return_value=[]),
        "get_email_templates": AsyncMock(return_value=[]),
        "get_email_examples": AsyncMock(return_value=[]),
        "get_client_reservations": AsyncMock(return_value=[]),
        "get_messages_stats_for_date": AsyncMock(return_value={
            "emails_received": 0, "emails_replied": 0,
            "avg_confidence_score": None, "avg_response_time_ms": None,
            "total_tokens_used": 0, "total_cost_eur": 0.0,
        }),
        "get_escalations_count_for_date": AsyncMock(return_value=0),
        "upsert_daily_summary": AsyncMock(return_value={}),
        "get_daily_summary": AsyncMock(return_value=None),
    }
    patches = []
    for name, mock in fakes.items():
        p = patch(f"src.services.supabase_client.{name}", mock)
        p.start()
        patches.append(p)
    yield fakes
    for p in patches:
        p.stop()


# ── Fake email factory ───────────────────────────────────────────────

def make_email(
    *,
    from_email: str = "guest@example.com",
    from_name: str = "Test Guest",
    subject: str = "Test email",
    body_text: str = "",
    body_html: str = "",
    message_id: str | None = None,
    conversation_id: str | None = None,
) -> InboundEmail:
    return InboundEmail(
        outlook_message_id=message_id or f"msg-{uuid.uuid4().hex[:8]}",
        outlook_thread_id=f"thread-{uuid.uuid4().hex[:8]}",
        outlook_conversation_id=conversation_id or f"conv-{uuid.uuid4().hex[:8]}",
        from_email=from_email,
        from_name=from_name,
        to_email="info@lemartinhotel.com",
        subject=subject,
        body_text=body_text,
        body_html=body_html,
        received_at=datetime.now(),
    )
