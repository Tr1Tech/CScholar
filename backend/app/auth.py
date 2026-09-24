"""Authentication utilities — password hashing + JWT tokens."""

import datetime
import functools
from flask import request, jsonify, current_app
from werkzeug.exceptions import Unauthorized
import bcrypt
import jwt
from .models import get_user_by_id


# ── Password hashing ──────────────────────────────────────────────────────

def hash_password(plain: str) -> str:
    """Hash a plaintext password with bcrypt."""
    return bcrypt.hashpw(plain.encode(), bcrypt.gensalt()).decode()


def verify_password(plain: str, hashed: str) -> bool:
    """Verify a plaintext password against a bcrypt hash."""
    return bcrypt.checkpw(plain.encode(), hashed.encode())


# ── JWT tokens ────────────────────────────────────────────────────────────

def create_token(user) -> str:
    """Create a JWT access token for a user."""
    now = datetime.datetime.now(datetime.timezone.utc)
    payload = {
        "sub": str(user["id"]),
        "username": user["username"],
        "email": user["email"],
        "role": user["role"],
        "exp": now + datetime.timedelta(hours=24),
        "iat": now,
    }
    return jwt.encode(payload, current_app.config["SECRET_KEY"], algorithm="HS256")


def decode_token(token: str) -> dict:
    """Decode and verify a JWT token. Raises Unauthorized if invalid."""
    try:
        return jwt.decode(token, current_app.config["SECRET_KEY"], algorithms=["HS256"])
    except (jwt.ExpiredSignatureError, jwt.InvalidTokenError) as e:
        raise Unauthorized("Invalid or expired token") from e


# ── Auth decorator for protected routes ───────────────────────────────────

def login_required(fn):
    """Decorator that requires a valid JWT token."""
    @functools.wraps(fn)
    def wrapper(*args, **kwargs):
        auth = request.headers.get("Authorization", "")
        if not auth.startswith("Bearer "):
            return jsonify({"error": "Missing Bearer token"}), 401
        token = auth.split(" ", 1)[1]
        try:
            payload = decode_token(token)
            user_id = int(payload.get("sub"))
        except Unauthorized:
            return jsonify({"error": "Invalid or expired token"}), 401
        except (KeyError, TypeError, ValueError):
            return jsonify({"error": "Invalid or expired token"}), 401
        user = get_user_by_id(user_id)
        if not user or not user["is_active"]:
            return jsonify({"error": "User not found or inactive"}), 401
        request.current_user = user
        return fn(*args, **kwargs)
    return wrapper


def admin_required(fn):
    """Decorator that requires admin role."""
    @functools.wraps(fn)
    def wrapper(*args, **kwargs):
        auth = request.headers.get("Authorization", "")
        if not auth.startswith("Bearer "):
            return jsonify({"error": "Missing Bearer token"}), 401
        token = auth.split(" ", 1)[1]
        try:
            payload = decode_token(token)
            user_id = int(payload.get("sub"))
        except Unauthorized:
            return jsonify({"error": "Invalid or expired token"}), 401
        except (KeyError, TypeError, ValueError):
            return jsonify({"error": "Invalid or expired token"}), 401
        user = get_user_by_id(user_id)
        if not user or not user["is_active"]:
            return jsonify({"error": "User not found or inactive"}), 401
        if user["role"] != "admin":
            return jsonify({"error": "Admin access required"}), 403
        request.current_user = user
        return fn(*args, **kwargs)
    return wrapper
