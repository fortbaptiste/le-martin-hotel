"""Message and email models."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel

from .enums import ConversationCategory, MessageDirection


class Message(BaseModel):
    id: str
    conversation_id: str
    outlook_message_id: str | None = None
    direction: MessageDirection
    from_email: str
    to_email: str
    subject: str | None = None
    body_text: str | None = None
    body_html: str | None = None
    ai_draft: str | None = None
    final_text: str | None = None
    was_edited: bool = False
    confidence_score: float | None = None
    tokens_input: int = 0
    tokens_output: int = 0
    cost_eur: float = 0.0
    response_time_ms: int | None = None
    detected_language: str | None = None
    category: ConversationCategory | None = None
    sent_at: datetime | None = None
    created_at: datetime | None = None


class InboundEmail(BaseModel):
    """Raw email received from Outlook."""
    outlook_message_id: str
    outlook_thread_id: str | None = None
    outlook_conversation_id: str | None = None
    from_email: str
    from_name: str | None = None
    to_email: str
    subject: str | None = None
    body_text: str = ""
    body_html: str = ""
    received_at: datetime | None = None


class AIResponse(BaseModel):
    """Structured output from the AI engine."""
    response_text: str
    confidence_score: float
    detected_language: str = "en"
    category: ConversationCategory = ConversationCategory.OTHER
    tokens_input: int = 0
    tokens_output: int = 0
    tools_used: list[str] = []
    response_time_ms: int = 0
