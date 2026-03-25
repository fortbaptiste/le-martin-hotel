"""One-time script to clean Supabase live data — remove parasitic restaurant names, hardcoded prices, internal room names."""

import os
import requests
import json
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SERVICE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
HEADERS = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=minimal",
}


def patch(table, uuid, data):
    r = requests.patch(
        f"{SUPABASE_URL}/rest/v1/{table}?id=eq.{uuid}",
        headers=HEADERS,
        json=data,
    )
    print(f"  {table} {uuid[:8]}... -> {r.status_code}")
    return r.status_code


# ============================================================
# 1. EMAIL TEMPLATES — clean restaurant templates
# ============================================================
print("=== TEMPLATES ===")

patch("email_templates", "1eb66427-3319-4855-a1a0-dcbbe98e3e00", {
    "body": (
        "Dear {guest_name},\n\n"
        "We are delighted to share with you a selection of carefully chosen restaurants, "
        "perfectly aligned with the spirit of the Martin Boutique Hotel.\n\n"
        "{restaurant_list}\n\n"
        "We remain at your full disposal to make reservations or guide you.\n\n"
        "Warm regards,\nMarion & Emmanuel\nThe Martin Boutique Hotel"
    ),
    "variables": ["guest_name", "restaurant_list"],
    "notes": "Template restaurant. {restaurant_list} = UNIQUEMENT search_restaurants.",
})

patch("email_templates", "32858b6c-1c4e-42e7-ae3b-332a849fdc3a", {
    "body": (
        "Chers {guest_name},\n\n"
        "Nous sommes ravis de vous proposer une selection de restaurants soigneusement choisis.\n\n"
        "{restaurant_list}\n\n"
        "Nous restons a votre disposition pour les reservations.\n\n"
        "Chaleureusement,\nMarion & Emmanuel\nLe Martin Boutique Hotel"
    ),
    "variables": ["guest_name", "restaurant_list"],
    "notes": "Version FR. {restaurant_list} = UNIQUEMENT search_restaurants.",
})

patch("email_templates", "3bcbb290-6e85-4895-ab06-53dd39e24e76", {
    "body": (
        "Hello {guest_name},\n\n"
        "Here are a few restaurants we love for your stay:\n\n"
        "{restaurant_list}\n\n"
        "Happy to help with reservations!\n\nMarion & Emmanuel"
    ),
    "variables": ["guest_name", "restaurant_list"],
    "notes": "WhatsApp EN. {restaurant_list} = UNIQUEMENT search_restaurants.",
})

patch("email_templates", "b1818bdb-4407-4fb4-8d25-6a3dc094be06", {
    "body": (
        "Bonjour {guest_name},\n\n"
        "Voici quelques adresses que nous aimons:\n\n"
        "{restaurant_list}\n\n"
        "A votre disposition pour reserver!\n\nMarion & Emmanuel"
    ),
    "variables": ["guest_name", "restaurant_list"],
    "notes": "WhatsApp FR. {restaurant_list} = UNIQUEMENT search_restaurants.",
})


# ============================================================
# 2. EMAIL EXAMPLES — clean restaurant names + internal room names
# ============================================================
print("\n=== EXAMPLES ===")

# Ex3: restaurant (had Coco Beach, Babacool, Kalatua)
patch("email_examples", "e764d4fc-1de8-43c1-af4a-5a466b791378", {
    "client_message": (
        "We were hoping you could help us with dinner reservations. "
        "We are looking for a romantic spot with good food and French atmosphere."
    ),
    "marion_response": (
        "Dear Richard,\n\n"
        "We are looking forward to seeing you soon!\n\n"
        "I would love to recommend a couple of our favorite spots. "
        "Let me check availability and come back to you with a confirmed reservation.\n\n"
        "Warm regards,\nMarion & Emmanuel"
    ),
    "context": "Client demande conseil restaurant. Appeler search_restaurants.",
    "learnings": [
        "TOUJOURS appeler search_restaurants avant de recommander",
        "Ne JAMAIS citer un restaurant hors de la base",
        "Proposer de faire la reservation",
    ],
})

# Ex4: reservation (had Marius, Pierre, Marcelle)
patch("email_examples", "cf89051a-ff20-4446-a90f-6654ab96bbce", {
    "marion_response": (
        "Bonsoir Jon,\n\n"
        "Thank you for your message. We would be delighted to welcome you "
        "and your wife to celebrate her birthday.\n\n"
        "We no longer have availability in the same room for the entire stay, but we can offer:\n\n"
        "Feb 19-23: Deluxe Sea View Suite\n"
        "Feb 23-26: Privilege Room garden view\n\n"
        "I will send you a quotation with our Advance Purchase rate (-10%, non-refundable).\n\n"
        "Book directly: https://lemartinhotel.thais-hotel.com/direct-booking/calendar\n\n"
        "Warm regards,\nMarion & Emmanuel"
    ),
    "context": "Client veut 1 chambre sur 7 nuits, pas dispo. Proposer 2 chambres.",
    "learnings": [
        "JAMAIS noms internes (Marius, Pierre, etc.) - categories publiques",
        "TOUJOURS inclure lien reservation",
        "Mentionner Advance Purchase (-10%)",
    ],
})

# Ex7: birthday (had hardcoded prices 75/60/165 EUR)
patch("email_examples", "25491564-dc2b-4203-a318-c3c8307d383f", {
    "marion_response": (
        "Dear Nneka,\n\n"
        "Thank you for your lovely message!\n\n"
        "We would be happy to organize a birthday decoration for Erica. "
        "We prepare balloons with little notes attached. "
        "You can send us 10 short messages.\n\n"
        "We can also arrange flowers for the room.\n\n"
        "Let me check the exact rates and come back with a quote.\n\n"
        "Warm regards,\nMarion & Emmanuel"
    ),
    "learnings": [
        "Enthousiasme pour occasions speciales",
        "TOUJOURS appeler get_hotel_services pour les tarifs",
        "Ne JAMAIS citer un prix de memoire",
    ],
})

# Ex8: planning (had Coco Beach, Maison Mere, Le Pressoir, Joa Beach)
patch("email_examples", "0414d7a0-dcb2-4c6d-b512-3f76ddf59673", {
    "title": "Organisation complete diners sur sejour long",
    "client_message": (
        "Could you help us organize dinner reservations for our 7-night stay? "
        "We love good food and would like a mix of French and Italian."
    ),
    "marion_response": (
        "Dear Joseph and Phil,\n\n"
        "We are delighted to welcome you back!\n\n"
        "Dinner seatings are typically at 6:30 or 8:00 p.m. "
        "I will check our recommended restaurants and come back with a full plan.\n\n"
        "Kind regards,\nMarion & Emmanuel"
    ),
    "context": "Sejour long. Appeler search_restaurants UNIQUEMENT.",
    "learnings": [
        "Pour sejours longs, organiser tous les repas",
        "TOUJOURS appeler search_restaurants",
        "Ne jamais citer un restaurant de memoire",
    ],
})

# Ex2: context fix (had internal name Marcelle)
patch("email_examples", "94364cb4-05a1-4bab-ba81-29c7fe8bca0c", {
    "context": "Client fidele qui revient. Reservation existante.",
})


# ============================================================
# 3. AI RULES — remove hardcoded prices and restaurant names
# ============================================================
print("\n=== AI RULES ===")

patch("ai_rules", "d95eb5d2-2580-4801-acbb-c14f4b18a60a", {
    "action_text": "Appeler get_hotel_services pour obtenir les tarifs exacts. Ne JAMAIS citer un prix de memoire.",
})

patch("ai_rules", "616533ae-4ab7-4d0c-8db5-899026e97efc", {
    "action_text": "Appeler search_activities pour obtenir les activites avec tarifs. Ne citer QUE les activites retournees par l outil.",
})

patch("ai_rules", "ee67005c-d7a4-45c8-af32-5145c3d087a7", {
    "action_text": "Appeler get_transport_schedules pour horaires et tarifs. Mentionner passeport obligatoire. Ne JAMAIS citer un prix de memoire.",
})

patch("ai_rules", "12e4c986-9d73-4d7d-8ceb-4e8e963097e1", {
    "action_text": "Appeler get_hotel_services pour les tarifs de transfert. Trajet Princess Juliana = 1h. Demander vol et heure. Ne JAMAIS citer un prix de memoire.",
})

patch("ai_rules", "0a91948d-fca8-4c4f-b539-60096626dfa7", {
    "action_text": "Etre honnete. Si un lieu n est pas dans la base, dire je me renseigne pour vous et appeler request_team_action. Ne JAMAIS inventer un avis.",
})

# Also fix the restaurant classification rule
# Get its ID first
r = requests.get(
    f"{SUPABASE_URL}/rest/v1/ai_rules?select=id&rule_name=eq.Classification email — restaurant",
    headers={k: v for k, v in HEADERS.items() if k != "Prefer"},
)
restaurant_rules = r.json()
if restaurant_rules:
    patch("ai_rules", restaurant_rules[0]["id"], {
        "action_text": "Appeler search_restaurants pour obtenir les restaurants. Ne citer QUE les restaurants retournes par l outil.",
    })

print("\n=== VERIFICATION ===")
# Verify
HEADERS_GET = {k: v for k, v in HEADERS.items() if k != "Prefer"}
bad_names = ["Karibuni", "Coco Beach", "Calmos", "Les Galets", "Maison Mere",
             "Le Cottage", "Astrolabe", "Le Pressoir", "Babacool", "Kalatua",
             "Les Lolos", "Le Java", "Aloha", "Marius", "Marcelle", "Georgette"]

for table in ["email_templates", "email_examples", "ai_rules"]:
    r = requests.get(f"{SUPABASE_URL}/rest/v1/{table}?select=*", headers=HEADERS_GET)
    all_text = str(r.json())
    found = [n for n in bad_names if n.lower() in all_text.lower()]
    if found:
        print(f"  WARNING {table}: still has {found}")
    else:
        print(f"  OK {table}: CLEAN")

print("\nDONE!")
