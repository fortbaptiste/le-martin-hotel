"""Simulation locale — test le pipeline IA sans toucher Outlook ni envoyer d'email.

Appelle le vrai Claude API + Thais PMS + Supabase (lecture seule).
"""
from __future__ import annotations

import asyncio
import io
import sys
import time

# Fix Windows UTF-8 output
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

# ── Patch Outlook AVANT tout import du pipeline ──
# On ne veut AUCUN appel Outlook (ni envoi, ni draft, ni mark_as_read)
import src.services.outlook as outlook_mod

async def _noop(*a, **kw):
    return None

async def _fake_draft(*a, **kw):
    return "SIMULATED-DRAFT-ID-001"

outlook_mod.fetch_unread_emails = _noop
outlook_mod.mark_as_read = _noop
outlook_mod.send_reply = _noop
outlook_mod.send_email = _noop
outlook_mod.create_draft_reply = _fake_draft

# ── Capture des réponses IA ──
# On intercepte create_message pour récupérer le brouillon IA
_last_ai_draft = []

import src.services.supabase_client as _db_mod
_original_create_message = _db_mod.create_message

async def _capture_create_message(data):
    """Intercept outbound messages to capture AI draft text."""
    if data.get("direction") and str(data["direction"]).lower() in ("outbound", "MessageDirection.OUTBOUND"):
        _last_ai_draft.append(data.get("ai_draft", ""))
    elif hasattr(data.get("direction"), "value") and data["direction"].value == "outbound":
        _last_ai_draft.append(data.get("ai_draft", ""))
    return await _original_create_message(data)

_db_mod.create_message = _capture_create_message

# ── Imports réels ──
from datetime import datetime
from src.models.message import InboundEmail
from src.services.email_processor import process_email, _processed_ids, _retry_counts, _PROCESSED_IDS_FILE


# ── Emails de test ──
TEST_EMAILS = [
    {
        "name": "🏨 Demande de réservation (FR)",
        "email": InboundEmail(
            outlook_message_id="SIM-001-reservation",
            outlook_conversation_id="CONV-SIM-001",
            from_email="jean.dupont@gmail.com",
            from_name="Jean Dupont",
            to_email="info@lemartinhotel.com",
            subject="Réservation chambre",
            body_text="Bonjour,\n\nJ'aimerais louer une chambre du 4 juin au 8 juin 2026 s'il vous plaît.\nNous sommes 2 adultes.\n\nMerci d'avance,\nJean",
            received_at=datetime.now(),
        ),
    },
    {
        "name": "🍽️ Restaurant recommendation (EN)",
        "email": InboundEmail(
            outlook_message_id="SIM-002-restaurant",
            outlook_conversation_id="CONV-SIM-002",
            from_email="sarah.johnson@outlook.com",
            from_name="Sarah Johnson",
            to_email="info@lemartinhotel.com",
            subject="Restaurant recommendation",
            body_text="Hi,\n\nWe're staying at Le Martin next week for our honeymoon. Could you recommend a romantic restaurant for a special dinner?\n\nThank you!\nSarah",
            received_at=datetime.now(),
        ),
    },
    {
        "name": "🏖️ Question plage et activités (FR)",
        "email": InboundEmail(
            outlook_message_id="SIM-003-plage",
            outlook_conversation_id="CONV-SIM-003",
            from_email="marie.leclerc@yahoo.fr",
            from_name="Marie Leclerc",
            to_email="info@lemartinhotel.com",
            subject="Plages et activités",
            body_text="Bonjour Marion,\n\nNous arrivons la semaine prochaine. Quelles sont les plus belles plages à proximité de l'hôtel ? Y a-t-il des kayaks ou paddles disponibles ?\n\nMerci !\nMarie",
            received_at=datetime.now(),
        ),
    },
    {
        "name": "😡 Plainte (escalation test)",
        "email": InboundEmail(
            outlook_message_id="SIM-004-plainte",
            outlook_conversation_id="CONV-SIM-004",
            from_email="angry.guest@gmail.com",
            from_name="Pierre Martin",
            to_email="info@lemartinhotel.com",
            subject="Réclamation urgente",
            body_text="Bonjour,\n\nC'est inacceptable ! La climatisation ne fonctionne pas depuis 2 jours. Je demande un remboursement ou un changement de chambre immédiat.\n\nPierre Martin",
            received_at=datetime.now(),
        ),
    },
    {
        "name": "✈️ Transfer aéroport (FR)",
        "email": InboundEmail(
            outlook_message_id="SIM-005-transfer",
            outlook_conversation_id="CONV-SIM-005",
            from_email="famille.bernard@free.fr",
            from_name="Famille Bernard",
            to_email="info@lemartinhotel.com",
            subject="Transfert aéroport",
            body_text="Bonjour,\n\nNous arrivons à l'aéroport de Grand Case (SFG) le 15 juin à 14h. Est-ce que vous proposez un service de transfert depuis l'aéroport ?\n\nCordialement,\nFamille Bernard",
            received_at=datetime.now(),
        ),
    },
]


async def run_simulation():
    print("=" * 70)
    print("  SIMULATION LOCALE — Le Martin Hotel AI Concierge")
    print("  Mode: OBSERVATION (aucun email envoyé, aucun draft Outlook)")
    print("  API: Claude réel + Thais PMS réel + Supabase lecture seule")
    print("=" * 70)

    # Reset ALL processed IDs (file + memory) to start fresh
    _processed_ids.clear()
    _retry_counts.clear()
    if _PROCESSED_IDS_FILE.exists():
        _PROCESSED_IDS_FILE.write_text("")

    for i, test in enumerate(TEST_EMAILS, 1):

        print(f"\n{'─' * 70}")
        print(f"  TEST {i}/{len(TEST_EMAILS)}: {test['name']}")
        print(f"  De: {test['email'].from_name} <{test['email'].from_email}>")
        print(f"  Objet: {test['email'].subject}")
        print(f"  Message: {test['email'].body_text[:100]}...")
        print(f"{'─' * 70}")

        _last_ai_draft.clear()
        start = time.monotonic()
        try:
            result = await process_email(test["email"])
            elapsed = time.monotonic() - start

            print(f"\n  ✅ Status: {result['status']}")

            if result["status"] == "escalated":
                print(f"  ⚠️  Raison escalade: {result.get('reason', '?')}")
                print(f"  → Pas de réponse IA (escaladé directement à Emmanuel)")
            elif result["status"] == "processed":
                print(f"  📊 Confidence: {result.get('confidence', '?')}")
                print(f"  📂 Catégorie: {result.get('category', '?')}")
                print(f"  🔧 Outils: {result.get('tools_used', [])}")
                print(f"  💰 Coût: {result.get('cost_eur', 0):.4f} €")
                if result.get("deferred_escalation"):
                    print(f"  ⚠️  Escalade différée: {result['deferred_escalation']}")

                # Afficher la réponse IA
                if _last_ai_draft:
                    print(f"\n  {'╔' + '═' * 60 + '╗'}")
                    print(f"  ║  RÉPONSE IA (brouillon pour Emmanuel){'':>21}║")
                    print(f"  {'╠' + '═' * 60 + '╣'}")
                    for line in _last_ai_draft[-1].split("\n"):
                        # Wrap long lines
                        while len(line) > 58:
                            print(f"  ║ {line[:58]} ║")
                            line = line[58:]
                        print(f"  ║ {line:<58} ║")
                    print(f"  {'╚' + '═' * 60 + '╝'}")

            print(f"  ⏱️  Temps: {elapsed:.1f}s")

        except Exception as exc:
            elapsed = time.monotonic() - start
            print(f"\n  ❌ ERREUR: {exc}")
            print(f"  ⏱️  Temps: {elapsed:.1f}s")
            import traceback
            traceback.print_exc()

    print(f"\n{'=' * 70}")
    print("  SIMULATION TERMINÉE")
    print("=" * 70)


if __name__ == "__main__":
    asyncio.run(run_simulation())
