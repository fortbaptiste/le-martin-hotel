"""
VisionIA x Le Martin Boutique Hotel
Script d'execution automatique des migrations Supabase
Execute tous les fichiers SQL via l'API Management Supabase
"""

import os
import sys
import json
import glob
import io
import time

# Fix Windows console encoding
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

import httpx

# ── Config ──
PROJECT_REF = "ssjwpvvundogojimpjrl"
SUPABASE_ACCESS_TOKEN = "sbp_ada375ab89a6435c49ca695890c7c6cade0d6174"
MANAGEMENT_API_URL = f"https://api.supabase.com/v1/projects/{PROJECT_REF}/database/query"


def execute_sql_via_management_api(sql: str, filename: str = ""):
    """
    Execute du SQL via l'API Management de Supabase.
    POST https://api.supabase.com/v1/projects/{ref}/database/query
    """
    headers = {
        "Authorization": f"Bearer {SUPABASE_ACCESS_TOKEN}",
        "Content-Type": "application/json",
    }

    try:
        response = httpx.post(
            MANAGEMENT_API_URL,
            headers=headers,
            json={"query": sql},
            timeout=120.0,
        )

        if response.status_code < 400:
            return True, response.text[:200]
        else:
            error_text = response.text[:300]
            return False, f"HTTP {response.status_code}: {error_text}"

    except httpx.TimeoutException:
        return False, "Timeout (120s)"
    except Exception as e:
        return False, str(e)[:200]


def main():
    print("=" * 60)
    print("  VisionIA x Le Martin Boutique Hotel")
    print("  Execution des migrations Supabase")
    print("  via Management API")
    print("=" * 60)
    print()

    # Trouver tous les fichiers SQL dans l'ordre (exclure ALL_MIGRATIONS.sql)
    sql_dir = os.path.dirname(os.path.abspath(__file__))
    sql_files = sorted([
        f for f in glob.glob(os.path.join(sql_dir, "*.sql"))
        if "ALL_MIGRATIONS" not in os.path.basename(f)
    ])

    if not sql_files:
        print("[ERREUR] Aucun fichier SQL trouve !")
        return

    print(f"[FILES] {len(sql_files)} fichiers SQL trouves :")
    for f in sql_files:
        print(f"   -> {os.path.basename(f)}")
    print()

    # Executer chaque fichier SQL
    print("[EXEC] Execution via Management API...")
    print(f"  Endpoint: {MANAGEMENT_API_URL}")
    print()

    success_count = 0
    error_count = 0

    for sql_file in sql_files:
        filename = os.path.basename(sql_file)
        print(f">> {filename}...")

        with open(sql_file, "r", encoding="utf-8") as f:
            sql_content = f.read()

        success, result = execute_sql_via_management_api(sql_content, filename)

        if success:
            # Verifier si le resultat contient une erreur SQL
            if '"error"' in result.lower() or '"message"' in result.lower():
                try:
                    data = json.loads(result[:500] if len(result) > 500 else result)
                    if isinstance(data, list) and len(data) > 0 and "error" in str(data[0]).lower():
                        print(f"  [WARN] {filename} - Reponse avec avertissement")
                    else:
                        print(f"  [OK] {filename}")
                        success_count += 1
                except json.JSONDecodeError:
                    print(f"  [OK] {filename}")
                    success_count += 1
            else:
                print(f"  [OK] {filename}")
                success_count += 1
        else:
            if "already exists" in result:
                print(f"  [SKIP] {filename} - Deja execute (tables existantes)")
                success_count += 1
            else:
                print(f"  [ERREUR] {filename}: {result[:150]}")
                error_count += 1

        # Pause entre les requetes pour eviter le rate limiting
        time.sleep(1)

    print()
    print("=" * 60)
    print(f"  Resultat: {success_count} OK / {error_count} erreurs")
    if error_count == 0:
        print("  Migration terminee avec succes !")
    else:
        print("  Certains fichiers ont echoue.")
        print("  Alternative: copier ALL_MIGRATIONS.sql dans SQL Editor")
    print("=" * 60)


if __name__ == "__main__":
    main()
