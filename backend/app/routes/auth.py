"""Authentication routes — register, login, current user."""

from flask import Blueprint, request, jsonify
from .. import models as db
from ..auth import hash_password, verify_password, create_token, login_required

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
    # Check duplicates
    existing = db.user_exists(username, email)
    if existing:
        for row in existing:
            if row[0] == username:
                return jsonify({"error": "Username already taken"}), 409
            if row[1] == email.lower():
                return jsonify({"error": "Email already registered"}), 409

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
