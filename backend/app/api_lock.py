"""Freeze the documented API surface.

The CScholar API is final: the operations listed in
``backend/api_contract.json`` are the complete public surface. This module is
the single comparison used by both the startup guard (``app/__init__.py``) and
``scripts/check_api_contract.py``, so an endpoint can never be added, removed,
or re-tagged without the contract being updated deliberately.

``/docs`` and ``/swagger.json`` are presentation routes and are excluded from
the OpenAPI schema (``include_in_schema=False``), so they are not part of the
frozen surface.
"""

import json
from pathlib import Path

CONTRACT_PATH = Path(__file__).resolve().parents[1] / "api_contract.json"

_METHODS = ("get", "post", "put", "patch", "delete")

#: Fields compared for every operation. Adding a field here makes that drift
#: a lock failure, so keep it to what actually defines the API surface.
_COMPARED = ("tags", "roles", "auth")


def _roles(operation):
    roles = operation.get("x-required-roles") or []
    return sorted(str(role).strip().lower() for role in roles if str(role).strip())


def snapshot(schema):
    """Return ``{(METHOD, path): {"tags": [...], "roles": [...], "auth": bool}}``."""
    operations = {}
    for path, methods in (schema.get("paths") or {}).items():
        if not isinstance(methods, dict):
            continue
        for method, operation in methods.items():
            if method.lower() not in _METHODS or not isinstance(operation, dict):
                continue
            operations[(str(method).upper(), path)] = {
                "tags": list(operation.get("tags") or []),
                "roles": _roles(operation),
                # True when the operation declares bearer auth, i.e. Swagger UI
                # draws the padlock. Catches a route quietly becoming public.
                "auth": bool(operation.get("security")),
            }
    return operations


def load_contract(path=CONTRACT_PATH):
    """Read the frozen contract, or ``None`` when the file is absent."""
    path = Path(path)
    if not path.is_file():
        return None
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def diff(schema, contract):
    """Compare a generated schema against the frozen contract.

    Returns ``{"added": [...], "removed": [...], "changed": [...]}`` where the
    keys are ``(METHOD, path)`` tuples. An empty result means the surface is
    exactly the locked one.
    """
    expected = {
        (str(op["method"]).upper(), str(op["path"])): op
        for op in contract.get("operations", [])
    }
    actual = snapshot(schema)

    added = sorted(set(actual) - set(expected))
    removed = sorted(set(expected) - set(actual))
    changed = []
    for key in sorted(set(actual) & set(expected)):
        for field in _COMPARED:
            if actual[key].get(field) != expected[key].get(field):
                changed.append(
                    {
                        "operation": key,
                        "field": field,
                        "expected": expected[key].get(field),
                        "actual": actual[key].get(field),
                    }
                )
    return {"added": added, "removed": removed, "changed": changed}


def format_diff(result):
    """Human-readable lines explaining a non-empty diff."""
    lines = []
    for method, path in result["added"]:
        lines.append(f"ADDED    {method} {path}")
    for method, path in result["removed"]:
        lines.append(f"REMOVED  {method} {path}")
    for item in result["changed"]:
        method, path = item["operation"]
        lines.append(
            f"CHANGED  {method} {path} {item['field']}: "
            f"{item['expected']!r} -> {item['actual']!r}"
        )
    return lines


def assert_surface_locked(app, path=CONTRACT_PATH):
    """Raise ``RuntimeError`` when the live routes drift from the contract.

    Called from the app lifespan: a drifted route set stops the server with an
    explanation instead of quietly publishing a different Swagger UI.
    """
    contract = load_contract(path)
    if contract is None:
        # Deployments without the frozen file stay runnable; the checker script
        # still reports the missing lock.
        return None
    result = diff(app.openapi(), contract)
    if any(result.values()):
        details = "\n".join(format_diff(result))
        raise RuntimeError(
            "The CScholar API surface is locked and no longer matches "
            f"{Path(path).name}:\n{details}\n"
            "The documented endpoint list is final. To change it deliberately, "
            "get owner approval and regenerate the contract with:\n"
            "    venv\\Scripts\\python scripts\\check_api_contract.py --write"
        )
    return result
