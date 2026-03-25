"""AI-related models — rules, confidence, escalation."""

from __future__ import annotations

from pydantic import BaseModel

from .enums import EscalationReason, RuleType


class AIRule(BaseModel):
    id: str
    rule_name: str
    rule: RuleType
    condition_text: str
    action_text: str
    priority: int = 50
    is_active: bool = True


class ConfidenceBreakdown(BaseModel):
    retrieval_relevance: float = 0.0
    context_completeness: float = 0.0
    llm_self_assessment: float = 0.0
    rule_compliance: float = 0.0
    template_match: float = 0.0

    @property
    def weighted_score(self) -> float:
        return (
            self.retrieval_relevance * 0.25
            + self.context_completeness * 0.20
            + self.llm_self_assessment * 0.15
            + self.rule_compliance * 0.25
            + self.template_match * 0.15
        )


class Escalation(BaseModel):
    conversation_id: str
    message_id: str | None = None
    reason: EscalationReason
    confidence_score: float | None = None
    details: str = ""
