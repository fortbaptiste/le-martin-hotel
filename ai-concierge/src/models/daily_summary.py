"""Daily summary model."""

from __future__ import annotations

from datetime import date, datetime

from pydantic import BaseModel


class DailySummary(BaseModel):
    id: str | None = None
    date: date
    emails_received: int = 0
    emails_replied: int = 0
    emails_escalated: int = 0
    avg_response_time_ms: int | None = None
    avg_confidence_score: float | None = None
    total_tokens_used: int = 0
    total_cost_eur: float = 0.0
    summary_text: str | None = None
    sent_to_owner: bool = False
    created_at: datetime | None = None
