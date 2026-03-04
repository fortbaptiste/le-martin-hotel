"""
Simulate an inbound email to test the full pipeline.

Usage:
    python -m scripts.simulate_email
    python -m scripts.simulate_email --scenario complaint
    python -m scripts.simulate_email --scenario availability
    python -m scripts.simulate_email --scenario restaurant

This bypasses Outlook entirely — it creates a fake InboundEmail and runs
it through the pipeline. The AI draft is printed to stdout instead of
being sent to Outlook.
"""

from __future__ import annotations

import argparse
import asyncio
import json
import sys
from datetime import datetime
from unittest.mock import AsyncMock, patch

# Ensure src is importable
sys.path.insert(0, str(__file__).rsplit("scripts", 1)[0])

from src.models.message import InboundEmail  # noqa: E402

# ---------------------------------------------------------------------------
# Test scenarios
# ---------------------------------------------------------------------------

SCENARIOS: dict[str, InboundEmail] = {
    "availability": InboundEmail(
        outlook_message_id="SIM-001",
        outlook_conversation_id="SIM-CONV-001",
        from_email="john.smith@gmail.com",
        from_name="John Smith",
        to_email="info@lemartinhotel.com",
        subject="Room availability — February 2027",
        body_text=(
            "Hello,\n\n"
            "My wife and I are planning a trip to Saint-Martin in February 2027. "
            "We would love to stay at Le Martin Boutique Hotel.\n\n"
            "Could you please let us know if you have a room available from "
            "February 14 to February 21, 2027? We're celebrating our anniversary "
            "and would appreciate a room with a nice view.\n\n"
            "Also, could you recommend some romantic restaurants nearby?\n\n"
            "Thank you!\n"
            "John Smith"
        ),
        received_at=datetime.now(),
    ),
    "restaurant": InboundEmail(
        outlook_message_id="SIM-002",
        outlook_conversation_id="SIM-CONV-002",
        from_email="marie.dupont@outlook.fr",
        from_name="Marie Dupont",
        to_email="info@lemartinhotel.com",
        subject="Recommandations restaurants",
        body_text=(
            "Bonjour Marion,\n\n"
            "Nous arrivons la semaine prochaine et nous aimerions réserver "
            "quelques restaurants pour notre séjour. Nous sommes un couple "
            "et nous aimons la gastronomie française et les fruits de mer.\n\n"
            "Pourriez-vous nous recommander vos adresses préférées ?\n\n"
            "Merci beaucoup,\n"
            "Marie"
        ),
        received_at=datetime.now(),
    ),
    "complaint": InboundEmail(
        outlook_message_id="SIM-003",
        outlook_conversation_id="SIM-CONV-003",
        from_email="angry.guest@yahoo.com",
        from_name="Robert Martin",
        to_email="info@lemartinhotel.com",
        subject="Unacceptable situation",
        body_text=(
            "I am extremely disappointed with my recent stay. "
            "The room was not clean and the air conditioning was broken. "
            "I want a full refund immediately.\n\n"
            "Robert Martin"
        ),
        received_at=datetime.now(),
    ),
    "family": InboundEmail(
        outlook_message_id="SIM-004",
        outlook_conversation_id="SIM-CONV-004",
        from_email="family.vacation@gmail.com",
        from_name="Sophie Laurent",
        to_email="info@lemartinhotel.com",
        subject="Vacances en famille — 4 personnes",
        body_text=(
            "Bonjour,\n\n"
            "Nous sommes une famille de 4 (2 adultes + 2 enfants de 8 et 12 ans) "
            "et nous cherchons un hébergement pour les vacances de Pâques "
            "(du 12 au 19 avril 2027).\n\n"
            "Avez-vous une chambre adaptée aux familles ?\n"
            "Quelles activités sont disponibles pour les enfants ?\n\n"
            "Merci,\n"
            "Sophie Laurent"
        ),
        received_at=datetime.now(),
    ),
    "activity": InboundEmail(
        outlook_message_id="SIM-005",
        outlook_conversation_id="SIM-CONV-005",
        from_email="adventure@gmail.com",
        from_name="Tom Wilson",
        to_email="info@lemartinhotel.com",
        subject="Water activities and beaches",
        body_text=(
            "Hi there!\n\n"
            "We're arriving next week and would love to know about water sports "
            "and snorkeling opportunities near the hotel. We've heard about "
            "Pinel Island — how do we get there?\n\n"
            "Also, which beaches do you recommend for snorkeling?\n\n"
            "Thanks!\nTom"
        ),
        received_at=datetime.now(),
    ),
}


# ---------------------------------------------------------------------------
# Mock Outlook (no real emails sent)
# ---------------------------------------------------------------------------

def _mock_outlook():
    """Patch Outlook calls to print instead of sending."""
    mocks = {
        "src.services.outlook.mark_as_read": AsyncMock(),
        "src.services.outlook.send_reply": AsyncMock(),
        "src.services.outlook.send_email": AsyncMock(),
    }

    async def mock_create_draft(message_id: str, body_html: str) -> str:
        print("\n" + "=" * 60)
        print("DRAFT CREATED (would appear in Outlook Drafts)")
        print("=" * 60)
        # Strip HTML tags for readability
        import re
        clean = re.sub(r"<[^>]+>", "", body_html)
        clean = re.sub(r"&amp;", "&", clean)
        clean = re.sub(r"&lt;", "<", clean)
        clean = re.sub(r"&gt;", ">", clean)
        print(clean)
        print("=" * 60)
        return "DRAFT-SIM-001"

    mocks["src.services.outlook.create_draft_reply"] = AsyncMock(side_effect=mock_create_draft)
    return mocks


async def run_simulation(scenario_name: str):
    """Run a simulated email through the pipeline."""
    email = SCENARIOS.get(scenario_name)
    if not email:
        print(f"Unknown scenario: {scenario_name}")
        print(f"Available: {', '.join(SCENARIOS.keys())}")
        return

    print(f"\nSimulating: {scenario_name}")
    print(f"From: {email.from_name} <{email.from_email}>")
    print(f"Subject: {email.subject}")
    print("-" * 60)
    print(email.body_text)
    print("-" * 60)

    # Import here to avoid loading everything at module level
    from src.services.email_processor import process_email

    # Mock Outlook calls
    mocks = _mock_outlook()
    patches = [patch(target, mock) for target, mock in mocks.items()]

    for p in patches:
        p.start()

    try:
        result = await process_email(email)
        print(f"\nResult: {json.dumps(result, indent=2, ensure_ascii=False)}")
    except Exception as exc:
        print(f"\nError: {exc}")
        import traceback
        traceback.print_exc()
    finally:
        for p in patches:
            p.stop()


def main():
    parser = argparse.ArgumentParser(description="Simulate an inbound email")
    parser.add_argument(
        "--scenario", "-s",
        default="availability",
        choices=list(SCENARIOS.keys()),
        help="Test scenario to run (default: availability)",
    )
    args = parser.parse_args()
    asyncio.run(run_simulation(args.scenario))


if __name__ == "__main__":
    main()
