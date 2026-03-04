"""Dispatch tool_name → async handler.  Returns JSON-serialisable results."""

from __future__ import annotations

import json
from datetime import date

import structlog

from src.services import supabase_client as db
from src.services import thais

log = structlog.get_logger()


async def handle_tool_call(tool_name: str, tool_input: dict) -> str:
    """Execute a tool call and return the result as a JSON string."""
    handler = _HANDLERS.get(tool_name)
    if handler is None:
        return json.dumps({"error": f"Unknown tool: {tool_name}"})

    try:
        result = await handler(tool_input)
        return json.dumps(result, ensure_ascii=False, default=str)
    except Exception as exc:
        log.error("tool.error", tool=tool_name, error=str(exc))
        return json.dumps({"error": str(exc)})


# ---------------------------------------------------------------------------
# Individual handlers
# ---------------------------------------------------------------------------

async def _check_room_availability(params: dict) -> list[dict]:
    checkin = date.fromisoformat(params["checkin"])
    checkout = date.fromisoformat(params["checkout"])
    room_type_ids = [params["room_type_id"]] if params.get("room_type_id") else None
    results = await thais.check_availability(checkin, checkout, room_type_ids)
    return [r.model_dump(mode="json") for r in results]


async def _get_room_details(params: dict) -> list[dict] | dict:
    slug = params.get("room_slug")
    if slug:
        room = await db.get_room_by_slug(slug)
        return room or {"error": f"Room '{slug}' not found"}
    return await db.get_rooms()


async def _search_restaurants(params: dict) -> list[dict]:
    results = await db.search_restaurants(
        area=params.get("area"),
        cuisine=params.get("cuisine"),
        is_partner=None,
    )
    # Client-side filter for best_for if provided
    best_for = params.get("best_for", "").lower()
    if best_for:
        results = [
            r for r in results
            if best_for in " ".join(r.get("best_for", [])).lower()
            or best_for in (r.get("ambiance") or "").lower()
            or best_for in (r.get("description_en") or "").lower()
        ]
    return results


async def _search_beaches(params: dict) -> list[dict]:
    results = await db.search_beaches(side=params.get("side"))
    best_for = params.get("best_for", "").lower()
    if best_for:
        results = [
            r for r in results
            if best_for in " ".join(r.get("best_for", [])).lower()
            or best_for in (r.get("characteristics") or "").lower()
        ]
    return results


async def _search_activities(params: dict) -> list[dict]:
    return await db.search_activities(category=params.get("category"))


async def _get_hotel_services(params: dict) -> list[dict]:
    return await db.get_hotel_services(category=params.get("category"))


async def _search_faq(params: dict) -> list[dict]:
    return await db.get_faq(category=params.get("category"))


async def _get_transport_schedules(params: dict) -> list[dict]:
    return await db.get_transport_schedules(route=params.get("route"))


async def _get_partner_info(params: dict) -> list[dict]:
    return await db.get_partners(service_type=params.get("service_type"))


async def _get_client_history(params: dict) -> dict:
    email = params["client_email"]
    client = await db.get_client_by_email(email)
    if not client:
        return {"found": False, "message": "No previous record for this guest."}

    reservations = await db.get_client_reservations(client["id"])
    return {
        "found": True,
        "client": client,
        "reservations": reservations,
    }


async def _get_email_template(params: dict) -> list[dict]:
    return await db.get_email_templates(
        category=params.get("category"),
        language=params.get("language"),
    )


async def _get_practical_info(params: dict) -> list[dict]:
    return await db.get_practical_info(category=params.get("category"))


# ---------------------------------------------------------------------------
# Dispatch map
# ---------------------------------------------------------------------------

_HANDLERS = {
    "check_room_availability": _check_room_availability,
    "get_room_details": _get_room_details,
    "search_restaurants": _search_restaurants,
    "search_beaches": _search_beaches,
    "search_activities": _search_activities,
    "get_hotel_services": _get_hotel_services,
    "search_faq": _search_faq,
    "get_transport_schedules": _get_transport_schedules,
    "get_partner_info": _get_partner_info,
    "get_client_history": _get_client_history,
    "get_email_template": _get_email_template,
    "get_practical_info": _get_practical_info,
}
