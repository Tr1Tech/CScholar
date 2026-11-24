"""Authentication routes -- register, login, current user."""

import os
from fastapi import APIRouter, Request, Depends, HTTPException, Body, Security
from fastapi.responses import FileResponse, RedirectResponse
from fastapi.security import HTTPAuthorizationCredentials
from .. import models as db
from ..auth import (
    hash_password,
    verify_password,
    create_token,
    decode_token,
    token_matches_user,
    login_required,
    admin_required,
    bearer_scheme,
)
from ..services.uploads import UPLOAD_URL_PREFIX, upload_filename, upload_path
from ..services import object_store
from ..schemas import (
    RegisterRequest,
    LoginRequest,
    CreateUserRequest,
    UpdateUserRequest,
    UpdateUserActiveRequest,
    ChangePasswordRequest,
)

router = APIRouter()


@router.post("/api/auth/register", status_code=201, tags=["Auth"])
def register(data: RegisterRequest = Body(default=None)):
    data = data.model_dump(exclude_unset=True) if data is not None else None
    if not data:
        raise HTTPException(status_code=400, detail="Missing request body")
    username = str(data.get("username", "")).strip()
    email = str(data.get("email", "")).strip()
    password = data.get("password", "")
    role = "student"

    if not username or not email or not password:
        raise HTTPException(status_code=400, detail="Username, email, and password are required")
    if len(password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")
    existing = db.user_exists(username, email)
    if existing:
        raise HTTPException(status_code=409, detail="An account with that username or email already exists")

    user = db.create_user(username, email, hash_password(password), role)
    token = create_token(user)
    return {
        "token": token,
        "user": {
            "id": user["id"],
            "username": user["username"],
            "email": user["email"],
            "role": user["role"],
        },
    }


@router.post("/api/auth/login", tags=["Auth"])
def login(data: LoginRequest = Body(default=None)):
    data = data.model_dump(exclude_unset=True) if data is not None else None
    if not data:
        raise HTTPException(status_code=400, detail="Missing request body")
    email = str(data.get("email", "")).strip()
    password = data.get("password", "")
    if not email or not password:
        raise HTTPException(status_code=400, detail="Email and password are required")
    user = db.get_user_by_email(email)
    if not user or not verify_password(password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    if not user["is_active"]:
        raise HTTPException(status_code=403, detail="Account is deactivated")
    token = create_token(user)
    return {
        "token": token,
        "user": {
            "id": user["id"],
            "username": user["username"],
            "email": user["email"],
            "role": user["role"],
        },
    }


@router.put("/api/auth/password", dependencies=[Depends(login_required)], tags=["Auth"])
def change_password(data: ChangePasswordRequest = Body(default=None), request: Request = None):
    """Change the signed-in user's password (any role).

    The current password is required so a borrowed session cannot silently
    take over the account. Existing JWTs stay valid until they expire.
    """
    data = data.model_dump(exclude_unset=True) if data is not None else None
    if not data:
        raise HTTPException(status_code=400, detail="Missing request body")
    current_password = data.get("current_password", "")
    new_password = data.get("new_password", "")
    if not current_password or not new_password:
        raise HTTPException(
            status_code=400,
            detail="Current and new password are required",
        )
    if len(new_password) < 6:
        raise HTTPException(
            status_code=400,
            detail="Password must be at least 6 characters",
        )
    user = request.state.current_user
    if not verify_password(current_password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Current password is incorrect")
    if verify_password(new_password, user["password_hash"]):
        raise HTTPException(
            status_code=400,
            detail="New password must be different from the current password",
        )
    db.set_user_password(user["id"], hash_password(new_password))
    # Rotating the hash revokes every older token. Mint a fresh one for this
    # device so the person who just changed the password stays signed in.
    updated = db.get_user_by_id(user["id"])
    return {"message": "Password updated", "token": create_token(updated)}


@router.get("/api/users", dependencies=[Depends(admin_required)], tags=["Users"])
def get_users():
    users = db.get_all_users()
    return {"users": users, "total": len(users)}


@router.post("/api/users", status_code=201, dependencies=[Depends(admin_required)], tags=["Users"])
def admin_create_user(data: CreateUserRequest = Body(default=None)):
    data = data.model_dump(exclude_unset=True) if data is not None else None
    if not data:
        raise HTTPException(status_code=400, detail="Missing request body")
    username = str(data.get("username", "")).strip()
    email = str(data.get("email", "")).strip()
    password = str(data.get("password", ""))
    role = str(data.get("role", "student")).strip().lower()
    if not username or not email or not password:
        raise HTTPException(status_code=400, detail="Username, email, and password are required")
    if len(password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")
    if role not in ("student", "faculty", "admin"):
        raise HTTPException(status_code=400, detail="Invalid role")
    existing = db.user_exists(username, email)
    if existing:
        for row in existing:
            if row[0] == username:
                raise HTTPException(status_code=409, detail="Username already taken")
            if row[1] == email.lower():
                raise HTTPException(status_code=409, detail="Email already registered")
    user = db.create_user(username, email, hash_password(password), role)
    return {
        "message": "User created",
        "user": {
            "id": user["id"],
            "username": user["username"],
            "email": user["email"],
            "role": user["role"],
        },
    }


@router.put("/api/users/{user_id}", dependencies=[Depends(admin_required)], tags=["Users"])
def update_user(user_id: int, data: UpdateUserRequest = Body(default=None), request: Request = None):
    data = data.model_dump(exclude_unset=True) if data is not None else None
    user = db.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if not data:
        raise HTTPException(status_code=400, detail="Missing request body")
    username = data.get("username", None)
    email = data.get("email", None)
    new_role = data.get("role", None)
    if username is None and email is None and new_role is None:
        raise HTTPException(status_code=400, detail="Nothing editable in request body")
    if username is not None:
        username = username.strip()
        if not username:
            raise HTTPException(status_code=400, detail="Username cannot be empty")
        clash = db.get_user_by_username(username)
        if clash and clash["id"] != user_id:
            raise HTTPException(status_code=409, detail="Username is already taken")
    if email is not None:
        email = email.strip()
        if not email or "@" not in email:
            raise HTTPException(status_code=400, detail="Valid email is required")
        clash = db.get_user_by_email(email)
        if clash and clash["id"] != user_id:
            raise HTTPException(status_code=409, detail="Email is already taken")
    if new_role is not None:
        if new_role not in ("student", "faculty", "admin"):
            raise HTTPException(status_code=400, detail="Invalid role")
        current_user = getattr(request.state, "current_user", None) if request else None
        if current_user and user["id"] == current_user["id"] and new_role != "admin":
            raise HTTPException(status_code=400, detail="You cannot remove your own admin role")
    updated = db.update_user(user_id, username=username, email=email, role=new_role)
    return {
        "message": "User updated",
        "user": {
            "id": updated["id"],
            "username": updated["username"],
            "email": updated["email"],
            "role": updated["role"],
            "is_active": updated["is_active"],
        },
    }


@router.put("/api/users/{user_id}/active", dependencies=[Depends(admin_required)], tags=["Users"])
def update_user_active(user_id: int, data: UpdateUserActiveRequest = Body(default=None), request: Request = None):
    data = data.model_dump(exclude_unset=True) if data is not None else None
    if not data or "is_active" not in data:
        raise HTTPException(status_code=400, detail="is_active is required")
    is_active = data["is_active"]
    if isinstance(is_active, str):
        is_active = is_active.lower() in ("true", "1", "yes")
    else:
        is_active = bool(is_active)
    user = db.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    current_user = getattr(request.state, "current_user", None) if request else None
    if current_user and user["id"] == current_user["id"]:
        raise HTTPException(status_code=400, detail="You cannot deactivate your own account")
    db.set_user_active(user_id, is_active)
    return {"message": "User status updated", "user_id": user_id, "is_active": is_active}


@router.get("/api/auth/me", dependencies=[Depends(login_required)], tags=["Auth"])
def me(request: Request):
    user = request.state.current_user
    return {
        "id": user["id"],
        "username": user["username"],
        "email": user["email"],
        "role": user["role"],
        "is_active": user["is_active"],
        "created_at": user["created_at"].isoformat() if user["created_at"] else None,
        "updated_at": user["updated_at"].isoformat() if user["updated_at"] else None,
    }


@router.get("/api/theses/{thesis_id}/pdf", tags=["Theses"])
def get_thesis_pdf(
    thesis_id: int,
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Security(bearer_scheme),
):
    user = None
    auth = request.headers.get("Authorization", "")
    raw_token = None
    if auth.startswith("Bearer "):
        raw_token = auth.split(" ", 1)[1]
    else:
        raw_token = request.query_params.get("token")
    if not raw_token:
        raise HTTPException(status_code=401, detail="Missing Bearer token")
    try:
        payload = decode_token(raw_token)
        user = db.get_user_by_id(int(payload.get("sub")))
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    if not user or not user.get("is_active"):
        raise HTTPException(status_code=401, detail="User not found or inactive")
    if not token_matches_user(payload, user):
        raise HTTPException(
            status_code=401,
            detail="Session expired; please sign in again",
        )

    thesis = db.get_thesis_by_id(thesis_id)
    if not thesis:
        raise HTTPException(status_code=404, detail="Thesis not found")
    if thesis.get("status") != "published" and not db.user_can_view_unpublished(thesis, user):
        raise HTTPException(status_code=404, detail="Thesis not found")

    pdf_url = thesis.get("pdf_url")
    if not pdf_url:
        raise HTTPException(status_code=404, detail="No PDF attached to this thesis")
    if not pdf_url.startswith(UPLOAD_URL_PREFIX):
        raise HTTPException(status_code=500, detail="Invalid pdf_url format")
    if upload_filename(pdf_url) is None:
        raise HTTPException(status_code=400, detail="Invalid filename")
    file_path = upload_path(pdf_url)
    if file_path and os.path.exists(file_path):
        return FileResponse(file_path, media_type="application/pdf")

    # Free hosts have no persistent disk: the file may live in object storage
    # while this instance has never seen it. The auth check above is unchanged;
    # the redirect target is a short-lived presigned URL for this one object.
    stored_name = upload_filename(pdf_url)
    if stored_name and object_store.enabled():
        signed = object_store.presigned_get(stored_name)
        if signed:
            return RedirectResponse(signed, status_code=307)

    raise HTTPException(status_code=404, detail="PDF file not found on server")