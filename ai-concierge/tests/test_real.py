"""
Test du vrai pipeline avec des conversations reelles multi-messages d'Outlook.
- Lit les vrais emails (inbox + sentItems) depuis Outlook (GET seulement)
- Groupe par conversationId pour reconstituer les threads complets
- Rejoue chaque conversation en ordre chronologique avec historique
- Mock Outlook (pas de brouillon, pas d'envoi, pas de mark-as-read)
- Mock les ecritures Supabase (pas de pollution en base prod)
- Les lectures Supabase marchent (regles, chambres, restos, etc.)
- L'IA tourne pour de vrai avec Claude Sonnet 4.6

Usage:
  python -m tests.test_real              # toutes les conversations
  python -m tests.test_real --limit 5    # les 5 premieres conversations
  python -m tests.test_real --single     # mode email individuel (pas de threads)
"""

import asyncio
import os
import re
import sys
from collections import defaultdict
from unittest.mock import AsyncMock, patch

# Fix Windows console encoding
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


# -- Outlook fetch helpers ---------------------------------------------------

_SKIP_DOMAINS = {
    "assistance97.fr", "app.thebookingbutton.com", "lemartinhotel.com",
    "ecsolutions.fr", "app.siteminder.com", "tehamestudio.com",
    "payline.com", "insee.fr", "mrandmrssmith.com", "smithhotels.com",
}
_SKIP_EMAILS = {
    "instant.floral@yahoo.com", "slinet@assistance97.fr",
    "facturation@assistance97.fr", "donotreply@app.thebookingbutton.com",
}


async def _fetch_folder(folder: str, limit: int, token: str) -> list[dict]:
    from src.services.outlook import _headers, _user_url
    import httpx
    url = (
        f"{_user_url()}/mailFolders/{folder}/messages"
        f"?$top={limit}&$orderby=receivedDateTime desc"
        f"&$select=id,conversationId,conversationIndex,from,toRecipients,"
        f"subject,body,bodyPreview,receivedDateTime,internetMessageHeaders"
    )
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.get(url, headers=_headers(token))
        if resp.status_code != 200:
            print(f"ERREUR Outlook ({folder}): {resp.status_code}")
            return []
        return resp.json().get("value", [])


def _parse_msg(msg: dict, direction: str) -> dict:
    fa = msg.get("from", {}).get("emailAddress", {})
    to = msg.get("toRecipients", [])
    body = msg.get("body", {})
    tid = None
    for h in msg.get("internetMessageHeaders", []):
        if h.get("name", "").lower() == "thread-index":
            tid = h["value"]
            break
    return {
        "outlook_message_id": msg["id"],
        "outlook_thread_id": tid,
        "outlook_conversation_id": msg.get("conversationId"),
        "from_email": fa.get("address", "").lower(),
        "from_name": fa.get("name", ""),
        "to_email": to[0]["emailAddress"]["address"] if to else "info@lemartinhotel.com",
        "subject": msg.get("subject", ""),
        "body_text": msg.get("bodyPreview", ""),
        "body_html": body.get("content", "") if body.get("contentType") == "html" else "",
        "received_at": msg.get("receivedDateTime"),
        "direction": direction,
    }


def _is_guest(sender: str) -> bool:
    domain = sender.split("@")[-1] if "@" in sender else ""
    if sender in _SKIP_EMAILS or domain in _SKIP_DOMAINS:
        return False
    if "noreply" in sender or "donotreply" in sender:
        return False
    if sender.endswith("@lemartinhotel.com"):
        return False
    return True


def _preview(raw: dict) -> str:
    from bs4 import BeautifulSoup
    if raw.get("body_html"):
        soup = BeautifulSoup(raw["body_html"], "html.parser")
        for t in soup(["script", "style", "head"]):
            t.decompose()
        for t in soup.select("div#appendonsend, div.gmail_quote, blockquote"):
            t.decompose()
        txt = soup.get_text(separator=" ", strip=True)
    else:
        txt = raw.get("body_text", "")
    return re.sub(r"\s+", " ", txt)[:300]


async def fetch_conversations(max_msgs: int = 100) -> dict[str, list[dict]]:
    from src.services.outlook import _get_token
    token = await _get_token()
    inbox_raw, sent_raw = await asyncio.gather(
        _fetch_folder("inbox", max_msgs, token),
        _fetch_folder("sentItems", max_msgs, token),
    )
    convs: dict[str, list[dict]] = defaultdict(list)
    for msg in inbox_raw:
        p = _parse_msg(msg, "inbound")
        if _is_guest(p["from_email"]) and p.get("outlook_conversation_id"):
            convs[p["outlook_conversation_id"]].append(p)
    for msg in sent_raw:
        p = _parse_msg(msg, "outbound")
        cid = p.get("outlook_conversation_id")
        if cid and cid in convs:
            convs[cid].append(p)
    for cid in convs:
        convs[cid].sort(key=lambda m: m.get("received_at", ""))
    return dict(convs)


# -- Process one inbound email through the pipeline -------------------------

async def _process_one(raw: dict, mock_create_msg, results: list, conv_id: str,
                       msg_idx: int, thread_size: int):
    """Process a single inbound email. Returns AI draft text or None."""
    from src.models.message import InboundEmail
    from src.services.email_processor import process_email
    from src.tools.handlers import clear_session_state

    clear_session_state()
    email = InboundEmail(
        outlook_message_id=raw["outlook_message_id"],
        outlook_thread_id=raw.get("outlook_thread_id"),
        outlook_conversation_id=raw.get("outlook_conversation_id"),
        from_email=raw["from_email"],
        from_name=raw.get("from_name"),
        to_email=raw["to_email"],
        subject=raw.get("subject", ""),
        body_text=raw.get("body_text", ""),
        body_html=raw.get("body_html", ""),
        received_at=raw.get("received_at"),
    )

    try:
        result = await process_email(email)
        status = result.get("status", "?")
        _print_result(status, result, mock_create_msg, raw, results, conv_id, msg_idx, thread_size)
        if status == "processed":
            return _get_ai_draft(mock_create_msg)
    except Exception as exc:
        print(f"  >> ERREUR PIPELINE: {exc}")
        import traceback
        traceback.print_exc()
        results.append({"conv_id": conv_id, "from": raw["from_email"],
                         "status": "crash", "error": str(exc)})
    return None


def _get_ai_draft(mock_create_msg) -> str:
    if mock_create_msg.call_count > 0:
        last = mock_create_msg.call_args_list[-1]
        data = last[0][0] if last[0] else last[1].get("data", {})
        return data.get("ai_draft") or data.get("final_text", "")
    return ""


def _print_result(status, result, mock_create_msg, raw, results, conv_id, msg_idx, thread_size):
    if status == "skipped":
        print(f"  >> SKIP (filtre automatique)")
        results.append({"conv_id": conv_id, "from": raw["from_email"], "status": status})
    elif status == "escalated":
        print(f"  >> ESCALADE: {result.get('reason', '?')}")
        results.append({"conv_id": conv_id, "from": raw["from_email"],
                         "status": status, "reason": result.get("reason")})
    elif status == "error":
        print(f"  >> ERREUR: {result.get('error', '?')}")
        results.append({"conv_id": conv_id, "from": raw["from_email"],
                         "status": status, "error": result.get("error")})
    elif status == "processed":
        ai_draft = _get_ai_draft(mock_create_msg)
        if ai_draft:
            _print_ai_response(ai_draft, mock_create_msg, result, raw, results,
                               conv_id, msg_idx, thread_size)
        else:
            print(f"  >> Pas de reponse IA (status: {status})")
            results.append({"conv_id": conv_id, "from": raw["from_email"], "status": status})
    else:
        results.append({"conv_id": conv_id, "from": raw["from_email"], "status": status})


def _print_ai_response(ai_draft, mock_create_msg, result, raw, results,
                        conv_id, msg_idx, thread_size):
    last = mock_create_msg.call_args_list[-1]
    data = last[0][0] if last[0] else last[1].get("data", {})
    confidence = data.get("confidence_score", "?")
    category = data.get("category", "?")
    tokens_in = data.get("tokens_input", 0)
    tokens_out = data.get("tokens_output", 0)
    word_count = len(ai_draft.split())

    print(f"\n  REPONSE IA ({word_count} mots, confiance: {confidence}, cat: {category}):")
    print(f"  {'-'*60}")
    for line in ai_draft.split("\n"):
        print(f"  {line}")
    print(f"  {'-'*60}")
    print(f"  Tokens: {tokens_in} in / {tokens_out} out")

    tools = result.get("tools_used", [])
    if tools:
        print(f"  Outils: {', '.join(tools)}")

    results.append({
        "conv_id": conv_id, "from": raw["from_email"],
        "subject": raw.get("subject", ""), "status": "processed",
        "word_count": word_count, "confidence": confidence,
        "category": category, "tokens_in": tokens_in, "tokens_out": tokens_out,
        "msg_in_thread": msg_idx, "thread_size": thread_size,
    })


# -- Build mock context manager ----------------------------------------------

def _build_mocks():
    """Create all mocks and return (patches_list, mock_create_msg, mock_get_conv_msgs_fn)."""
    mock_draft = AsyncMock(return_value="MOCK_DRAFT_ID_001")
    mock_mark = AsyncMock()
    mock_send = AsyncMock()

    conv_counter = [0]

    def make_client(data):
        return {
            "id": f"test-client-{conv_counter[0]}", "email": data.get("email", ""),
            "first_name": data.get("first_name", ""), "last_name": data.get("last_name", ""),
            "language": data.get("language", "en"), "vip_score": 0, "total_stays": 0,
            "preferences": {}, "notes": None,
        }

    def make_conv(data):
        conv_counter[0] += 1
        return {
            "id": f"test-conv-{conv_counter[0]}", "client_id": f"test-client-{conv_counter[0]}",
            "subject": data.get("subject", ""), "status": "active",
        }

    mock_create_msg = AsyncMock(return_value={"id": "test-msg-id"})

    patches = [
        patch("src.services.email_processor.outlook.create_draft_reply", mock_draft),
        patch("src.services.email_processor.outlook.mark_as_read", mock_mark),
        patch("src.services.email_processor.outlook.send_email", mock_send),
        patch("src.services.email_processor.db.get_client_by_email", AsyncMock(return_value=None)),
        patch("src.services.email_processor.db.create_client_record", AsyncMock(side_effect=make_client)),
        patch("src.services.email_processor.db.update_client", AsyncMock(return_value={})),
        patch("src.services.email_processor.db.get_conversation_by_thread", AsyncMock(return_value=None)),
        patch("src.services.email_processor.db.create_conversation", AsyncMock(side_effect=make_conv)),
        patch("src.services.email_processor.db.update_conversation", AsyncMock(return_value={})),
        patch("src.services.email_processor.db.create_message", mock_create_msg),
        patch("src.services.email_processor.db.update_message", AsyncMock(return_value={})),
        patch("src.services.email_processor.db.create_escalation", AsyncMock(return_value={})),
        patch("src.services.email_processor.is_already_processed", AsyncMock(return_value=False)),
        patch("src.services.email_processor._save_processed_id", AsyncMock()),
        patch("src.services.email_processor.notify_team_action", AsyncMock()),
        patch("src.services.email_processor.notify_escalation", AsyncMock()),
    ]
    return patches, mock_create_msg


# -- Conversation test -------------------------------------------------------

async def run_conversation_test(limit: int = 10):
    print(f"\n{'#'*70}")
    print(f"  TEST CONVERSATIONS REELLES - Pipeline complet")
    print(f"  Modele: claude-sonnet-4-6")
    print(f"  Mode: conversations multi-messages avec historique")
    print(f"{'#'*70}\n")

    print("Recuperation des emails depuis Outlook (inbox + sentItems)...")
    conversations = await fetch_conversations(max_msgs=100)
    if not conversations:
        print("Aucune conversation trouvee.")
        return

    multi = {k: v for k, v in conversations.items() if len(v) >= 2}
    single = {k: v for k, v in conversations.items() if len(v) == 1}
    print(f"  {len(conversations)} conversations trouvees")
    print(f"  {len(multi)} avec 2+ messages (threads)")
    print(f"  {len(single)} avec 1 seul message")

    # Sort: longest threads first, then singles by date
    sorted_convs = sorted(multi.items(), key=lambda x: len(x[1]), reverse=True)
    sorted_convs += sorted(single.items(), key=lambda x: x[1][0].get("received_at", ""), reverse=True)
    sorted_convs = sorted_convs[:limit]
    print(f"  Test sur {len(sorted_convs)} conversations\n")

    patches, mock_create_msg = _build_mocks()

    # Thread history for conversation context
    thread_histories: dict[str, list[dict]] = defaultdict(list)
    current_conv_id = [None]

    async def mock_get_conv_msgs(conversation_id, limit=10):
        cid = current_conv_id[0]
        if cid and cid in thread_histories:
            return list(thread_histories[cid][-limit:])
        return []

    patches.append(patch("src.services.email_processor.db.get_conversation_messages", mock_get_conv_msgs))

    results = []
    total_inbound = 0

    # Start all patches
    for p in patches:
        p.start()

    try:
        for conv_idx, (conv_id, messages) in enumerate(sorted_convs, 1):
            inbound = [m for m in messages if m["direction"] == "inbound"]
            outbound = [m for m in messages if m["direction"] == "outbound"]
            first_from = inbound[0]["from_name"] or inbound[0]["from_email"]

            print(f"\n{'='*70}")
            print(f"  CONVERSATION {conv_idx}/{len(sorted_convs)}")
            print(f"  Client: {first_from}")
            print(f"  Objet: {inbound[0].get('subject', '(sans objet)')}")
            print(f"  Messages: {len(inbound)} client + {len(outbound)} Marion")
            print(f"{'='*70}")

            current_conv_id[0] = conv_id
            thread_histories[conv_id] = []

            for msg_idx, msg in enumerate(messages, 1):
                d = msg["direction"]
                print(f"\n  [{msg_idx}/{len(messages)}] {'>> CLIENT' if d == 'inbound' else '<< MARION (reel)'}")
                print(f"  De: {msg.get('from_name', '')} <{msg['from_email']}>")
                print(f"  Date: {(msg.get('received_at') or '')[:16]}")
                print(f"  {_preview(msg)[:200]}")

                if d == "outbound":
                    # Marion's real reply -> add to history, don't process
                    thread_histories[conv_id].append({
                        "direction": "outbound",
                        "from_email": msg["from_email"],
                        "to_email": msg["to_email"],
                        "body_text": msg.get("body_text", ""),
                        "final_text": msg.get("body_text", ""),
                        "ai_draft": msg.get("body_text", ""),
                        "subject": msg.get("subject", ""),
                    })
                    continue

                # Inbound: process through pipeline
                total_inbound += 1
                print(f"  {'-'*60}")

                ai_draft = await _process_one(
                    msg, mock_create_msg, results, conv_id,
                    msg_idx, len(messages),
                )

                # Add to conversation history
                thread_histories[conv_id].append({
                    "direction": "inbound",
                    "from_email": msg["from_email"],
                    "body_text": msg.get("body_text", ""),
                    "subject": msg.get("subject", ""),
                })
                if ai_draft:
                    thread_histories[conv_id].append({
                        "direction": "outbound",
                        "from_email": "info@lemartinhotel.com",
                        "to_email": msg["from_email"],
                        "final_text": ai_draft,
                        "ai_draft": ai_draft,
                        "body_text": ai_draft,
                    })
    finally:
        for p in patches:
            p.stop()

    _print_summary(results, total_inbound, len(sorted_convs))


# -- Single email test -------------------------------------------------------

async def run_single_test(limit: int = 30):
    print(f"\n{'#'*70}")
    print(f"  TEST PIPELINE REEL - Mode email individuel")
    print(f"  Modele: claude-sonnet-4-6")
    print(f"{'#'*70}\n")

    from src.services.outlook import _get_token
    token = await _get_token()
    raw_msgs = await _fetch_folder("inbox", 50, token)

    emails = []
    for msg in raw_msgs:
        p = _parse_msg(msg, "inbound")
        if _is_guest(p["from_email"]):
            emails.append(p)
    emails = emails[:limit]

    if not emails:
        print("Aucun email recupere.")
        return
    print(f"  {len(emails)} emails a tester\n")

    patches, mock_create_msg = _build_mocks()
    patches.append(patch("src.services.email_processor.db.get_conversation_messages",
                         AsyncMock(return_value=[])))

    results = []

    for p in patches:
        p.start()

    try:
        for i, raw in enumerate(emails, 1):
            print(f"{'='*70}")
            print(f"  EMAIL {i}/{len(emails)}")
            print(f"  De: {raw.get('from_name', '')} <{raw['from_email']}>")
            print(f"  Objet: {raw.get('subject', '(sans objet)')}")
            print(f"  Date: {(raw.get('received_at') or '')[:16]}")
            print(f"-"*70)
            print(f"  {_preview(raw)[:200]}")
            print(f"-"*70)

            await _process_one(raw, mock_create_msg, results, "single", i, 1)
            print()
    finally:
        for p in patches:
            p.stop()

    _print_summary(results, len(emails))


# -- Summary printer ---------------------------------------------------------

def _print_summary(results: list, total_inbound: int = 0, total_convs: int = 0):
    ok = [r for r in results if r.get("status") == "processed"]
    escalated = [r for r in results if r.get("status") == "escalated"]
    skipped = [r for r in results if r.get("status") == "skipped"]
    errors = [r for r in results if r.get("status") in ("error", "crash")]

    print(f"\n{'#'*70}")
    print(f"  RESUME")
    print(f"{'#'*70}")
    if total_convs:
        print(f"  Conversations testees: {total_convs}")
        print(f"  Emails inbound traites: {total_inbound}")
    print(f"  Reponses IA: {len(ok)} | Escalades: {len(escalated)} | Skip: {len(skipped)} | Erreurs: {len(errors)}")

    if ok:
        wc = [r.get("word_count", 0) for r in ok if r.get("word_count")]
        cf = [r.get("confidence", 0) for r in ok if isinstance(r.get("confidence"), (int, float))]
        if wc:
            print(f"  Mots moyen: {sum(wc)/len(wc):.0f}")
        if cf:
            print(f"  Confiance moyenne: {sum(cf)/len(cf):.2f}")

    multi = [r for r in ok if r.get("thread_size", 0) > 1]
    if multi:
        print(f"  Reponses dans threads multi-messages: {len(multi)}")

    if errors:
        print(f"\n  ERREURS:")
        for e in errors:
            print(f"    - {e['from']}: {e.get('error', '?')}")


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", "-l", type=int, default=10,
                        help="Nombre de conversations a tester")
    parser.add_argument("--single", "-s", action="store_true",
                        help="Mode email individuel (pas de threads)")
    args = parser.parse_args()

    if args.single:
        asyncio.run(run_single_test(limit=args.limit))
    else:
        asyncio.run(run_conversation_test(limit=args.limit))
