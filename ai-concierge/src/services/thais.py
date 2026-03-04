"""Thais PMS API — JWT auth, availability, room types, customer search."""

from __future__ import annotations

import time
from datetime import date

import httpx
import structlog

from src.config import settings
from src.exceptions import ThaisError
from src.models.reservation import RoomAvailability

log = structlog.get_logger()

# ---------------------------------------------------------------------------
# JWT token management (valid 10 minutes)
# ---------------------------------------------------------------------------

_jwt_token: str | None = None
_jwt_expires_at: float = 0.0


async def _ensure_token() -> str:
    global _jwt_token, _jwt_expires_at
    if _jwt_token and time.time() < _jwt_expires_at - 30:
        return _jwt_token

    url = f"{settings.thais_api_url}/hub/api/partner/login"
    payload = {"username": settings.thais_api_user, "password": settings.thais_api_password}
    headers = {"User-Agent": settings.thais_user_agent, "Content-Type": "application/json"}

    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.post(url, json=payload, headers=headers)
        if resp.status_code == 429:
            raise ThaisError("Thais rate-limited (429). Retry later.")
        if resp.status_code != 200:
            raise ThaisError(f"Thais login failed ({resp.status_code}): {resp.text}")
        data = resp.json()

    _jwt_token = data.get("token") or data.get("access_token")
    if not _jwt_token:
        raise ThaisError(f"No token in Thais response: {data}")

    _jwt_expires_at = time.time() + 540  # 9 minutes (safe margin)
    log.debug("thais.authenticated")
    return _jwt_token


def _headers(token: str) -> dict[str, str]:
    return {
        "Authorization": f"Bearer {token}",
        "User-Agent": settings.thais_user_agent,
        "Accept": "application/json",
    }


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

async def check_availability(
    checkin: date,
    checkout: date,
    room_type_ids: list[str] | None = None,
) -> list[RoomAvailability]:
    """Check room availability and pricing from Thais PMS."""
    token = await _ensure_token()
    url = f"{settings.thais_api_url}/hub/api/partner/hotel/apr/availabilities/currents"

    params: dict[str, str | list[str]] = {
        "from": checkin.isoformat(),
        "to": checkout.isoformat(),
    }
    if room_type_ids:
        params["room_type_id[]"] = room_type_ids

    async with httpx.AsyncClient(timeout=20) as client:
        resp = await client.get(url, params=params, headers=_headers(token))
        if resp.status_code == 429:
            raise ThaisError("Thais rate-limited (429). Retry later.")
        if resp.status_code != 200:
            raise ThaisError(f"Thais availability failed ({resp.status_code}): {resp.text}")
        data = resp.json()

    results: list[RoomAvailability] = []
    items = data if isinstance(data, list) else data.get("data", data.get("availabilities", []))

    for item in items:
        # Thais returns varied structures; adapt gracefully
        room_type = item.get("room_type", item.get("roomType", {}))
        rates = item.get("rates", item.get("prices", []))

        if isinstance(room_type, dict):
            rt_id = str(room_type.get("id", ""))
            rt_name = room_type.get("name", room_type.get("label", ""))
        else:
            rt_id = str(item.get("room_type_id", ""))
            rt_name = str(item.get("room_type_name", ""))

        available = bool(item.get("available", item.get("is_available", True)))

        price_per_night = None
        total_price = None
        rate_name = None

        if rates and isinstance(rates, list):
            best = rates[0]
            price_per_night = best.get("price_per_night", best.get("pricePerNight"))
            total_price = best.get("total", best.get("totalPrice"))
            rate_name = best.get("name", best.get("rateName"))
        elif isinstance(item.get("price"), (int, float)):
            price_per_night = item["price"]

        results.append(RoomAvailability(
            room_type_id=rt_id,
            room_type_name=rt_name,
            available=available,
            price_per_night=price_per_night,
            total_price=total_price,
            currency=item.get("currency", "EUR"),
            rate_name=rate_name,
            checkin=checkin,
            checkout=checkout,
        ))

    log.info("thais.availability_checked", checkin=str(checkin), checkout=str(checkout), results=len(results))
    return results


async def get_room_types() -> list[dict]:
    """Fetch room type definitions from Thais."""
    token = await _ensure_token()
    url = f"{settings.thais_api_url}/hub/api/partner/hotel/room-types"
    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.get(url, headers=_headers(token))
        if resp.status_code != 200:
            raise ThaisError(f"Thais room-types failed ({resp.status_code}): {resp.text}")
        data = resp.json()
    items = data if isinstance(data, list) else data.get("data", [])
    log.debug("thais.room_types", count=len(items))
    return items


async def search_customer(query: str) -> list[dict]:
    """Search customers in Thais PMS by name or email."""
    token = await _ensure_token()
    url = f"{settings.thais_api_url}/hub/api/partner/resort/customers"
    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.get(url, params={"q": query}, headers=_headers(token))
        if resp.status_code != 200:
            raise ThaisError(f"Thais customer search failed ({resp.status_code}): {resp.text}")
        data = resp.json()
    items = data if isinstance(data, list) else data.get("data", [])
    log.debug("thais.customer_search", query=query, results=len(items))
    return items


async def get_hotel_config() -> dict:
    """Fetch hotel configuration (room types, rates, etc.)."""
    token = await _ensure_token()
    url = f"{settings.thais_api_url}/hub/api/partner/config"
    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.get(url, params={"lang": "fr"}, headers=_headers(token))
        if resp.status_code != 200:
            raise ThaisError(f"Thais config failed ({resp.status_code}): {resp.text}")
    return resp.json()
