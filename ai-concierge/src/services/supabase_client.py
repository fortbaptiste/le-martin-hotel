"""Supabase CRUD — all 21 tables."""

from __future__ import annotations

from typing import Any

import structlog
from supabase import create_client, Client

from src.config import settings

log = structlog.get_logger()

# ---------------------------------------------------------------------------
# Singleton client
# ---------------------------------------------------------------------------

_client: Client | None = None


def get_client() -> Client:
    global _client
    if _client is None:
        key = settings.supabase_service_role_key or settings.supabase_anon_key
        _client = create_client(settings.supabase_url, key)
    return _client


# ---------------------------------------------------------------------------
# Generic helpers
# ---------------------------------------------------------------------------

def _table(name: str):
    return get_client().table(name)


async def _select(table: str, columns: str = "*", filters: dict[str, Any] | None = None,
                  order: str | None = None, limit: int | None = None) -> list[dict]:
    q = _table(table).select(columns)
    if filters:
        for col, val in filters.items():
            q = q.eq(col, val)
    if order:
        desc = order.startswith("-")
        col = order.lstrip("-")
        q = q.order(col, desc=desc)
    if limit:
        q = q.limit(limit)
    resp = q.execute()
    return resp.data or []


async def _insert(table: str, data: dict[str, Any]) -> dict:
    resp = _table(table).insert(data).execute()
    rows = resp.data or []
    return rows[0] if rows else {}


async def _update(table: str, id_val: str, data: dict[str, Any]) -> dict:
    resp = _table(table).update(data).eq("id", id_val).execute()
    rows = resp.data or []
    return rows[0] if rows else {}


async def _upsert(table: str, data: dict[str, Any]) -> dict:
    resp = _table(table).upsert(data).execute()
    rows = resp.data or []
    return rows[0] if rows else {}


# ---------------------------------------------------------------------------
# Clients
# ---------------------------------------------------------------------------

async def get_client_by_email(email: str) -> dict | None:
    rows = await _select("clients", filters={"email": email}, limit=1)
    return rows[0] if rows else None


async def create_client_record(data: dict[str, Any]) -> dict:
    return await _insert("clients", data)


async def update_client(client_id: str, data: dict[str, Any]) -> dict:
    return await _update("clients", client_id, data)


# ---------------------------------------------------------------------------
# Conversations
# ---------------------------------------------------------------------------

async def get_conversation_by_thread(thread_id: str) -> dict | None:
    rows = await _select("conversations", filters={"outlook_conversation_id": thread_id}, limit=1)
    return rows[0] if rows else None


async def create_conversation(data: dict[str, Any]) -> dict:
    return await _insert("conversations", data)


async def update_conversation(conv_id: str, data: dict[str, Any]) -> dict:
    return await _update("conversations", conv_id, data)


# ---------------------------------------------------------------------------
# Messages
# ---------------------------------------------------------------------------

async def create_message(data: dict[str, Any]) -> dict:
    return await _insert("messages", data)


async def update_message(msg_id: str, data: dict[str, Any]) -> dict:
    return await _update("messages", msg_id, data)


async def get_conversation_messages(conv_id: str, limit: int = 20) -> list[dict]:
    return await _select("messages", filters={"conversation_id": conv_id}, order="-created_at", limit=limit)


# ---------------------------------------------------------------------------
# Reservations
# ---------------------------------------------------------------------------

async def get_client_reservations(client_id: str) -> list[dict]:
    return await _select("reservations", filters={"client_id": client_id}, order="-checkin_date")


# ---------------------------------------------------------------------------
# Escalations
# ---------------------------------------------------------------------------

async def create_escalation(data: dict[str, Any]) -> dict:
    return await _insert("escalations", data)


# ---------------------------------------------------------------------------
# AI Rules
# ---------------------------------------------------------------------------

async def get_active_rules() -> list[dict]:
    q = _table("ai_rules").select("*").eq("is_active", True).order("priority", desc=True)
    resp = q.execute()
    return resp.data or []


# ---------------------------------------------------------------------------
# Daily Summaries
# ---------------------------------------------------------------------------

async def upsert_daily_summary(data: dict[str, Any]) -> dict:
    return await _upsert("daily_summaries", data)


async def get_daily_summary(date_str: str) -> dict | None:
    rows = await _select("daily_summaries", filters={"date": date_str}, limit=1)
    return rows[0] if rows else None


# ---------------------------------------------------------------------------
# Knowledge base — read-only lookups
# ---------------------------------------------------------------------------

async def get_rooms(active_only: bool = True) -> list[dict]:
    filters = {"is_active": True} if active_only else None
    return await _select("rooms", filters=filters, order="sort_order")


async def get_room_by_slug(slug: str) -> dict | None:
    rows = await _select("rooms", filters={"slug": slug}, limit=1)
    return rows[0] if rows else None


async def get_hotel_services(category: str | None = None) -> list[dict]:
    filters: dict[str, Any] = {"is_active": True}
    if category:
        filters["category"] = category
    return await _select("hotel_services", filters=filters, order="sort_order")


async def search_restaurants(
    area: str | None = None,
    cuisine: str | None = None,
    is_partner: bool | None = None,
) -> list[dict]:
    q = _table("restaurants").select("*")
    if area:
        q = q.ilike("area", f"%{area}%")
    if cuisine:
        q = q.ilike("cuisine", f"%{cuisine}%")
    if is_partner is not None:
        q = q.eq("is_partner", is_partner)
    q = q.order("sort_order")
    resp = q.execute()
    return resp.data or []


async def search_beaches(side: str | None = None) -> list[dict]:
    filters: dict[str, Any] = {}
    if side:
        filters["side"] = side
    return await _select("beaches", filters=filters if filters else None, order="sort_order")


async def search_activities(category: str | None = None) -> list[dict]:
    filters: dict[str, Any] = {}
    if category:
        filters["category"] = category
    return await _select("activities", filters=filters if filters else None, order="sort_order")


async def get_faq(category: str | None = None) -> list[dict]:
    filters: dict[str, Any] = {}
    if category:
        filters["category"] = category
    return await _select("faq", filters=filters if filters else None, order="sort_order")


async def get_practical_info(category: str | None = None) -> list[dict]:
    filters: dict[str, Any] = {}
    if category:
        filters["category"] = category
    return await _select("practical_info", filters=filters if filters else None, order="sort_order")


async def get_partners(service_type: str | None = None) -> list[dict]:
    filters: dict[str, Any] = {"is_active": True}
    if service_type:
        filters["service_type"] = service_type
    return await _select("partners", filters=filters)


async def get_transport_schedules(route: str | None = None) -> list[dict]:
    filters: dict[str, Any] = {"is_active": True}
    if route:
        filters["route"] = route
    return await _select("transport_schedules", filters=filters)


async def get_email_templates(category: str | None = None, language: str | None = None) -> list[dict]:
    filters: dict[str, Any] = {"is_active": True}
    if category:
        filters["category"] = category
    if language:
        filters["language"] = language
    return await _select("email_templates", filters=filters)


async def get_email_examples(category: str | None = None) -> list[dict]:
    filters: dict[str, Any] = {}
    if category:
        filters["category"] = category
    return await _select("email_examples", filters=filters)


# ---------------------------------------------------------------------------
# Stats helpers (for daily summary)
# ---------------------------------------------------------------------------

async def get_messages_stats_for_date(date_str: str) -> dict:
    """Aggregate message stats for a given date."""
    q = (
        _table("messages")
        .select("direction,confidence_score,tokens_input,tokens_output,cost_eur,response_time_ms")
        .gte("created_at", f"{date_str}T00:00:00")
        .lt("created_at", f"{date_str}T23:59:59")
    )
    resp = q.execute()
    rows = resp.data or []

    inbound = [r for r in rows if r.get("direction") == "inbound"]
    outbound = [r for r in rows if r.get("direction") == "outbound"]
    scores = [r["confidence_score"] for r in outbound if r.get("confidence_score") is not None]
    times = [r["response_time_ms"] for r in outbound if r.get("response_time_ms") is not None]

    return {
        "emails_received": len(inbound),
        "emails_replied": len(outbound),
        "avg_confidence_score": round(sum(scores) / len(scores), 2) if scores else None,
        "avg_response_time_ms": int(sum(times) / len(times)) if times else None,
        "total_tokens_used": sum(r.get("tokens_input", 0) + r.get("tokens_output", 0) for r in rows),
        "total_cost_eur": round(sum(r.get("cost_eur", 0) for r in rows), 4),
    }


async def get_escalations_count_for_date(date_str: str) -> int:
    q = (
        _table("escalations")
        .select("id", count="exact")
        .gte("created_at", f"{date_str}T00:00:00")
        .lt("created_at", f"{date_str}T23:59:59")
    )
    resp = q.execute()
    return resp.count or 0
