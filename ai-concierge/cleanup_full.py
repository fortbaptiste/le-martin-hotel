"""Full Supabase cleanup — make everything perfect."""

import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

import os
import requests
import json
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SERVICE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
H = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=minimal",
}
H_GET = {k: v for k, v in H.items() if k != "Prefer"}


def delete_all(table):
    """Delete all rows from a table."""
    r = requests.delete(f"{SUPABASE_URL}/rest/v1/{table}?id=not.is.null", headers=H)
    print(f"  DELETE {table}: {r.status_code}")
    return r.status_code


def delete_by_id(table, row_id):
    r = requests.delete(f"{SUPABASE_URL}/rest/v1/{table}?id=eq.{row_id}", headers=H)
    print(f"  DELETE {table} {row_id[:8]}...: {r.status_code}")
    return r.status_code


def patch(table, row_id, data):
    r = requests.patch(
        f"{SUPABASE_URL}/rest/v1/{table}?id=eq.{row_id}",
        headers=H,
        json=data,
    )
    print(f"  PATCH {table} {row_id[:8]}...: {r.status_code}")
    return r.status_code


# ============================================================
# 1. DELETE UNUSED TABLES (clear all rows)
# ============================================================
print("=" * 60)
print("1. SUPPRESSION TABLES INUTILES")
print("=" * 60)

delete_all("reviews")
delete_all("review_stats")
delete_all("ai_corrections")

# ============================================================
# 2. DELETE ACTIVITIES (user confirmed not needed)
# ============================================================
print("\n" + "=" * 60)
print("2. SUPPRESSION ACTIVITÉS")
print("=" * 60)

delete_all("activities")

# Delete activity-related AI rules
delete_by_id("ai_rules", "d9f3bc00-4e57-457c-a696-aa202648bc2d")  # Activité demandée
delete_by_id("ai_rules", "616533ae-4ab7-4d0c-8db5-899026e97efc")  # Classification email — activités

# ============================================================
# 3. DELETE CONVERSATIONS + MESSAGES + ESCALATIONS
# ============================================================
print("\n" + "=" * 60)
print("3. SUPPRESSION CONVERSATIONS (+ messages + escalations)")
print("=" * 60)

# Order matters: messages first (FK to conversations), then escalations, then conversations
delete_all("messages")
delete_all("escalations")
delete_all("conversations")

# ============================================================
# 4. FIX HOTEL_SERVICES
# ============================================================
print("\n" + "=" * 60)
print("4. NETTOYAGE HOTEL_SERVICES")
print("=" * 60)

# Remove the confusing 115€ online booking transfer
delete_by_id("hotel_services", "a8161550-2ce7-4dca-82a9-47fab1ee3e6c")
print("  → Supprimé: Transfert réservation en ligne (115€)")

# Fix duplicate bouquets — rename the event one to be distinct
patch("hotel_services", "8f896d94-8327-4bfb-a7ff-e956bca68d26", {
    "name_fr": "Bouquet de fleurs événement (grand)",
    "name_en": "Event flower bouquet (large)",
})
print("  → Renommé: Bouquet event 60€ → 'Bouquet de fleurs événement (grand)'")

# ============================================================
# 5. FIX ROOMS — Public names + remove static prices
# ============================================================
print("\n" + "=" * 60)
print("5. NETTOYAGE ROOMS — Noms publics + prix → NULL (Thais only)")
print("=" * 60)

# Room mappings: slug → public name
# Thais categories: Deluxe Vue Mer (type 10), Privilège (type 13), Familiale (type 7)
room_updates = {
    # Suite Marius → Deluxe Sea View
    "marius": {
        "name": "Suite Deluxe Vue Mer",
        "category": "deluxe_sea_view",
        "price_low_season": None,
        "price_high_season": None,
    },
    # Chambre Pierre → Privilege
    "pierre": {
        "name": "Chambre Privilège",
        "category": "privilege",
        "price_low_season": None,
        "price_high_season": None,
    },
    # Suite Marcelle → Deluxe Sea View
    "marcelle": {
        "name": "Suite Deluxe Vue Mer",
        "category": "deluxe_sea_view",
        "price_low_season": None,
        "price_high_season": None,
    },
    # Suite René → Deluxe Sea View (biggest, 41m²)
    "rene": {
        "name": "Suite Deluxe Vue Mer",
        "category": "deluxe_sea_view",
        "price_low_season": None,
        "price_high_season": None,
    },
    # Suite Marthe → Deluxe Sea View
    "marthe": {
        "name": "Suite Deluxe Vue Mer",
        "category": "deluxe_sea_view",
        "price_low_season": None,
        "price_high_season": None,
    },
    # Suite Georgette → Deluxe Sea View
    "georgette": {
        "name": "Suite Deluxe Vue Mer",
        "category": "deluxe_sea_view",
        "price_low_season": None,
        "price_high_season": None,
    },
    # Suite Familiale
    "family-suite": {
        "name": "Suite Familiale",
        "category": "family_suite",
        "price_low_season": None,
        "price_high_season": None,
    },
}

for slug, data in room_updates.items():
    r = requests.patch(
        f"{SUPABASE_URL}/rest/v1/rooms?slug=eq.{slug}",
        headers=H,
        json=data,
    )
    print(f"  PATCH rooms slug={slug}: {r.status_code} → {data['name']}")


# ============================================================
# 6. VERIFICATION
# ============================================================
print("\n" + "=" * 60)
print("6. VÉRIFICATION FINALE")
print("=" * 60)

# Count all tables
check_tables = [
    "reviews", "review_stats", "ai_corrections", "activities",
    "conversations", "messages", "escalations",
    "rooms", "hotel_services", "restaurants", "beaches",
    "practical_info", "transport_schedules", "faq", "partners",
    "email_templates", "email_examples", "ai_rules",
    "clients", "daily_summaries",
]

H_COUNT = {**H_GET, "Prefer": "count=exact", "Range": "0-0"}
for table in check_tables:
    r = requests.head(f"{SUPABASE_URL}/rest/v1/{table}?select=id", headers=H_COUNT)
    count = r.headers.get("content-range", "ERROR")
    print(f"  {table:25} | {count}")

# Verify rooms have no internal names
print("\n--- Rooms after cleanup ---")
r = requests.get(
    f"{SUPABASE_URL}/rest/v1/rooms?select=slug,name,category,price_low_season,price_high_season&order=sort_order",
    headers=H_GET,
)
for rm in r.json():
    print(f"  {rm['slug']:20} | {rm['name']:25} | {rm['category']:18} | low={rm.get('price_low_season')} high={rm.get('price_high_season')}")

# Verify hotel_services transfer section
print("\n--- Hotel services (transport/concierge) ---")
r = requests.get(
    f"{SUPABASE_URL}/rest/v1/hotel_services?select=name_fr,price_eur,category&category=in.(transport,concierge)&order=category",
    headers=H_GET,
)
for s in r.json():
    print(f"  {s['category']:12} | {s['name_fr']:45} | {s.get('price_eur',0)} EUR")

# Verify no bouquet duplicates
print("\n--- Hotel services (bouquets) ---")
r = requests.get(
    f"{SUPABASE_URL}/rest/v1/hotel_services?select=name_fr,price_eur,category&name_fr=ilike.*bouquet*",
    headers=H_GET,
)
for s in r.json():
    print(f"  {s['category']:12} | {s['name_fr']:45} | {s.get('price_eur',0)} EUR")

print("\n✓ CLEANUP COMPLETE")
