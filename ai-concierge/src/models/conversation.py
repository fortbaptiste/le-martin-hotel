"""Conversation models."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel

from .enums import ConversationCategory, ConversationStatus


class Conversation(BaseModel):
    id: str
    client_id: str
    outlook_thread_id: str | None = None
    outlook_conversation_id: str | None = None
    subject: str | None = None
    status: ConversationStatus = ConversationStatus.ACTIVE
    category: ConversationCategory = ConversationCategory.OTHER
    assignee: str = "bot"
    message_count: int = 0
    last_message_at: datetime | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None


class ConversationCreate(BaseModel):
    client_id: str
    outlook_thread_id: str | None = None
    outlook_conversation_id: str | None = None
    subject: str | None = None
    category: ConversationCategory = ConversationCategory.OTHER
