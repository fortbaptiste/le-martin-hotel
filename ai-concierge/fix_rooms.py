"""Fix rooms: public names + clear static prices (Thais is source of truth)."""

import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

import os
import requests
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

# Update room names to public categories + clear prices
rooms = [
    ("marius", "Suite Deluxe Vue Mer"),
    ("pierre", "Chambre Privilège"),
    ("marcelle", "Suite Deluxe Vue Mer"),
    ("rene", "Suite Deluxe Vue Mer"),
    ("marthe", "Suite Deluxe Vue Mer"),
    ("georgette", "Suite Deluxe Vue Mer"),
]

for slug, new_name in rooms:
    r = requests.patch(
        f"{SUPABASE_URL}/rest/v1/rooms?slug=eq.{slug}",
        headers=H,
        json={"name": new_name, "price_low_season": None, "price_high_season": None},
    )
    status = "OK" if r.status_code == 204 else f"ERROR {r.status_code}: {r.text[:150]}"
    print(f"  {slug:20} → {new_name:25} | {status}")

# Verify
print("\n=== ROOMS AFTER FIX ===")
r = requests.get(
    f"{SUPABASE_URL}/rest/v1/rooms?select=slug,name,category,price_low_season,price_high_season&order=sort_order",
    headers=H_GET,
)
for rm in r.json():
    print(
        f"  {rm['slug']:20} | {rm['name']:25} | {rm['category']:15} | "
        f"low={rm.get('price_low_season')} high={rm.get('price_high_season')}"
    )
