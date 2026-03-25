"""Clean restaurants table: keep only 4 restaurants, delete everything else."""

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
    "Prefer": "return=representation",
}
HEADERS_MIN = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=minimal",
}
HEADERS_GET = {k: v for k, v in HEADERS.items() if k != "Prefer"}

KEEP_IDS = [
    "a270e553-4d8f-4dc0-8ca2-7e90e38d5823",  # Lulu's Corner
    "715cc282-4db4-4b11-a71f-33176a0e6c3a",  # Le Tropicana
]

# 1. Delete all restaurants NOT in keep list
print("=== DELETING extra restaurants ===")
keep_csv = ",".join(KEEP_IDS)
r = requests.delete(
    f"{SUPABASE_URL}/rest/v1/restaurants?id=not.in.({keep_csv})",
    headers=HEADERS_MIN,
)
print(f"  Delete status: {r.status_code}")

# 2. Update Lulu's Corner phone
print("\n=== UPDATING Lulu's Corner phone ===")
r = requests.patch(
    f"{SUPABASE_URL}/rest/v1/restaurants?id=eq.a270e553-4d8f-4dc0-8ca2-7e90e38d5823",
    headers=HEADERS_MIN,
    json={"phone": "+590 690 77 87 81"},
)
print(f"  Update: {r.status_code}")

# 3. Create Ristorante Del Arti
print("\n=== CREATING Ristorante Del Arti ===")
r = requests.post(
    f"{SUPABASE_URL}/rest/v1/restaurants",
    headers=HEADERS,
    json={
        "name": "Ristorante Del Arti",
        "area": "Saint-Martin",
        "cuisine": "Italien",
        "phone": "+590 690 73 96 33",
        "reservation_required": True,
        "is_partner": True,
        "sort_order": 1,
    },
)
print(f"  Create: {r.status_code}")
if r.status_code in (200, 201):
    data = r.json()
    new_id = data[0]["id"] if isinstance(data, list) else data.get("id", "?")
    print(f"  ID: {new_id}")

# 4. Create Le Terrasse Rooftop Restaurant
print("\n=== CREATING Le Terrasse Rooftop Restaurant ===")
r = requests.post(
    f"{SUPABASE_URL}/rest/v1/restaurants",
    headers=HEADERS,
    json={
        "name": "Le Terrasse Rooftop Restaurant",
        "area": "Saint-Martin",
        "cuisine": "Gastronomique",
        "phone": "+590 690 66 99 99",
        "reservation_required": True,
        "is_partner": True,
        "sort_order": 3,
    },
)
print(f"  Create: {r.status_code}")
if r.status_code in (200, 201):
    data = r.json()
    new_id = data[0]["id"] if isinstance(data, list) else data.get("id", "?")
    print(f"  ID: {new_id}")

# 5. Verify final state
print("\n=== VERIFICATION ===")
r = requests.get(
    f"{SUPABASE_URL}/rest/v1/restaurants?select=name,phone,cuisine,is_partner&order=sort_order",
    headers=HEADERS_GET,
)
data = r.json()
print(f"Total restaurants: {len(data)}")
for rest in data:
    partner = "PARTNER" if rest.get("is_partner") else ""
    print(f"  {rest['name']:35} | {rest.get('phone',''):20} | {rest.get('cuisine',''):20} | {partner}")

print("\nDONE!")
