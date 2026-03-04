"""Reservation models."""

from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel

from .enums import RateType, ReservationStatus


class Reservation(BaseModel):
    id: str
    client_id: str | None = None
    conversation_id: str | None = None
    thais_reservation_id: str | None = None
    room_slug: str | None = None
    checkin_date: date
    checkout_date: date
    nights: int | None = None
    guests_adults: int = 1
    guests_children: int = 0
    total_price: Decimal | None = None
    currency: str = "EUR"
    rate: RateType = RateType.FLEXIBLE
    status: ReservationStatus = ReservationStatus.PENDING
    special_requests: str | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None


class RoomAvailability(BaseModel):
    """Availability result from Thais PMS."""
    room_type_id: str
    room_type_name: str
    available: bool
    price_per_night: Decimal | None = None
    total_price: Decimal | None = None
    currency: str = "EUR"
    rate_name: str | None = None
    checkin: date
    checkout: date
