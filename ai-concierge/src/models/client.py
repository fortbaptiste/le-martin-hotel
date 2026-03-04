"""Client models."""

from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


class Client(BaseModel):
    id: str
    email: str
    first_name: str | None = None
    last_name: str | None = None
    phone: str | None = None
    language: str = "en"
    nationality: str | None = None
    vip_score: int = 0
    total_stays: int = 0
    preferences: dict[str, Any] = Field(default_factory=dict)
    notes: str | None = None
    first_contact_at: datetime | None = None
    last_contact_at: datetime | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None


class ClientCreate(BaseModel):
    email: str
    first_name: str | None = None
    last_name: str | None = None
    phone: str | None = None
    language: str = "en"
    nationality: str | None = None
    preferences: dict[str, Any] = Field(default_factory=dict)
    notes: str | None = None
