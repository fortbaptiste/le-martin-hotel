"""Full audit of Supabase live database."""

import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

import os
import requests
import json
from collections import Counter
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SERVICE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
H = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
    "Content-Type": "application/json",
}


def get(table, select="*", **params):
    url = f"{SUPABASE_URL}/rest/v1/{table}?select={select}"
    for k, v in params.items():
        url += f"&{k}={v}"
    r = requests.get(url, headers=H)
    return r.json() if r.status_code == 200 else []


# ai_rules
print("=== AI_RULES (34 rows) ===")
rules = get("ai_rules", "id,rule_name,category,priority,condition_text,action_text", order="category,priority")
for rule in rules:
    print(f"  {str(rule.get('category','')):20} | P{rule.get('priority','?')} | {str(rule.get('rule_name',''))}")

print()

# reviews
print("=== REVIEWS (211 rows) ===")
reviews = get("reviews", "source,rating,language,date")
source_counts = Counter(r.get("source", "") for r in reviews)
lang_counts = Counter(r.get("language", "") for r in reviews)
rating_counts = Counter(r.get("rating", 0) for r in reviews)
print(f"  By source: {dict(source_counts)}")
print(f"  By language: {dict(lang_counts)}")
print(f"  By rating: {dict(sorted(rating_counts.items()))}")

# Sample a few reviews
print("\n  Sample reviews:")
sample = get("reviews", "source,rating,guest_name,title,language", order="date.desc", limit=5)
for rv in sample:
    print(f"    {rv.get('source',''):15} | {rv.get('rating','')}/5 | {rv.get('language',''):3} | {str(rv.get('guest_name','')):15} | {str(rv.get('title',''))[:50]}")

print()

# review_stats
print("=== REVIEW_STATS (2 rows) ===")
stats = get("review_stats")
print(json.dumps(stats, indent=2, ensure_ascii=False))

print()

# ai_corrections
print("=== AI_CORRECTIONS (0 rows) ===")
corrections = get("ai_corrections", limit=3)
print(f"  Empty: {corrections}")

print()

# conversations
print("=== CONVERSATIONS (30 rows) ===")
convos = get("conversations", "*", limit=1)
if convos:
    print(f"  COLUMNS: {list(convos[0].keys())}")
convos = get("conversations", "guest_email,status,created_at,subject", order="created_at.desc", limit=10)
for c in convos:
    print(f"  {str(c.get('guest_email','')):35} | {str(c.get('status','')):10} | {str(c.get('created_at',''))[:19]} | {str(c.get('subject',''))[:40]}")

# Check for test/dummy data in conversations
print("\n  All statuses:")
convos_all = get("conversations", "status")
status_counts = Counter(c.get("status", "") for c in convos_all)
print(f"  {dict(status_counts)}")
