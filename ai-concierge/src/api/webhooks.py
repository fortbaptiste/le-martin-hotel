"""Outlook webhook endpoint — receives push notifications from Microsoft Graph."""

from __future__ import annotations

import hmac
import time
from collections import deque

import structlog
from fastapi import APIRouter, Request, Response

from src.config import settings
from src.services import outlook
from src.services.email_processor import process_email

log = structlog.get_logger()

router = APIRouter(tags=["webhooks"])

# ---------------------------------------------------------------------------
# Simple in-memory rate limiter: max N calls per 60-second window
# ---------------------------------------------------------------------------
_RATE_LIMIT = 30            # max webhook calls per minute
_RATE_WINDOW = 60           # seconds
_call_timestamps: deque[float] = deque()


def _is_rate_limited() -> bool:
    """Return True if the webhook rate limit has been exceeded."""
    now = time.monotonic()
    # Purge timestamps older than the window
    while _call_timestamps and _call_timestamps[0] < now - _RATE_WINDOW:
        _call_timestamps.popleft()
    if len(_call_timestamps) >= _RATE_LIMIT:
        return True
    _call_timestamps.append(now)
    return False


def _verify_client_state(notification: dict) -> bool:
    """
    Verify the clientState in a webhook notification.
    Returns True if verification passes (or if no secret is configured).
    Uses constant-time comparison to prevent timing attacks.
    """
    expected = settings.webhook_client_state
    if not expected:
        # No client state configured — skip verification
        return True
    actual = notification.get("clientState", "")
    return hmac.compare_digest(expected, actual)


@router.post("/webhooks/outlook")
async def outlook_webhook(request: Request):
    """
    Handle Microsoft Graph webhook notifications.

    Microsoft sends a validation request first (with validationToken query param),
    then POST notifications when new emails arrive.
    """
    # Validation handshake — Graph sends ?validationToken=xxx on subscription creation
    validation_token = request.query_params.get("validationToken")
    if validation_token:
        log.info("webhook.validation", token=validation_token[:20])
        return Response(content=validation_token, media_type="text/plain")

    # Rate limiting
    if _is_rate_limited():
        log.warning("webhook.rate_limited", limit=_RATE_LIMIT, window=_RATE_WINDOW)
        return Response(
            content='{"error": "rate limit exceeded"}',
            status_code=429,
            media_type="application/json",
        )

    # Parse notification body
    try:
        body = await request.json()
    except Exception:
        log.warning("webhook.invalid_body")
        return Response(
            content='{"error": "invalid request body"}',
            status_code=400,
            media_type="application/json",
        )

    notifications = body.get("value", [])
    log.info("webhook.received", count=len(notifications))

    for notification in notifications:
        # Verify clientState if configured
        if not _verify_client_state(notification):
            log.warning("webhook.invalid_client_state", resource=notification.get("resource", ""))
            return Response(
                content='{"error": "invalid clientState"}',
                status_code=403,
                media_type="application/json",
            )

        resource = notification.get("resource", "")
        change_type = notification.get("changeType", "")

        if change_type == "created" and "messages" in resource:
            # New email received — fetch and process
            try:
                emails = await outlook.fetch_unread_emails(limit=1)
                for email in emails:
                    await process_email(email)
            except Exception as exc:
                log.error("webhook.process_error", error=str(exc))

    return {"status": "ok"}
