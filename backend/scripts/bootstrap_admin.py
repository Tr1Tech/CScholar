"""Create the first administrator account on a fresh CScholar database.

Why this exists: ``POST /api/auth/register`` always creates a student, and only
an admin can create users. A database with zero users therefore has no path to
its first admin through the API, which locks everyone out permanently.

Usage (from ``backend/``):

    venv\\Scripts\\python scripts\\bootstrap_admin.py
    venv\\Scripts\\python scripts\\bootstrap_admin.py --email me@csu.edu.ph --username me
    venv\\Scripts\\python scripts\\bootstrap_admin.py --password "..." --promote

Without ``--password`` the password is read from ``BOOTSTRAP_ADMIN_PASSWORD``,
or generated randomly and printed once. Re-running is safe: an existing admin is
left unchanged.
"""

import argparse
import os
import secrets
import sys
from pathlib import Path

import bcrypt
import psycopg
from dotenv import load_dotenv

BACKEND_DIR = Path(__file__).resolve().parents[1]
load_dotenv(BACKEND_DIR / ".env")

DEFAULT_EMAIL = "admin@csu.edu.ph"
DEFAULT_USERNAME = "admin"


def generate_password(length=20):
    alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%"
    return "".join(secrets.choice(alphabet) for _ in range(length))


def hash_password(plain):
    return bcrypt.hashpw(plain.encode(), bcrypt.gensalt()).decode()


def connect():
    url = os.getenv("DATABASE_URL")
    if not url:
        sys.exit("DATABASE_URL is not set. Add it to backend/.env first.")
    conn = psycopg.connect(url)
    with conn.cursor() as cur:
        cur.execute("SET search_path TO ceit_repo")
    conn.commit()
    return conn


def main():
    parser = argparse.ArgumentParser(description="Create or promote the first admin.")
    parser.add_argument("--email", default=DEFAULT_EMAIL)
    parser.add_argument("--username", default=DEFAULT_USERNAME)
    parser.add_argument("--password", default=os.getenv("BOOTSTRAP_ADMIN_PASSWORD"))
    parser.add_argument(
        "--promote",
        action="store_true",
        help="If the email already exists with another role, promote it to admin.",
    )
    args = parser.parse_args()

    password = args.password or generate_password()
    generated = args.password is None

    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, username, role FROM users WHERE lower(email) = lower(%s)",
                (args.email,),
            )
            existing = cur.fetchone()

            if existing:
                user_id, username, role = existing
                if role == "admin":
                    print(f"Admin already exists: {username} <{args.email}> (id {user_id})")
                    print("Nothing to do.")
                    return
                if not args.promote:
                    print(
                        f"User {username} <{args.email}> already exists with role '{role}'.\n"
                        "Re-run with --promote to make it an admin."
                    )
                    sys.exit(2)
                cur.execute(
                    "UPDATE users SET role = 'admin', updated_at = NOW() WHERE id = %s",
                    (user_id,),
                )
                conn.commit()
                print(f"Promoted {username} <{args.email}> (id {user_id}) to admin.")
                return

            cur.execute(
                "INSERT INTO users (username, email, password_hash, role, is_active) "
                "VALUES (%s, %s, %s, 'admin', TRUE) RETURNING id",
                (args.username, args.email, hash_password(password)),
            )
            user_id = cur.fetchone()[0]
        conn.commit()

    print(f"Created admin #{user_id}: {args.username} <{args.email}>")
    if generated:
        print(f"Temporary password: {password}")
        print("Change it after first login, and do not commit it anywhere.")
    else:
        print("Password set from the value you supplied.")


if __name__ == "__main__":
    main()
