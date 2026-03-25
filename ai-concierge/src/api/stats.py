"""Stats / monitoring endpoint — last 24 h aggregates."""

from __future__ import annotations

from collections import Counter
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter

from src.services.supabase_client import get_client

router = APIRouter(tags=["stats"])


def _cutoff_iso() -> str:
    """Return ISO-8601 timestamp for 24 hours ago (UTC)."""
    return (datetime.now(timezone.utc) - timedelta(hours=24)).isoformat()


@router.get("/api/stats")
async def get_stats():
    """Aggregate email-processing metrics for the last 24 hours."""

    cutoff = _cutoff_iso()
    sb = get_client()

    # ------------------------------------------------------------------
    # 1. Messages — inbound + outbound in the last 24 h
    # ------------------------------------------------------------------
    msg_resp = (
        sb.table("messages")
        .select("direction,confidence_score,tokens_input,tokens_output,"
                "response_time_ms,category")
        .gte("created_at", cutoff)
        .execute()
    )
    messages = msg_resp.data or []

    inbound = [m for m in messages if m.get("direction") == "inbound"]
    outbound = [m for m in messages if m.get("direction") == "outbound"]

    emails_processed = len(inbound)

    # ------------------------------------------------------------------
    # 2. Escalations in the last 24 h
    # ------------------------------------------------------------------
    esc_resp = (
        sb.table("escalations")
        .select("id", count="exact")
        .gte("created_at", cutoff)
        .execute()
    )
    emails_escalated = esc_resp.count or 0

    emails_auto_responded = max(len(outbound) - emails_escalated, 0)

    escalation_rate = round(emails_escalated / emails_processed, 2) if emails_processed else 0.0

    # ------------------------------------------------------------------
    # 3. Confidence scores (from outbound messages)
    # ------------------------------------------------------------------
    scores = [
        m["confidence_score"]
        for m in outbound
        if m.get("confidence_score") is not None
    ]
    avg_confidence = round(sum(scores) / len(scores), 2) if scores else None

    # ------------------------------------------------------------------
    # 4. Response time (from outbound messages)
    # ------------------------------------------------------------------
    times = [
        m["response_time_ms"]
        for m in outbound
        if m.get("response_time_ms") is not None
    ]
    avg_response_time_ms = int(sum(times) / len(times)) if times else None

    # ------------------------------------------------------------------
    # 5. Token usage (from outbound messages)
    # ------------------------------------------------------------------
    tok_in = [m.get("tokens_input", 0) or 0 for m in outbound]
    tok_out = [m.get("tokens_output", 0) or 0 for m in outbound]

    avg_tokens: dict | None = None
    if outbound:
        avg_tokens = {
            "input": int(sum(tok_in) / len(tok_in)),
            "output": int(sum(tok_out) / len(tok_out)),
        }

    # ------------------------------------------------------------------
    # 6. Top categories (from inbound messages)
    # ------------------------------------------------------------------
    cats = [m["category"] for m in inbound if m.get("category")]
    top_categories = dict(Counter(cats).most_common(5))

    # ------------------------------------------------------------------
    # 7. Errors — conversations that ended up with status 'escalated'
    #    minus intentional escalations ≈ processing errors.
    #    We approximate errors as 0 since we don't have an explicit
    #    error log table; in practice, check application logs.
    # ------------------------------------------------------------------
    # A rough proxy: outbound messages with confidence_score = None
    # (i.e. the pipeline never scored them) could signal errors.
    errors = sum(
        1 for m in outbound
        if m.get("confidence_score") is None and m.get("response_time_ms") is None
    )

    return {
        "period": "last_24h",
        "emails_processed": emails_processed,
        "emails_escalated": emails_escalated,
        "emails_auto_responded": emails_auto_responded,
        "escalation_rate": escalation_rate,
        "avg_confidence": avg_confidence,
        "avg_response_time_ms": avg_response_time_ms,
        "avg_tokens_per_email": avg_tokens,
        "top_categories": top_categories,
        "errors": errors,
    }
