"""Dispatch tool_name → async handler.  Returns JSON-serialisable results."""

from __future__ import annotations

import asyncio
import contextvars
import json
import re
from collections import defaultdict
from datetime import date, timedelta

import structlog

from src.services import supabase_client as db
from src.services import thais

log = structlog.get_logger()

# Session context using contextvars — each async task gets its own state,
# preventing race conditions when processing multiple emails concurrently.
# IMPORTANT: default=None (not mutable []) to avoid sharing state across contexts.
_last_reservation_lookup: contextvars.ContextVar[list[dict] | None] = contextvars.ContextVar(
    "_last_reservation_lookup", default=None
)
_pending_team_actions: contextvars.ContextVar[list[dict] | None] = contextvars.ContextVar(
    "_pending_team_actions", default=None
)


def get_pending_team_actions() -> list[dict]:
    """Return pending team actions and clear the list."""
    actions = list(_pending_team_actions.get() or [])
    _pending_team_actions.set([])
    return actions


def clear_session_state():
    """Clear all session state between pipeline runs."""
    _last_reservation_lookup.set([])
    _pending_team_actions.set([])


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

async def _check_room_availability(params: dict) -> list[dict] | dict:
    # Parse and validate dates
    try:
        checkin = date.fromisoformat(params["checkin"])
        checkout = date.fromisoformat(params["checkout"])
    except (ValueError, KeyError) as exc:
        return {"error": f"Invalid date format. Use YYYY-MM-DD. Detail: {exc}"}

    if checkin >= checkout:
        return {"error": "checkin must be strictly before checkout."}

    # Reject past dates — we are in 2026, never check 2024/2025
    today = date.today()
    if checkin < today:
        return {"error": f"checkin date {checkin} is in the past (today is {today}). Use a future date. We are in 2026."}

    # ── Stay-extension detection ──
    # If a previous lookup_reservation found a booking that overlaps with the
    # requested dates, the guest's own room will appear unavailable.
    # Detect this and add a warning so the AI knows to check only added nights.
    extension_warning = None
    for resa in (_last_reservation_lookup.get() or []):
        resa_checkin_str = resa.get("check_in") or ""
        resa_checkout_str = resa.get("check_out") or ""
        if not resa_checkin_str or not resa_checkout_str:
            continue
        try:
            resa_checkin = date.fromisoformat(resa_checkin_str[:10])
            resa_checkout = date.fromisoformat(resa_checkout_str[:10])
        except ValueError:
            continue
        # Check overlap: requested range includes nights already booked
        if checkin < resa_checkout and checkout > resa_checkin and checkin < resa_checkin:
            # The AI is checking a range that starts before the existing booking
            # This is not an extension case, skip
            continue
        if checkin < resa_checkout and checkout > resa_checkout and checkin >= resa_checkin:
            # Extension case: guest wants to stay beyond current checkout
            # Their own booking blocks their room for checkin → resa_checkout
            extension_warning = (
                f"WARNING: The guest already has a booking {resa_checkin_str[:10]} to {resa_checkout_str[:10]} "
                f"(ref {resa.get('reference', '?')}). Their own room appears unavailable for those nights. "
                f"For a stay EXTENSION, only the nights from {resa_checkout_str[:10]} to {checkout.isoformat()} matter. "
                f"Re-check with checkin={resa_checkout_str[:10]} and checkout={checkout.isoformat()} to see true availability."
            )
            log.info("tool.extension_detected", resa_ref=resa.get("reference"), resa_checkout=resa_checkout_str[:10])
            break

    room_type_ids = [params["room_type_id"]] if params.get("room_type_id") else None
    avail_results = await thais.check_availability(checkin, checkout, room_type_ids)
    results = [avail.model_dump(mode="json") for avail in avail_results]

    if extension_warning:
        return {"warning": extension_warning, "results": results}

    return results


async def _lookup_reservation(params: dict) -> list[dict] | dict:
    guest_email = (params.get("guest_email") or "").strip()
    guest_name = (params.get("guest_name") or "").strip()

    if not guest_email and not guest_name:
        return {"error": "You must provide at least guest_email or guest_name to search."}

    query = guest_email or guest_name
    results = await thais.get_customer_reservations(query)
    if not results:
        _last_reservation_lookup.set([])
        return {"found": False, "message": "No reservation found for this guest in Thais."}

    # Store for extension detection in check_room_availability
    _last_reservation_lookup.set(results)
    return {"found": True, "reservations": results}


# Internal room names → public categories (never show internal names to guests)
# DB already stores public names, but this is a safety net.
_INTERNAL_TO_PUBLIC: dict[str, dict[str, str]] = {
    "marius":    {"fr": "Suite Deluxe Vue Mer",
                  "en": "Deluxe Sea View Suite"},
    "marcelle":  {"fr": "Suite Deluxe Vue Mer",
                  "en": "Deluxe Sea View Suite"},
    "pierre":    {"fr": "Chambre Privilège",
                  "en": "Privilege Room"},
    "rené":      {"fr": "Suite Deluxe Vue Mer",
                  "en": "Deluxe Sea View Suite"},
    "rene":      {"fr": "Suite Deluxe Vue Mer",
                  "en": "Deluxe Sea View Suite"},
    "marthe":    {"fr": "Suite Deluxe Vue Mer",
                  "en": "Deluxe Sea View Suite"},
    "georgette": {"fr": "Suite Deluxe Vue Mer",
                  "en": "Deluxe Sea View Suite"},
}

_INTERNAL_NAME_RE = re.compile(
    r"\b(?:Suite|Chambre)\s+(Marius|Marcelle|Pierre|René|Rene|Marthe|Georgette)\b",
    re.IGNORECASE,
)


def _sanitize_room(room: dict) -> dict:
    """Replace internal room name with public category."""
    room = dict(room)  # shallow copy
    name = (room.get("name") or "").lower()
    for key, labels in _INTERNAL_TO_PUBLIC.items():
        if key in name:
            room["name"] = labels["en"]
            break
    # Also ensure public_category fields take precedence if present
    if room.get("public_category_en"):
        room["name"] = room["public_category_en"]
    return room


async def _get_room_details(params: dict) -> list[dict] | dict:
    slug = params.get("room_slug")
    if slug:
        room = await db.get_room_by_slug(slug)
        if not room:
            return {"error": f"Room '{slug}' not found"}
        return _sanitize_room(room)
    rooms = await db.get_rooms()
    return [_sanitize_room(r) for r in rooms]


async def _search_restaurants(params: dict) -> list[dict]:
    results = await db.search_restaurants(
        area=params.get("area"),
        cuisine=params.get("cuisine"),
        is_partner=None,
    )
    # Client-side filter for best_for if provided
    # best_for is a Postgres TEXT[] — Supabase returns it as a Python list
    best_for = (params.get("best_for") or "").lower()
    if best_for:
        filtered = []
        for r in results:
            bf_list = r.get("best_for") or []
            # Handle both list (TEXT[]) and string fallback
            if isinstance(bf_list, list):
                bf_text = " ".join(str(item).lower() for item in bf_list)
            else:
                bf_text = str(bf_list).lower()

            if (
                best_for in bf_text
                or best_for in (r.get("ambiance") or "").lower()
                or best_for in (r.get("description_en") or "").lower()
            ):
                filtered.append(r)
        results = filtered
    return results


async def _search_beaches(params: dict) -> list[dict]:
    results = await db.search_beaches(side=params.get("side"))
    best_for = (params.get("best_for") or "").lower()
    if best_for:
        filtered = []
        for r in results:
            bf_list = r.get("best_for") or []
            if isinstance(bf_list, list):
                bf_text = " ".join(str(item).lower() for item in bf_list)
            else:
                bf_text = str(bf_list).lower()

            if (
                best_for in bf_text
                or best_for in (r.get("characteristics") or "").lower()
            ):
                filtered.append(r)
        results = filtered
    return results


async def _get_hotel_services(params: dict) -> list[dict]:
    return await db.get_hotel_services(category=params.get("category"))


async def _search_activities(params: dict) -> list[dict]:
    results = await db.search_activities(category=params.get("category"))
    best_for = (params.get("best_for") or "").lower()
    if best_for:
        filtered = []
        for r in results:
            searchable = " ".join([
                (r.get("name_en") or "").lower(),
                (r.get("name_fr") or "").lower(),
                (r.get("category") or "").lower(),
                (r.get("operator") or "").lower(),
            ])
            if best_for in searchable:
                filtered.append(r)
        results = filtered
    return results


async def _search_faq(params: dict) -> list[dict]:
    return await db.get_faq(category=params.get("category"))


async def _get_transport_schedules(params: dict) -> list[dict]:
    return await db.get_transport_schedules(route=params.get("route"))


async def _get_partner_info(params: dict) -> list[dict]:
    results = await db.get_partners(service_type=params.get("service_type"))
    # Add internal-only warning — AI must NOT share partner names with guests
    for r in results:
        r["_INTERNAL_WARNING"] = (
            "CONFIDENTIAL: Do NOT mention this partner's name to the guest. "
            "Use generic terms ('our boat partner', 'a nearby gym', 'our car rental partner'). "
            "The hotel LOSES commission if guests contact partners directly. "
            "Use the name ONLY in request_team_action for internal follow-up."
        )
    return results


async def _get_client_history(params: dict) -> dict:
    email = params.get("client_email", "")
    if not email:
        return {"error": "client_email is required"}
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


async def _check_availability_range(params: dict) -> dict:
    """Check availability night-by-night over a date range for counter-proposals.

    Optimized: fetches availability + prices for the FULL range in a single API call,
    then analyzes per-night data locally. Much faster than N sequential calls.
    """
    try:
        start = date.fromisoformat(params["start_date"])
        end = date.fromisoformat(params["end_date"])
    except (ValueError, KeyError) as exc:
        return {"error": f"Invalid date format. Use YYYY-MM-DD. Detail: {exc}"}

    if start >= end:
        return {"error": "start_date must be strictly before end_date."}

    today = date.today()
    if start < today:
        return {"error": f"start_date {start} is in the past (today is {today}). Use a future date."}

    num_nights = (end - start).days
    if num_nights > 14:
        return {"error": f"Range too large ({num_nights} nights). Maximum is 14 nights."}

    try:
        # Single API call for full range — availability endpoint returns per-night data
        from src.config import settings as _settings
        avail_url = f"{_settings.thais_api_url}/hub/api/partner/hotel/apr/availabilities/currents"
        prices_url = f"{_settings.thais_api_url}/hub/api/partner/hotel/apr/prices/currents"
        range_params: dict = {"from": start.isoformat(), "to": end.isoformat()}

        avail_resp, prices_resp, rt_map = await asyncio.gather(
            thais._api_request("GET", avail_url, params=range_params),
            thais._api_request("GET", prices_url, params=range_params),
            thais._room_type_label_map(),
        )

        # Parse availability per (room_type_id, date)
        avail_data = avail_resp.json()
        avail_items = avail_data if isinstance(avail_data, list) else avail_data.get("data", [])

        # Group by (rt_id, date_str)
        avail_by_night: dict[str, dict[int, int]] = defaultdict(dict)  # date_str → {rt_id → count}
        for item in avail_items:
            rt_id = item.get("room_type_id")
            if rt_id in thais._NON_ROOM_TYPE_IDS:
                continue
            # Thais returns date as "from" or "date" field
            item_date = item.get("date") or item.get("from", "")
            if item_date:
                avail_by_night[item_date[:10]][rt_id] = item.get("availability", 0)

        # Parse prices per (rt_id, rate_id, date)
        prices_data = prices_resp.json()
        price_items = prices_data if isinstance(prices_data, list) else prices_data.get("data", [])

        prices_by_night: dict[str, dict[int, float]] = defaultdict(dict)  # date_str → {rt_id → price}
        for p in price_items:
            rt_id = p.get("room_type_id")
            rate_id = p.get("rate_id")
            if rate_id != thais._RATE_BEST_FLEXIBLE:
                continue  # Only show Best Flexible for counter-proposals
            item_date = p.get("date") or p.get("from", "")
            price_val = p.get("price")
            if item_date and price_val is not None:
                prices_by_night[item_date[:10]][rt_id] = float(price_val)

        # Build night-by-night summary
        nights: list[dict] = []
        for i in range(num_nights):
            night_date = start + timedelta(days=i)
            next_date = night_date + timedelta(days=1)
            date_str = night_date.isoformat()
            label = f"{night_date.strftime('%d/%m')} → {next_date.strftime('%d/%m')}"

            avail_for_night = avail_by_night.get(date_str, {})
            prices_for_night = prices_by_night.get(date_str, {})

            room_strs = []
            for rt_id in sorted(thais._ACTIVE_ROOM_TYPE_IDS):
                count = avail_for_night.get(rt_id, 0)
                if count > 0:
                    name = rt_map.get(rt_id, f"Type {rt_id}")
                    # Extract short English name from parentheses
                    short_name = name.split("(")[-1].rstrip(")") if "(" in name else name
                    price = prices_for_night.get(rt_id)
                    price_str = f"{price:.0f}€" if price else "prix sur demande"
                    room_strs.append(f"{short_name} {price_str} ({count} dispo)")

            if room_strs:
                nights.append({"night": label, "status": ", ".join(room_strs)})
            else:
                nights.append({"night": label, "status": "COMPLET"})

    except Exception as exc:
        log.warning("tool.availability_range.error", error=str(exc))
        return {"error": f"Erreur lors de la vérification : {exc}"}

    # Format as readable text for the AI
    lines = [f"Disponibilités nuit par nuit ({start.strftime('%d/%m')} → {end.strftime('%d/%m')}):"]
    for n in nights:
        lines.append(f"- {n['night']}: {n['status']}")

    return {"summary": "\n".join(lines), "nights": nights}


async def _request_team_action(params: dict) -> dict:
    action = params.get("action", "")
    if not action:
        return {"error": "action is required"}
    entry = {
        "action": action,
        "partner_name": params.get("partner_name", ""),
        "guest_name": params.get("guest_name", ""),
        "urgency": params.get("urgency", "normal"),
    }
    actions = _pending_team_actions.get() or []
    actions.append(entry)
    _pending_team_actions.set(actions)
    log.info("tool.team_action_requested", action=action)
    return {"status": "ok", "message": "Action noted. The team will be notified."}


# ---------------------------------------------------------------------------
# Dispatch map
# ---------------------------------------------------------------------------

_HANDLERS = {
    "check_room_availability": _check_room_availability,
    "lookup_reservation": _lookup_reservation,
    "get_room_details": _get_room_details,
    "search_restaurants": _search_restaurants,
    "search_beaches": _search_beaches,
    "get_hotel_services": _get_hotel_services,
    "search_activities": _search_activities,
    "search_faq": _search_faq,
    "get_transport_schedules": _get_transport_schedules,
    "get_partner_info": _get_partner_info,
    "get_client_history": _get_client_history,
    "get_email_template": _get_email_template,
    "get_practical_info": _get_practical_info,
    "check_availability_range": _check_availability_range,
    "request_team_action": _request_team_action,
}
