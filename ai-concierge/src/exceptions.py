"""Custom exception hierarchy."""

from __future__ import annotations


class ConciergeError(Exception):
    """Base exception for the AI Concierge system."""


class OutlookError(ConciergeError):
    """Microsoft Graph / Outlook API error."""


class ThaisError(ConciergeError):
    """Thais PMS API error."""


class AIError(ConciergeError):
    """Claude AI generation error."""


class EscalationRequired(ConciergeError):
    """Raised when the email must be escalated to a human."""

    def __init__(self, reason: str, details: str = ""):
        self.reason = reason
        self.details = details
        super().__init__(f"Escalation required: {reason} — {details}")


class SupabaseError(ConciergeError):
    """Supabase data layer error."""
