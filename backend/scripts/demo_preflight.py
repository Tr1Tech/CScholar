"""Pre-demo health check for the CScholar defense build.

Runs the P0 acceptance checks end to end, so the demo machine is verified
before anyone presents. Exits non-zero on the first failed expectation and
prints every check it ran.

Usage (from backend/, with the API already running):
    venv\\Scripts\\python scripts\\demo_preflight.py

Override the API base with CSCHOLAR_API, e.g. http://127.0.0.1:5000.
"""

import json
import os
import sys
import urllib.request
from pathlib import Path

BACKEND = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BACKEND))

from app import models as db  # noqa: E402
from app.auth import create_token  # noqa: E402
from app.config import UPLOAD_DIR  # noqa: E402

BASE = os.getenv("CSCHOLAR_API", "http://127.0.0.1:5000").rstrip("/")
VISTAL_THESES = {48, 50, 54, 56}

failures = []


def check(label, ok, detail=""):
    print(("PASS  " if ok else "FAIL  ") + label + (f" - {detail}" if detail else ""))
    if not ok:
        failures.append(label)


def get(path):
    with urllib.request.urlopen(BASE + path, timeout=20) as response:
        return json.load(response)


def main():
    # 1. The API is the current build, not a stale server process.
    try:
        types = get("/api/research-types")
        check("API responds", True, f"{BASE} -> {types}")
    except Exception as exc:  # noqa: BLE001 - the report is the point
        check("API responds", False, str(exc))
        print("\nStart it from backend/: venv\\Scripts\\python run.py")
        return 1

    # 2. Public payloads carry no contact emails (P0 3.4).
    advisers = get("/api/advisers")
    authors = get("/api/authors")
    check(
        "anonymous /api/advisers hides email",
        all("email" not in row for row in advisers),
        f"{len(advisers)} advisers",
    )
    check(
        "anonymous /api/authors hides email",
        all("email" not in row for row in authors),
        f"{len(authors)} authors",
    )

    # 3. The corpus is published and complete.
    published = get("/api/theses?status=published&per_page=100")
    rows = published["theses"]
    check("19 published theses", len(rows) == 19 and published["total"] == 19)

    incomplete = [
        row["id"]
        for row in rows
        if not row.get("title")
        or not row.get("abstract")
        or not row.get("authors")
        or not row.get("advisers")
    ]
    check("every record has title, abstract, authors, adviser", not incomplete, str(incomplete))

    missing_chunks = [
        row["id"] for row in rows if db.count_thesis_embedding_chunks(row["id"]) == 0
    ]
    check("every record has embedding chunks", not missing_chunks, str(missing_chunks))

    missing_pdfs = []
    for row in rows:
        stored = db.get_thesis_file(row["id"])
        # file_path is the served URL (/api/uploads/<stored name>); the stored
        # blob uses that name, not the original upload filename.
        stored_name = os.path.basename((stored or {}).get("file_path") or "")
        if not stored_name or not os.path.exists(
            os.path.join(UPLOAD_DIR, stored_name)
        ):
            missing_pdfs.append(row["id"])
    check("every record has a PDF on disk", not missing_pdfs, str(missing_pdfs))

    # 4. Published PDFs actually open through the API with a student token.
    student = db.get_user_by_username("demostudent")
    if not student:
        check("demostudent exists for the PDF check", False)
    else:
        sample = [rows[0]["id"], rows[len(rows) // 2]["id"], rows[-1]["id"]]
        opened = []
        token = create_token(student)
        for thesis_id in sample:
            request = urllib.request.Request(
                f"{BASE}/api/theses/{thesis_id}/pdf",
                headers={"Authorization": f"Bearer {token}"},
            )
            with urllib.request.urlopen(request, timeout=30) as response:
                opened.append(
                    (thesis_id, response.status, response.read(5).startswith(b"%PDF-"))
                )
        check(
            "published PDFs open with a student token",
            all(status == 200 and is_pdf for _, status, is_pdf in opened),
            str(opened),
        )

    # 5. Adviser-aware search (P0 3.5).
    vistal = get("/api/theses?q=Vistal&per_page=50")
    found = {row["id"] for row in vistal["theses"]}
    check(
        "q=Vistal returns all four advised theses",
        found == VISTAL_THESES,
        f"found={sorted(found)}",
    )
    check(
        "anonymous search never shows a draft",
        all(row["status"] == "published" for row in vistal["theses"]),
    )

    # 6. The demo faculty login resolves to the seeded advisee set.
    conn = db.get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT u.username, a.id, "
                "  (SELECT COUNT(*) FROM thesis_advisers ta WHERE ta.adviser_id = a.id), "
                "  (SELECT COUNT(DISTINCT th.author_id) FROM thesis_authors th "
                "     JOIN thesis_advisers ta ON ta.thesis_id = th.thesis_id "
                "    WHERE ta.adviser_id = a.id) "
                "FROM users u JOIN advisers a ON LOWER(a.email) = LOWER(u.email) "
                "WHERE u.username = 'demo_faculty'"
            )
            row = cur.fetchone()
    finally:
        db.put_conn(conn)

    if not row:
        check("demo_faculty is linked to an adviser", False, "no match")
    else:
        _, adviser_id, theses, advisees = row
        check(
            "demo_faculty adviser link",
            adviser_id and theses == 4 and advisees == 12,
            f"theses={theses} advisees={advisees}",
        )

    print()
    if failures:
        print(f"{len(failures)} check(s) failed: {', '.join(failures)}")
        return 1
    print("All checks passed. Demo build is ready.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
