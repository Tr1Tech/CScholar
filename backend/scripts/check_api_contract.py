"""Verify that the documented API surface still matches the frozen contract.

Every operation in the Swagger UI is listed in ``backend/api_contract.json``.
This checker fails when an endpoint is added, removed, re-tagged, or changes
which roles may call it. Run it after touching any file in ``app/routes/``.

Usage (from ``backend/``):

    venv\\Scripts\\python scripts\\check_api_contract.py

Exit codes: 0 = locked surface intact, 1 = drift, 2 = contract missing/broken.

Regenerating the contract is an owner decision, not a routine step:

    venv\\Scripts\\python scripts\\check_api_contract.py --write
"""

import argparse
import json
import sys
from datetime import date
from pathlib import Path

BACKEND = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BACKEND))

from app import app  # noqa: E402
from app.api_lock import (  # noqa: E402
    CONTRACT_PATH,
    diff,
    format_diff,
    snapshot,
)


def build_contract():
    schema = app.openapi()
    operations = snapshot(schema)
    entries = [
        {
            "method": method,
            "path": path,
            "tags": details["tags"],
            "roles": details["roles"],
            "auth": details["auth"],
        }
        for (method, path), details in sorted(operations.items())
    ]
    return {
        "title": app.title,
        "version": app.version,
        "locked_on": date.today().isoformat(),
        "note": (
            "Frozen API surface. The Swagger UI is final: do not add endpoints. "
            "Regenerate only with explicit owner approval."
        ),
        "operation_count": len(entries),
        "operations": entries,
    }


def main(argv=None):
    parser = argparse.ArgumentParser(description="Check the locked API surface.")
    parser.add_argument(
        "--write",
        action="store_true",
        help="Rewrite api_contract.json from the current routes (owner approval required).",
    )
    parser.add_argument("--quiet", action="store_true", help="Only print failures.")
    args = parser.parse_args(argv)

    if args.write:
        contract = build_contract()
        CONTRACT_PATH.write_text(
            json.dumps(contract, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        print(
            f"Wrote {CONTRACT_PATH.name}: {contract['operation_count']} operations "
            f"locked on {contract['locked_on']}."
        )
        return 0

    if not CONTRACT_PATH.is_file():
        print(f"FAIL  {CONTRACT_PATH.name} is missing; the API is not locked.")
        return 1

    try:
        contract = json.loads(CONTRACT_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"FAIL  cannot read {CONTRACT_PATH.name}: {exc}")
        return 2

    result = diff(app.openapi(), contract)
    if any(result.values()):
        print(
            f"FAIL  API surface drifted from {CONTRACT_PATH.name} "
            f"({contract.get('operation_count', '?')} locked operations):"
        )
        for line in format_diff(result):
            print("  " + line)
        print(
            "The documented endpoint list is final. If the change is approved, "
            "regenerate with --write."
        )
        return 1

    if not args.quiet:
        print(
            f"PASS  {contract.get('operation_count', 0)} operations match "
            f"{CONTRACT_PATH.name} (locked {contract.get('locked_on', 'unknown')})."
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
