"""Authentication routes — register, login, current user."""

from flask import Blueprint, request, jsonify, send_from_directory, current_app, os as flask_os
from .. import models as db
from ..auth import hash_password, verify_password, create_token, login_required, admin_required

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
    db.update_user_role(user_id, new_role)
    return jsonify({"message": "Role updated", "user_id": user_id, "role": new_role}), 200


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
@login_required
def get_thesis_pdf(thesis_id):
    """Return the PDF file for a thesis."""
    thesis = db.get_thesis_by_id(thesis_id)
    if not thesis:
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
    upload_dir = flask_os.path.join(current_app.root_path, "uploads")

    # Security: ensure filename doesn't traverse directories
    if ".." in filename or filename.startswith("/"):
        return jsonify({"error": "Invalid filename"}), 400

    file_path = flask_os.path.join(upload_dir, filename)
    if not flask_os.path.exists(file_path):
        return jsonify({"error": "PDF file not found on server"}), 404

    return send_from_directory(upload_dir, filename, mimetype="application/pdf", as_attachment=False)
