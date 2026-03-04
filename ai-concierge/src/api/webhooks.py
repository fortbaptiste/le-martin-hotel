"""Outlook webhook endpoint — receives push notifications from Microsoft Graph."""

from __future__ import annotations

import structlog
from fastapi import APIRouter, Request, Response

from src.services import outlook
from src.services.email_processor import process_email

log = structlog.get_logger()

router = APIRouter(tags=["webhooks"])


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

    # Process notification
    try:
        body = await request.json()
    except Exception:
        log.warning("webhook.invalid_body")
        return {"status": "invalid_body"}

    notifications = body.get("value", [])
    log.info("webhook.received", count=len(notifications))

    for notification in notifications:
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
