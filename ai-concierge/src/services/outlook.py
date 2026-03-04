"""Microsoft Graph API — Outlook email operations (OAuth2 client-credentials via MSAL)."""

from __future__ import annotations

import structlog
import httpx
import msal

from src.config import settings
from src.exceptions import OutlookError
from src.models.message import InboundEmail

log = structlog.get_logger()

# ---------------------------------------------------------------------------
# MSAL confidential-client — acquires tokens for daemon/service flow
# ---------------------------------------------------------------------------

_msal_app: msal.ConfidentialClientApplication | None = None


def _get_msal_app() -> msal.ConfidentialClientApplication:
    global _msal_app
    if _msal_app is None:
        _msal_app = msal.ConfidentialClientApplication(
            client_id=settings.azure_client_id,
            client_credential=settings.azure_client_secret,
            authority=settings.azure_authority,
        )
    return _msal_app


async def _get_token() -> str:
    app = _get_msal_app()
    scopes = [settings.azure_scopes]
    result = app.acquire_token_silent(scopes, account=None)
    if not result:
        result = app.acquire_token_for_client(scopes=scopes)
    if "access_token" not in result:
        raise OutlookError(f"MSAL token acquisition failed: {result.get('error_description', result)}")
    return result["access_token"]


def _headers(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}


def _user_url() -> str:
    return f"{settings.graph_api_base_url}/users/{settings.email_address}"


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

async def fetch_unread_emails(limit: int = 10) -> list[InboundEmail]:
    """Fetch unread emails from the monitored mailbox."""
    token = await _get_token()
    url = (
        f"{_user_url()}/mailFolders/inbox/messages"
        f"?$filter=isRead eq false"
        f"&$top={limit}"
        f"&$orderby=receivedDateTime asc"
        f"&$select=id,conversationId,conversationIndex,from,toRecipients,"
        f"subject,body,bodyPreview,receivedDateTime,internetMessageHeaders"
    )
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.get(url, headers=_headers(token))
        if resp.status_code != 200:
            raise OutlookError(f"Fetch emails failed ({resp.status_code}): {resp.text}")
        data = resp.json()

    emails: list[InboundEmail] = []
    for msg in data.get("value", []):
        from_addr = msg.get("from", {}).get("emailAddress", {})
        to_addrs = msg.get("toRecipients", [])
        to_email = to_addrs[0]["emailAddress"]["address"] if to_addrs else settings.email_address

        # Extract thread ID from internet headers if available
        thread_id = None
        for header in msg.get("internetMessageHeaders", []):
            if header.get("name", "").lower() == "thread-index":
                thread_id = header["value"]
                break

        body = msg.get("body", {})
        emails.append(InboundEmail(
            outlook_message_id=msg["id"],
            outlook_thread_id=thread_id,
            outlook_conversation_id=msg.get("conversationId"),
            from_email=from_addr.get("address", ""),
            from_name=from_addr.get("name"),
            to_email=to_email,
            subject=msg.get("subject", ""),
            body_text=msg.get("bodyPreview", ""),
            body_html=body.get("content", "") if body.get("contentType") == "html" else "",
            received_at=msg.get("receivedDateTime"),
        ))
    log.info("outlook.fetched", count=len(emails))
    return emails


async def mark_as_read(message_id: str) -> None:
    """Mark a specific message as read."""
    token = await _get_token()
    url = f"{_user_url()}/messages/{message_id}"
    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.patch(url, headers=_headers(token), json={"isRead": True})
        if resp.status_code not in (200, 204):
            raise OutlookError(f"Mark read failed ({resp.status_code}): {resp.text}")
    log.debug("outlook.marked_read", message_id=message_id)


async def send_reply(message_id: str, body_html: str) -> None:
    """Reply to a message (auto mode)."""
    token = await _get_token()
    url = f"{_user_url()}/messages/{message_id}/reply"
    payload = {"message": {"body": {"contentType": "html", "content": body_html}}}
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(url, headers=_headers(token), json=payload)
        if resp.status_code not in (200, 202):
            raise OutlookError(f"Send reply failed ({resp.status_code}): {resp.text}")
    log.info("outlook.reply_sent", message_id=message_id)


async def create_draft_reply(message_id: str, body_html: str) -> str:
    """Create a draft reply (draft mode — human reviews before sending)."""
    token = await _get_token()
    url = f"{_user_url()}/messages/{message_id}/createReply"
    async with httpx.AsyncClient(timeout=30) as client:
        # Step 1: create the reply skeleton
        resp = await client.post(url, headers=_headers(token), json={})
        if resp.status_code not in (200, 201):
            raise OutlookError(f"Create reply failed ({resp.status_code}): {resp.text}")
        draft = resp.json()
        draft_id = draft["id"]

        # Step 2: update the draft body
        patch_url = f"{_user_url()}/messages/{draft_id}"
        resp2 = await client.patch(
            patch_url,
            headers=_headers(token),
            json={"body": {"contentType": "html", "content": body_html}},
        )
        if resp2.status_code != 200:
            raise OutlookError(f"Update draft failed ({resp2.status_code}): {resp2.text}")

    log.info("outlook.draft_created", draft_id=draft_id, original_id=message_id)
    return draft_id


async def send_email(to: str, subject: str, body_html: str) -> None:
    """Send a standalone email (for escalation notifications, daily summaries)."""
    token = await _get_token()
    url = f"{_user_url()}/sendMail"
    payload = {
        "message": {
            "subject": subject,
            "body": {"contentType": "html", "content": body_html},
            "toRecipients": [{"emailAddress": {"address": to}}],
        },
        "saveToSentItems": True,
    }
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(url, headers=_headers(token), json=payload)
        if resp.status_code not in (200, 202):
            raise OutlookError(f"Send email failed ({resp.status_code}): {resp.text}")
    log.info("outlook.email_sent", to=to, subject=subject)
