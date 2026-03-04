"""Enums mirroring the Supabase database types."""

from __future__ import annotations

from enum import StrEnum


class ConversationStatus(StrEnum):
    ACTIVE = "active"
    CLOSED = "closed"
    ESCALATED = "escalated"


class ConversationCategory(StrEnum):
    AVAILABILITY = "availability"
    PRICING = "pricing"
    BOOKING = "booking"
    BOOKING_MODIFICATION = "booking_modification"
    CANCELLATION = "cancellation"
    INFO_REQUEST = "info_request"
    RESTAURANT = "restaurant"
    ACTIVITY = "activity"
    TRANSFER = "transfer"
    COMPLAINT = "complaint"
    COMPLIMENT = "compliment"
    HONEYMOON = "honeymoon"
    FAMILY = "family"
    OTHER = "other"


class MessageDirection(StrEnum):
    INBOUND = "inbound"
    OUTBOUND = "outbound"


class ReservationStatus(StrEnum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    CANCELLED = "cancelled"
    COMPLETED = "completed"
    NO_SHOW = "no_show"


class RateType(StrEnum):
    ADVANCE_PURCHASE = "advance_purchase"
    FLEXIBLE = "flexible"
    HONEYMOON = "honeymoon"
    NON_REFUNDABLE = "non_refundable"
    OTHER = "other"


class EscalationReason(StrEnum):
    LOW_CONFIDENCE = "low_confidence"
    COMPLAINT = "complaint"
    REFUND_REQUEST = "refund_request"
    BOOKING_MODIFICATION = "booking_modification"
    GROUP_REQUEST = "group_request"
    PRIVATIZATION = "privatization"
    PAYMENT_ISSUE = "payment_issue"
    OUT_OF_SCOPE = "out_of_scope"
    UNKNOWN_QUESTION = "unknown_question"
    PHYSICAL_ACTION_REQUIRED = "physical_action_required"
    OTHER = "other"


class CorrectionType(StrEnum):
    TONE = "tone"
    FACTUAL = "factual"
    MISSING_INFO = "missing_info"
    WRONG_INFO = "wrong_info"
    GRAMMAR = "grammar"
    POLICY = "policy"
    OTHER = "other"


class RuleType(StrEnum):
    RESPONSE = "response"
    ESCALATION = "escalation"
    TONE = "tone"
    AVAILABILITY = "availability"
    PRICING = "pricing"
    ROUTING = "routing"
    GREETING = "greeting"
    SIGNATURE = "signature"


class AppMode(StrEnum):
    DRAFT = "draft"
    AUTO = "auto"


class RoomCategory(StrEnum):
    PRESTIGE = "prestige"
    DELUXE = "deluxe"
    FAMILY_SUITE = "family_suite"


class ServiceCategory(StrEnum):
    WELLNESS = "wellness"
    TRANSPORT = "transport"
    DINING = "dining"
    ACTIVITY = "activity"
    ROOM_EXTRA = "room_extra"
    CONCIERGE = "concierge"
    EVENT = "event"


class BeachSide(StrEnum):
    FRENCH = "french"
    DUTCH = "dutch"


class ActivityCategory(StrEnum):
    WATER_SPORT = "water_sport"
    BOAT_TRIP = "boat_trip"
    ISLAND_TRIP = "island_trip"
    LAND_ACTIVITY = "land_activity"
    WELLNESS = "wellness"
    SHOPPING = "shopping"
    NIGHTLIFE = "nightlife"
    CULTURAL = "cultural"
    FAMILY = "family"


class PriceRange(StrEnum):
    LOW = "€"
    MEDIUM = "€€"
    HIGH = "€€€"
    LUXURY = "€€€€"
