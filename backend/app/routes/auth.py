"""Authentication routes — register, login, current user."""

import os

from flask import Blueprint, request, jsonify, send_from_directory, current_app
from .. import models as db
from ..auth import hash_password, verify_password, create_token, decode_token, login_required, admin_required

auth_bp = Blueprint("auth", __name__)


@auth_bp.route("/api/auth/register", methods=["POST"])
def register():
    """Register a new user."""
    data = request.get_json()
    if not data:
        return jsonify({"error": "Missing request body"}), 400

    username = data.get("username", "").strip()
    email = data.get("email", "").strip()
    password = data.get("password", "")
    # Public registration must never be able to grant elevated access.
    # Faculty and administrator accounts are provisioned by an administrator.
    role = "student"

    if not username or not email or not password:
        return jsonify({"error": "Username, email, and password are required"}), 400
    if len(password) < 6:
        return jsonify({"error": "Password must be at least 6 characters"}), 400
    # Check duplicates — single generic message to avoid user enumeration
    # (don't reveal whether the username or the email already exists).
    existing = db.user_exists(username, email)
    if existing:
        return jsonify({"error": "An account with that username or email already exists"}), 409

    user = db.create_user(username, email, hash_password(password), role)
    token = create_token(user)

    return jsonify({
        "token": token,
        "user": {
            "id": user["id"],
            "username": user["username"],
            "email": user["email"],
            "role": user["role"],
        },
    }), 201


@auth_bp.route("/api/auth/login", methods=["POST"])
def login():
    """Login with username/email + password."""
    data = request.get_json()
    if not data:
        return jsonify({"error": "Missing request body"}), 400

    login_id = data.get("username", "").strip() or data.get("email", "").strip()
    password = data.get("password", "")

    if not login_id or not password:
        return jsonify({"error": "Username/email and password are required"}), 400

    user = db.find_user(login_id)
    if not user or not verify_password(password, user["password_hash"]):
        return jsonify({"error": "Invalid credentials"}), 401
    if not user["is_active"]:
        return jsonify({"error": "Account is deactivated"}), 403

    token = create_token(user)
    return jsonify({
        "token": token,
        "user": {
            "id": user["id"],
            "username": user["username"],
            "email": user["email"],
            "role": user["role"],
        },
    }), 200


@auth_bp.route("/api/users", methods=["GET"])
@admin_required
def get_users():
    """List all users (admin only)."""
    users = db.get_all_users()
    return jsonify({"users": users, "total": len(users)}), 200


@auth_bp.route("/api/users/<int:user_id>/role", methods=["PUT"])
@admin_required
def update_user_role(user_id):
    """Update a user's role (admin only)."""
    data = request.get_json()
    if not data or "role" not in data:
        return jsonify({"error": "role is required"}), 400
    new_role = data["role"]
    if new_role not in ("student", "faculty", "admin"):
        return jsonify({"error": "Invalid role"}), 400
    user = db.get_user_by_id(user_id)
    if not user:
        return jsonify({"error": "User not found"}), 404
    if user["id"] == request.current_user["id"] and new_role != "admin":
        return jsonify({"error": "You cannot remove your own admin role"}), 400
    db.update_user_role(user_id, new_role)
    return jsonify({"message": "Role updated", "user_id": user_id, "role": new_role}), 200


@auth_bp.route("/api/users/<int:user_id>/active", methods=["PUT"])
@admin_required
def update_user_active(user_id):
    """Activate or deactivate a user (admin only)."""
    data = request.get_json()
    if not data or "is_active" not in data:
        return jsonify({"error": "is_active is required"}), 400
    is_active = data["is_active"]
    if isinstance(is_active, str):
        is_active = is_active.lower() in ("true", "1", "yes")
    else:
        is_active = bool(is_active)
    user = db.get_user_by_id(user_id)
    if not user:
        return jsonify({"error": "User not found"}), 404
    if user["id"] == request.current_user["id"]:
        return jsonify({"error": "You cannot deactivate your own account"}), 400
    db.set_user_active(user_id, is_active)
    return jsonify({"message": "User status updated", "user_id": user_id, "is_active": is_active}), 200


@auth_bp.route("/api/auth/me", methods=["GET"])
@login_required
def me():
    """Get current user profile."""
    user = request.current_user
    return jsonify({
        "id": user["id"],
        "username": user["username"],
        "email": user["email"],
        "role": user["role"],
        "is_active": user["is_active"],
        "created_at": user["created_at"].isoformat() if user["created_at"] else None,
        "updated_at": user["updated_at"].isoformat() if user["updated_at"] else None,
    }), 200


@auth_bp.route("/api/theses/<int:thesis_id>/pdf", methods=["GET"])
def get_thesis_pdf(thesis_id):
    """Return the PDF file for a thesis (login required).

    Accepts the JWT via `Authorization: Bearer` header (preferred) or the
    `?token=` query param as a fallback so the app can open the PDF in an
    external browser tab, which can't set headers. Query-param tokens can
    end up in server logs — the token is short-lived (24h) and gets the
    exact same validation as the header.
    """
    user = None
    auth = request.headers.get("Authorization", "")
    raw_token = None
    if auth.startswith("Bearer "):
        raw_token = auth.split(" ", 1)[1]
    else:
        raw_token = request.args.get("token")
    if not raw_token:
        return jsonify({"error": "Missing Bearer token"}), 401
    try:
        payload = decode_token(raw_token)
        user = db.get_user_by_id(int(payload.get("sub")))
    except Exception:
        return jsonify({"error": "Invalid or expired token"}), 401
    if not user or not user.get("is_active"):
        return jsonify({"error": "User not found or inactive"}), 401

    thesis = db.get_thesis_by_id(thesis_id)
    if not thesis:
        return jsonify({"error": "Thesis not found"}), 404

    # Drafts/archived PDFs require admin/faculty; published visible to any login.
    if thesis.get("status") not in ("published", "approved"):
        if user.get("role") not in ("admin", "faculty"):
            return jsonify({"error": "Thesis not found"}), 404

    pdf_url = thesis.get("pdf_url")
    if not pdf_url:
        return jsonify({"error": "No PDF attached to this thesis"}), 404

    # pdf_url is stored as /api/uploads/<filename>, map to uploads directory
    # Strip the /api/uploads/ prefix to get the filename
    prefix = "/api/uploads/"
    if not pdf_url.startswith(prefix):
        return jsonify({"error": "Invalid pdf_url format"}), 500

    filename = pdf_url[len(prefix):]
    upload_dir = os.path.join(current_app.root_path, "uploads")

    # Security: flat filename only — no dirs, traversal, encodings, or drives.
    if (not filename or ".." in filename or filename.startswith(("/", "\\"))
            or "/" in filename or "\\" in filename or "%" in filename
            or ":" in filename):
        return jsonify({"error": "Invalid filename"}), 400

    file_path = os.path.join(upload_dir, filename)
    if not os.path.exists(file_path):
        return jsonify({"error": "PDF file not found on server"}), 404

    return send_from_directory(upload_dir, filename, mimetype="application/pdf", as_attachment=False)
