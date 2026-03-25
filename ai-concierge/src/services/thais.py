"""Thais PMS API — JWT auth, availability, room types, customer search, pricing.

Improvements over v1:
- asyncio.Lock for thread-safe JWT token management (double-check pattern)
- time.monotonic() for token expiry (immune to wall-clock drift)
- Persistent httpx.AsyncClient (lazy-initialized, module-level)
- Exponential backoff retry on 429 / auto re-auth on 401
- Pricing integrated into check_availability results
- Non-room type IDs filtered out (Petit déjeuner, Fictive-Relogements)
- customer_id filter on /bookings endpoint (no more full-scan)
- Room types cached for 10 minutes
- /hotel/pricing endpoint for computed stay pricing (incl. breakfast + tourist tax)
"""

from __future__ import annotations

import asyncio
import time
from collections import defaultdict
from datetime import date
from decimal import Decimal

import httpx
import structlog

from src.config import settings
from src.exceptions import ThaisError
from src.models.reservation import RoomAvailability

log = structlog.get_logger()

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# IDs that are not real room types (Petit déjeuner=16, Fictive-Relogements=17)
_NON_ROOM_TYPE_IDS: set[int] = {16, 17}

# Active room type IDs at Le Martin
_ACTIVE_ROOM_TYPE_IDS: set[int] = {2, 7, 10, 13}

# Direct-booking rate IDs
_RATE_BEST_FLEXIBLE: int = 7
_RATE_ADVANCE_PURCHASE: int = 57
_DIRECT_RATE_IDS: set[int] = {_RATE_BEST_FLEXIBLE, _RATE_ADVANCE_PURCHASE}

_RATE_LABELS: dict[int, str] = {
    _RATE_BEST_FLEXIBLE: "Best Flexible Rate",
    _RATE_ADVANCE_PURCHASE: "Advance Purchase Rate (-10%)",
}

# ---------------------------------------------------------------------------
# JWT token management (double-check pattern with asyncio.Lock)
# ---------------------------------------------------------------------------

_jwt_token: str | None = None
_jwt_expires_at: float = 0.0  # monotonic clock
_token_lock = asyncio.Lock()


async def _ensure_token() -> str:
    """Return a valid JWT token, authenticating if needed.

    Uses a double-check pattern: fast path without lock, slow path with lock.
    """
    global _jwt_token, _jwt_expires_at

    # Fast path — no lock needed if token is still valid
    if _jwt_token and time.monotonic() < _jwt_expires_at - 30:
        return _jwt_token

    # Slow path — acquire lock and re-check
    async with _token_lock:
        # Another coroutine may have refreshed while we waited
        if _jwt_token and time.monotonic() < _jwt_expires_at - 30:
            return _jwt_token

        token = await _authenticate()
        return token


async def _authenticate() -> str:
    """Perform login against Thais and store the JWT token."""
    global _jwt_token, _jwt_expires_at

    url = f"{settings.thais_api_url}/hub/api/partner/login"
    payload = {"username": settings.thais_api_user, "password": settings.thais_api_password}
    headers = {"User-Agent": settings.thais_user_agent, "Content-Type": "application/json"}

    client = await _get_client()
    try:
        resp = await client.post(url, json=payload, headers=headers)
    except httpx.TimeoutException as exc:
        raise ThaisError(f"Thais login timed out: {exc}") from exc

    if resp.status_code == 429:
        raise ThaisError("Thais rate-limited during login (429). Retry later.")
    if resp.status_code != 200:
        raise ThaisError(f"Thais login failed ({resp.status_code}): {resp.text}")

    data = resp.json()
    _jwt_token = data.get("token") or data.get("access_token")
    if not _jwt_token:
        raise ThaisError(f"No token in Thais login response: {data}")

    _jwt_expires_at = time.monotonic() + 540  # 9 min safe margin on 10 min TTL
    log.debug("thais.authenticated")
    return _jwt_token


def _clear_token() -> None:
    """Invalidate the cached JWT so the next call re-authenticates."""
    global _jwt_token, _jwt_expires_at
    _jwt_token = None
    _jwt_expires_at = 0.0


def _auth_headers(token: str) -> dict[str, str]:
    return {
        "Authorization": f"Bearer {token}",
        "User-Agent": settings.thais_user_agent,
        "Accept": "application/json",
    }


# ---------------------------------------------------------------------------
# Persistent httpx.AsyncClient (lazy-initialized)
# ---------------------------------------------------------------------------

_http_client: httpx.AsyncClient | None = None
_client_lock = asyncio.Lock()


async def _get_client() -> httpx.AsyncClient:
    """Return the module-level httpx.AsyncClient, creating it if needed."""
    global _http_client
    if _http_client is not None and not _http_client.is_closed:
        return _http_client

    async with _client_lock:
        if _http_client is not None and not _http_client.is_closed:
            return _http_client
        _http_client = httpx.AsyncClient(
            timeout=httpx.Timeout(20.0, connect=10.0),
            limits=httpx.Limits(max_connections=10, max_keepalive_connections=5),
        )
        return _http_client


async def close_client() -> None:
    """Gracefully close the persistent HTTP client (call at shutdown)."""
    global _http_client
    if _http_client is not None and not _http_client.is_closed:
        await _http_client.aclose()
        _http_client = None


# ---------------------------------------------------------------------------
# Circuit breaker — skip Thais if it's been failing repeatedly
# ---------------------------------------------------------------------------

_cb_failure_count: int = 0
_cb_open_until: float = 0.0  # monotonic timestamp
_CB_THRESHOLD: int = 3       # open circuit after 3 consecutive failures
_CB_COOLDOWN: float = 300.0  # 5 minutes before half-open retry


def _cb_record_success() -> None:
    global _cb_failure_count
    _cb_failure_count = 0


def _cb_record_failure() -> None:
    global _cb_failure_count, _cb_open_until
    _cb_failure_count += 1
    if _cb_failure_count >= _CB_THRESHOLD:
        _cb_open_until = time.monotonic() + _CB_COOLDOWN
        log.error(
            "thais.circuit_breaker_open",
            failures=_cb_failure_count,
            cooldown_seconds=_CB_COOLDOWN,
        )


def _cb_is_open() -> bool:
    if _cb_failure_count < _CB_THRESHOLD:
        return False
    if time.monotonic() >= _cb_open_until:
        # Half-open: allow one retry
        return False
    return True


# ---------------------------------------------------------------------------
# Retry helper with exponential backoff
# ---------------------------------------------------------------------------

async def _api_request(
    method: str,
    url: str,
    *,
    params: dict | None = None,
    json_body: dict | None = None,
    timeout: float | None = None,
    _max_retries: int = 3,
) -> httpx.Response:
    """Execute an authenticated API request with retry logic.

    Handles:
    - Circuit breaker: skip if Thais has been failing repeatedly
    - 429 (rate-limited): exponential backoff — 1s, 2s, 4s
    - 401 (unauthorized): clear token, re-authenticate, retry once
    - Timeout: raise ThaisError with clear message
    """
    # Circuit breaker check
    if _cb_is_open():
        raise ThaisError("Thais PMS temporarily unavailable (circuit breaker open). Retry in a few minutes.")

    client = await _get_client()
    retries_on_429 = 0
    retried_on_401 = False

    while True:
        token = await _ensure_token()
        headers = _auth_headers(token)

        try:
            if method.upper() == "GET":
                resp = await client.get(
                    url, params=params, headers=headers,
                    timeout=timeout or 20.0,
                )
            elif method.upper() == "POST":
                resp = await client.post(
                    url, params=params, json=json_body, headers=headers,
                    timeout=timeout or 20.0,
                )
            else:
                raise ThaisError(f"Unsupported HTTP method: {method}")
        except httpx.TimeoutException as exc:
            _cb_record_failure()
            raise ThaisError(f"Thais API timed out ({method} {url}): {exc}") from exc

        # --- 429: exponential backoff ---
        if resp.status_code == 429:
            retries_on_429 += 1
            if retries_on_429 > _max_retries:
                raise ThaisError(
                    f"Thais rate-limited (429) after {_max_retries} retries: {method} {url}"
                )
            delay = 2 ** (retries_on_429 - 1)  # 1s, 2s, 4s
            log.warning("thais.rate_limited", url=url, retry=retries_on_429, delay=delay)
            await asyncio.sleep(delay)
            continue

        # --- 401: re-authenticate once ---
        if resp.status_code == 401 and not retried_on_401:
            retried_on_401 = True
            log.warning("thais.token_expired", url=url)
            _clear_token()
            continue

        # --- 5xx: server error — record failure ---
        if resp.status_code >= 500:
            _cb_record_failure()
            raise ThaisError(f"Thais server error ({resp.status_code}): {method} {url}")

        # Success — reset circuit breaker
        _cb_record_success()
        return resp


# ---------------------------------------------------------------------------
# Room types cache (10 minutes)
# ---------------------------------------------------------------------------

_room_types_cache: list[dict] | None = None
_room_types_cached_at: float = 0.0
_ROOM_TYPES_TTL: float = 600.0  # 10 minutes


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

async def check_availability(
    checkin: date,
    checkout: date,
    room_type_ids: list[str] | None = None,
) -> list[RoomAvailability]:
    """Check room availability and pricing from Thais PMS.

    Fetches both availability and nightly prices, then merges them
    into RoomAvailability objects with price data included.

    Returns one RoomAvailability per (room_type, rate) combination
    for the direct-booking rates (Best Flexible + Advance Purchase).
    """
    avail_url = f"{settings.thais_api_url}/hub/api/partner/hotel/apr/availabilities/currents"

    params: dict[str, str | list[str]] = {
        "from": checkin.isoformat(),
        "to": checkout.isoformat(),
    }
    if room_type_ids:
        params["room_type_id[]"] = room_type_ids

    # Fetch availability + prices + room type labels in parallel
    avail_resp, prices_raw, rt_map = await asyncio.gather(
        _api_request("GET", avail_url, params=params),
        get_prices(checkin, checkout, room_type_ids),
        _room_type_label_map(),
    )

    if avail_resp.status_code != 200:
        raise ThaisError(
            f"Thais availability failed ({avail_resp.status_code}): {avail_resp.text}"
        )
    data = avail_resp.json()

    items = data if isinstance(data, list) else data.get("data", data.get("availabilities", []))

    # Group availability entries by room_type_id
    by_rt: dict[int, list[dict]] = defaultdict(list)
    for item in items:
        rt_id = item.get("room_type_id")
        if rt_id is not None and rt_id not in _NON_ROOM_TYPE_IDS:
            by_rt[rt_id].append(item)

    # Index prices: (room_type_id, rate_id) → list[nightly price dicts]
    prices_by_key: dict[tuple[int, int], list[dict]] = defaultdict(list)
    for price_entry in prices_raw:
        rt_id = price_entry.get("room_type_id")
        rate_id = price_entry.get("rate_id")
        if rt_id is not None and rate_id in _DIRECT_RATE_IDS:
            prices_by_key[(rt_id, rate_id)].append(price_entry)

    num_nights = (checkout - checkin).days
    results: list[RoomAvailability] = []

    for rt_id, entries in by_rt.items():
        # Check if room type is available for ALL nights
        avail_counts = [e.get("availability", 0) for e in entries]
        min_avail = min(avail_counts) if avail_counts else 0
        has_all_nights = len(entries) >= num_nights
        is_available = min_avail > 0 and has_all_nights

        # Emit one result per direct-booking rate that has price data
        emitted_any = False
        for rate_id in sorted(_DIRECT_RATE_IDS):
            nightly_prices = prices_by_key.get((rt_id, rate_id), [])
            if nightly_prices:
                amounts = [
                    Decimal(str(p.get("price", 0)))
                    for p in nightly_prices
                    if p.get("price") is not None
                ]
                total = sum(amounts)
                avg_per_night = (total / len(amounts)) if amounts else None

                results.append(RoomAvailability(
                    room_type_id=str(rt_id),
                    room_type_name=rt_map.get(rt_id, f"Type {rt_id}"),
                    available=is_available,
                    rooms_left=min_avail if has_all_nights else 0,
                    price_per_night=avg_per_night,
                    total_price=total if amounts else None,
                    currency="EUR",
                    rate_name=_RATE_LABELS.get(rate_id, f"Rate {rate_id}"),
                    checkin=checkin,
                    checkout=checkout,
                ))
                emitted_any = True

        # Fallback: no price data for this room type, still report availability
        if not emitted_any:
            results.append(RoomAvailability(
                room_type_id=str(rt_id),
                room_type_name=rt_map.get(rt_id, f"Type {rt_id}"),
                available=is_available,
                rooms_left=min_avail if has_all_nights else 0,
                price_per_night=None,
                total_price=None,
                currency="EUR",
                rate_name=None,
                checkin=checkin,
                checkout=checkout,
            ))

    log.info(
        "thais.availability_checked",
        checkin=str(checkin),
        checkout=str(checkout),
        results=len(results),
    )
    return results


async def get_prices(
    checkin: date,
    checkout: date,
    room_type_ids: list[str] | None = None,
) -> list[dict]:
    """Fetch nightly prices from Thais /apr/prices/currents."""
    url = f"{settings.thais_api_url}/hub/api/partner/hotel/apr/prices/currents"
    params: dict[str, str | list[str]] = {
        "from": checkin.isoformat(),
        "to": checkout.isoformat(),
    }
    if room_type_ids:
        params["room_type_id[]"] = room_type_ids

    resp = await _api_request("GET", url, params=params)
    if resp.status_code != 200:
        raise ThaisError(f"Thais prices failed ({resp.status_code}): {resp.text}")
    data = resp.json()
    return data if isinstance(data, list) else data.get("data", [])


async def get_stay_pricing(
    checkin: date,
    checkout: date,
    room_type_id: int,
    rate_id: int,
    adults: int = 2,
) -> dict:
    """Fetch computed stay pricing from Thais /hotel/pricing.

    Returns total_price including breakfast and tourist tax.
    This is the authoritative price for a given stay configuration.
    """
    url = f"{settings.thais_api_url}/hub/api/partner/hotel/pricing"
    params: dict[str, str | int] = {
        "from": checkin.isoformat(),
        "to": checkout.isoformat(),
        "room_type_id": room_type_id,
        "rate_id": rate_id,
        "adults": adults,
    }

    resp = await _api_request("GET", url, params=params)
    if resp.status_code != 200:
        raise ThaisError(f"Thais pricing failed ({resp.status_code}): {resp.text}")
    data = resp.json()
    log.debug(
        "thais.stay_pricing",
        checkin=str(checkin),
        checkout=str(checkout),
        room_type_id=room_type_id,
        rate_id=rate_id,
    )
    return data


async def get_room_types() -> list[dict]:
    """Fetch room type definitions from Thais (cached for 10 minutes).

    Non-room types (Petit déjeuner, Fictive-Relogements) are filtered out.
    """
    global _room_types_cache, _room_types_cached_at

    # Return cache if still valid
    if _room_types_cache is not None and time.monotonic() < _room_types_cached_at + _ROOM_TYPES_TTL:
        return _room_types_cache

    url = f"{settings.thais_api_url}/hub/api/partner/hotel/room-types"
    resp = await _api_request("GET", url)
    if resp.status_code != 200:
        raise ThaisError(f"Thais room-types failed ({resp.status_code}): {resp.text}")
    data = resp.json()

    items = data if isinstance(data, list) else data.get("data", [])
    # Filter out non-room types
    items = [rt for rt in items if rt.get("id") not in _NON_ROOM_TYPE_IDS]

    _room_types_cache = items
    _room_types_cached_at = time.monotonic()
    log.debug("thais.room_types", count=len(items))
    return items


# Public-facing room type names — NEVER expose internal names (Marius, Marcelle, etc.)
_PUBLIC_ROOM_LABELS: dict[int, str] = {
    2: "Suite vue jardin avec grande terrasse (Garden View Suite)",
    7: "Suite Familiale — chambres communicantes (Family Suite)",
    10: "Suite Deluxe vue mer (Deluxe Sea View Suite)",
    13: "Chambre Privilège vue jardin (Privilege Room garden view)",
}


async def _room_type_label_map() -> dict[int, str]:
    """Helper: return {room_type_id: public label}. Never internal names."""
    # Always prefer hardcoded public labels over whatever Thais returns
    return dict(_PUBLIC_ROOM_LABELS)


async def search_customer(query: str) -> list[dict]:
    """Search customers in Thais PMS by name or email."""
    url = f"{settings.thais_api_url}/hub/api/partner/resort/customers"
    resp = await _api_request("GET", url, params={"q": query})
    # 404 = no results (some APIs return 404 instead of empty 200)
    if resp.status_code == 404:
        log.debug("thais.customer_search", query=query, results=0)
        return []
    if resp.status_code != 200:
        raise ThaisError(f"Thais customer search failed ({resp.status_code}): {resp.text}")
    data = resp.json()

    items = data if isinstance(data, list) else data.get("data", [])
    log.debug("thais.customer_search", query=query, results=len(items))
    return items


async def get_customer_reservations(query: str) -> list[dict]:
    """Search a customer by name/email and return their bookings from Thais.

    Uses customer_id filter on /hotel/bookings endpoint for efficiency
    (no full-scan of all bookings).

    Each booking contains:
      - reference (e.g. "LMH7414")
      - start_at / end_at (check-in / check-out dates)
      - customer { lastname, firstname, email }
      - booking_rooms[] -> each with:
          - room { label, room_type { label } }
          - rate { label }
          - nb_persons { adults, children, infants }  <- KEY for discrepancy detection
    """
    # Step 1: Find matching customers
    customers = await search_customer(query)
    if not customers:
        return []

    # Collect up to 5 customer IDs
    customer_ids = [
        cust["id"] for cust in customers[:5]
        if cust.get("id") is not None
    ]
    if not customer_ids:
        return []

    # Step 2: Fetch bookings per customer_id (filtered — NOT full scan)
    bookings_url = f"{settings.thais_api_url}/hub/api/partner/hotel/bookings"
    all_bookings: list[dict] = []

    # Fetch bookings for each customer in parallel
    async def _fetch_for_customer(cid: int) -> list[dict]:
        resp = await _api_request(
            "GET", bookings_url,
            params={"customer_id": str(cid)},
            timeout=30.0,
        )
        if resp.status_code != 200:
            log.warning("thais.bookings_fetch_failed", customer_id=cid, status=resp.status_code)
            return []
        data = resp.json()
        return data if isinstance(data, list) else data.get("data", [])

    per_customer = await asyncio.gather(
        *[_fetch_for_customer(cid) for cid in customer_ids]
    )
    for bookings_list in per_customer:
        all_bookings.extend(bookings_list)

    # Deduplicate by booking reference (a customer might appear in multiple search results)
    seen_refs: set[str] = set()
    results: list[dict] = []

    for booking in all_bookings:
        ref = booking.get("reference", "")
        if ref in seen_refs:
            continue
        seen_refs.add(ref)

        # Extract key info for the AI in a clean format
        summary: dict = {
            "reference": ref,
            "check_in": booking.get("start_at"),
            "check_out": booking.get("end_at"),
            "canceled": booking.get("canceled", False),
            "source": booking.get("source"),
            "total_incl_taxes": booking.get("total_incl_taxes"),
        }

        # Customer info
        cust = booking.get("customer", {})
        summary["customer"] = {
            "lastname": cust.get("lastname", ""),
            "firstname": cust.get("firstname", ""),
            "email": cust.get("email", ""),
        }

        # Room details with nb_persons (adults/children/infants)
        # IMPORTANT: sanitize room labels — never expose internal names (Marius, etc.)
        rooms: list[dict] = []
        for br in booking.get("booking_rooms", []):
            room = br.get("room", {})
            room_type = room.get("room_type", {})
            rate = br.get("rate", {})
            nb = br.get("nb_persons", {})

            # Map room_type_id to public label if possible
            rt_id = room_type.get("id")
            public_type = _PUBLIC_ROOM_LABELS.get(rt_id, room_type.get("label", ""))

            rooms.append({
                "room_type": public_type,
                "rate": rate.get("label", ""),
                "adults": nb.get("adults", 0),
                "children": nb.get("children", 0),
                "infants": nb.get("infants", 0),
            })
        summary["rooms"] = rooms
        results.append(summary)

    log.info("thais.reservations_found", query=query, count=len(results))
    return results


async def get_hotel_config() -> dict:
    """Fetch hotel configuration (room types, rates, etc.)."""
    url = f"{settings.thais_api_url}/hub/api/partner/config"
    resp = await _api_request("GET", url, params={"lang": "fr"})
    if resp.status_code != 200:
        raise ThaisError(f"Thais config failed ({resp.status_code}): {resp.text}")
    return resp.json()
