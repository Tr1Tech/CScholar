"""Authentication utilities -- password hashing + JWT tokens (FastAPI)."""

import datetime
import functools
import os
from fastapi import Request, HTTPException, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import bcrypt
import jwt
from .config import Config
from .models import get_user_by_id


# -- Password hashing ------------------------------------------------------

def hash_password(plain: str) -> str:
    """Hash a plaintext password with bcrypt."""
    return bcrypt.hashpw(plain.encode(), bcrypt.gensalt()).decode()


def verify_password(plain: str, hashed: str) -> bool:
    """Verify a plaintext password against a bcrypt hash."""
    return bcrypt.checkpw(plain.encode(), hashed.encode())


# -- JWT tokens ------------------------------------------------------------

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
    return jwt.encode(payload, Config.SECRET_KEY, algorithm="HS256")


def decode_token(token: str) -> dict:
    """Decode and verify a JWT token. Raises HTTPException if invalid."""
    try:
        return jwt.decode(token, Config.SECRET_KEY, algorithms=["HS256"])
    except (jwt.ExpiredSignatureError, jwt.InvalidTokenError) as e:
        raise HTTPException(status_code=401, detail="Invalid or expired token") from e


# -- Auth dependency helpers ----------------------------------------------

# Declares the JWT bearer scheme in OpenAPI so Swagger UI shows "Authorize".
bearer_scheme = HTTPBearer(auto_error=False, bearerFormat="JWT")


def _resolve_user(request: Request):
    """Read and validate the Bearer token from the request headers."""
    auth = request.headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing Bearer token")
    token = auth.split(" ", 1)[1]
    try:
        payload = decode_token(token)
        user_id = int(payload.get("sub"))
    except HTTPException:
        raise
    except (KeyError, TypeError, ValueError):
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    user = get_user_by_id(user_id)
    if not user or not user.get("is_active"):
        raise HTTPException(status_code=401, detail="User not found or inactive")
    request.state.current_user = user
    return user


def get_current_user(
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Security(bearer_scheme),
):
    return _resolve_user(request)


def login_required(
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Security(bearer_scheme),
):
    return _resolve_user(request)


def admin_required(
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Security(bearer_scheme),
):
    user = _resolve_user(request)
    if user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    return user