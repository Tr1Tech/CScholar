"""Meta routes -- programs, academic years, categories, keywords, authors, advisers."""

import psycopg
from fastapi import APIRouter, Depends, HTTPException, Body, Request, Response
from ..auth import admin_required, login_required, optional_user
from ..audit import log_security_event
from .. import models as db
from ..schemas import (
    AuthorCreateRequest,
    AuthorUpdateRequest,
    AdviserCreateRequest,
    AdviserUpdateRequest,
    CategoryCreateRequest,
    CategoryUpdateRequest,
    ProgramCreateRequest,
    ProgramUpdateRequest,
    AcademicYearCreateRequest,
    AcademicYearUpdateRequest,
)

router = APIRouter(tags=["Metadata"])


@router.get("/api/programs")
def list_programs():
    return db.list_programs()


@router.get("/api/academic-years")
def list_academic_years():
    return db.list_academic_years()


@router.get("/api/categories")
def list_categories():
    return db.list_categories()


@router.get("/api/keywords")
def list_keywords():
    return db.list_keywords()


@router.get("/api/authors")
def list_authors(request: Request, user=Depends(optional_user)):
    # Names are public (they appear on published studies); email is admin-only.
    can_see_email = bool(user and user.get("role") == "admin")
    return db.list_authors(include_email=can_see_email)


@router.get("/api/advisers")
def list_advisers(request: Request, user=Depends(optional_user)):
    # The email is the faculty-link key; only admin screens edit it.
    can_see_email = bool(user and user.get("role") == "admin")
    return db.list_advisers(include_email=can_see_email)


@router.get("/api/research-types")
def list_research_types():
    return ["Thesis", "Capstone"]


# -- Authors CRUD --

@router.post(
    "/api/authors",
    status_code=201,
    dependencies=[Depends(login_required)],
    openapi_extra={"x-required-roles": ["admin", "faculty"]},
)
def create_author(
    request: Request,
    response: Response,
    data: AuthorCreateRequest = Body(default=None),
):
    """Create a student author, or return the existing row.

    Faculty need this to credit a student who is not in the repository yet;
    without it the thesis form could only pick authors an admin had created
    first. The lookup keeps retries and parallel submissions idempotent. A
    matched row answers 200 instead of 201, with ``reused: true``.
    """
    role = request.state.current_user["role"]
    if role not in ("admin", "faculty"):
        raise HTTPException(status_code=403, detail="Admin or faculty access required")

    data = data.model_dump(exclude_unset=True) if data is not None else None
    if not data:
        raise HTTPException(status_code=400, detail="Request body required")
    first_name = (data.get("first_name") or "").strip()
    last_name = (data.get("last_name") or "").strip()
    middle_name = (data.get("middle_name") or "").strip() or None
    email = (data.get("email") or "").strip() or None
    if not first_name or not last_name:
        raise HTTPException(status_code=400, detail="first_name and last_name are required")

    existing = db.find_author_match(first_name, middle_name, last_name, email)
    if existing:
        response.status_code = 200
        existing["reused"] = True
        return existing

    author = db.create_author(
        first_name=first_name,
        last_name=last_name,
        email=email,
        middle_name=middle_name,
    )
    log_security_event(
        "author_created",
        actor=request.state.current_user,
        request=request,
        entity_type="author",
        entity_id=author["id"],
        summary=f"Created author {first_name} {last_name}",
    )
    return author


@router.put("/api/authors/{author_id}", dependencies=[Depends(admin_required)])
def update_author(author_id: int, request: Request, data: AuthorUpdateRequest = Body(default=None)):
    data = data.model_dump(exclude_unset=True) if data is not None else None
    existing = db.get_author_by_id(author_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Author not found")
    if not data:
        raise HTTPException(status_code=400, detail="Request body required")
    allowed = {"first_name", "last_name", "email", "middle_name"}
    updates = {k: v for k, v in data.items() if k in allowed}
    author = db.update_author(author_id, **updates)
    log_security_event(
        "author_updated",
        actor=request.state.current_user,
        request=request,
        entity_type="author",
        entity_id=author_id,
        summary=f"Updated author {existing.get('first_name', '')} {existing.get('last_name', '')}".strip(),
        details={"fields": sorted(updates.keys())},
    )
    return author


@router.delete("/api/authors/{author_id}", dependencies=[Depends(admin_required)])
def delete_author(author_id: int, request: Request):
    existing = db.get_author_by_id(author_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Author not found")
    # thesis_authors cascades, so the row would delete cleanly and take this
    # person's name off every study without a word. Block instead: fix the
    # spelling, or unlink the studies first.
    used = db.count_theses_for_author(author_id)
    if used:
        raise HTTPException(
            status_code=409,
            detail=(
                f"{used} {'study lists' if used == 1 else 'studies list'} "
                f"this author. Correct the name instead, or remove the author "
                f"from those studies first. No studies were changed."
            ),
        )
    db.delete_author(author_id)
    log_security_event(
        "author_deleted",
        actor=request.state.current_user,
        request=request,
        entity_type="author",
        entity_id=author_id,
        summary=(
            f"Deleted author {existing.get('first_name', '')} "
            f"{existing.get('last_name', '')}"
        ).strip(),
    )
    return {"message": "Author deleted", "id": author_id}


# -- Advisers CRUD --

@router.post("/api/advisers", status_code=201, dependencies=[Depends(admin_required)])
def create_adviser(request: Request, data: AdviserCreateRequest = Body(default=None)):
    data = data.model_dump(exclude_unset=True) if data is not None else None
    if not data:
        raise HTTPException(status_code=400, detail="Request body required")
    first_name = data.get("first_name")
    last_name = data.get("last_name")
    if not first_name or not last_name:
        raise HTTPException(status_code=400, detail="first_name and last_name are required")
    adviser = db.create_adviser(
        first_name=first_name,
        last_name=last_name,
        email=data.get("email"),
        middle_name=data.get("middle_name"),
    )
    log_security_event(
        "adviser_created",
        actor=request.state.current_user,
        request=request,
        entity_type="adviser",
        entity_id=adviser["id"],
        summary=f"Created adviser {first_name} {last_name}",
    )
    return adviser


@router.put("/api/advisers/{adviser_id}", dependencies=[Depends(admin_required)])
def update_adviser(adviser_id: int, request: Request, data: AdviserUpdateRequest = Body(default=None)):
    data = data.model_dump(exclude_unset=True) if data is not None else None
    existing = db.get_adviser_by_id(adviser_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Adviser not found")
    if not data:
        raise HTTPException(status_code=400, detail="Request body required")
    allowed = {"first_name", "last_name", "email", "middle_name"}
    updates = {k: v for k, v in data.items() if k in allowed}
    adviser = db.update_adviser(adviser_id, **updates)
    log_security_event(
        "adviser_updated",
        actor=request.state.current_user,
        request=request,
        entity_type="adviser",
        entity_id=adviser_id,
        summary=(
            f"Updated adviser {existing.get('first_name', '')} "
            f"{existing.get('last_name', '')}"
        ).strip(),
        details={"fields": sorted(updates.keys())},
    )
    return adviser


@router.delete("/api/advisers/{adviser_id}", dependencies=[Depends(admin_required)])
def delete_adviser(adviser_id: int, request: Request):
    existing = db.get_adviser_by_id(adviser_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Adviser not found")
    # Same cascade as authors: the studies survive, their adviser attribution
    # does not. Refuse rather than rewrite research records silently.
    used = db.count_theses_for_adviser(adviser_id)
    if used:
        raise HTTPException(
            status_code=409,
            detail=(
                f"{used} {'study names' if used == 1 else 'studies name'} "
                f"this adviser. Correct the name instead, or reassign those "
                f"studies first. No studies were changed."
            ),
        )
    db.delete_adviser(adviser_id)
    log_security_event(
        "adviser_deleted",
        actor=request.state.current_user,
        request=request,
        entity_type="adviser",
        entity_id=adviser_id,
        summary=(
            f"Deleted adviser {existing.get('first_name', '')} "
            f"{existing.get('last_name', '')}"
        ).strip(),
    )
    return {"message": "Adviser deleted", "id": adviser_id}


# -- Categories CRUD --

@router.post("/api/categories", status_code=201, dependencies=[Depends(admin_required)])
def create_category(request: Request, data: CategoryCreateRequest = Body(default=None)):
    data = data.model_dump(exclude_unset=True) if data is not None else None
    if not data:
        raise HTTPException(status_code=400, detail="Request body required")
    name = data.get("name")
    if not name:
        raise HTTPException(status_code=400, detail="name is required")
    try:
        category = db.create_category(
            name=name,
            description=data.get("description"),
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    log_security_event(
        "category_created",
        actor=request.state.current_user,
        request=request,
        entity_type="category",
        entity_id=category["id"],
        summary=f"Created category {name}",
    )
    return category


@router.put("/api/categories/{category_id}", dependencies=[Depends(admin_required)])
def update_category(category_id: int, request: Request, data: CategoryUpdateRequest = Body(default=None)):
    data = data.model_dump(exclude_unset=True) if data is not None else None
    existing = db.get_category_by_id(category_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Category not found")
    if not data:
        raise HTTPException(status_code=400, detail="Request body required")
    allowed = {"name", "description"}
    updates = {k: v for k, v in data.items() if k in allowed}
    try:
        category = db.update_category(category_id, **updates)
    except ValueError as exc:
        raise HTTPException(status_code=409, detail=str(exc))
    log_security_event(
        "category_updated",
        actor=request.state.current_user,
        request=request,
        entity_type="category",
        entity_id=category_id,
        summary=f"Updated category {existing.get('name', '')}",
        details={"fields": sorted(updates.keys())},
    )
    return category


@router.delete("/api/categories/{category_id}", dependencies=[Depends(admin_required)])
def delete_category(category_id: int, request: Request):
    existing = db.get_category_by_id(category_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Category not found")
    # This used to delete and report how many studies lost the tag. Those
    # studies are how the repository is organised, so the tag goes only when
    # no study relies on it.
    used = db.count_theses_for_category(category_id)
    if used:
        raise HTTPException(
            status_code=409,
            detail=(
                f"{used} {'study is' if used == 1 else 'studies are'} tagged "
                f"with this category. Remove the tag from those studies first. "
                f"No studies were changed."
            ),
        )
    db.delete_category(category_id)
    log_security_event(
        "category_deleted",
        actor=request.state.current_user,
        request=request,
        entity_type="category",
        entity_id=category_id,
        summary=f"Deleted category {existing.get('name', '')}",
    )
    return {"message": "Category deleted", "id": category_id}


# -- Programs CRUD --

@router.post("/api/programs", status_code=201, dependencies=[Depends(admin_required)])
def create_program(request: Request, data: ProgramCreateRequest = Body(default=None)):
    data = data.model_dump(exclude_unset=True) if data is not None else None
    if not data:
        raise HTTPException(status_code=400, detail="Request body required")
    name = data.get("name")
    if not name:
        raise HTTPException(status_code=400, detail="name is required")
    program = db.create_program(
        name=name,
        code=data.get("code"),
        description=data.get("description"),
    )
    log_security_event(
        "program_created",
        actor=request.state.current_user,
        request=request,
        entity_type="program",
        entity_id=program["id"],
        summary=f"Created program {name}",
    )
    return program


@router.put("/api/programs/{program_id}", dependencies=[Depends(admin_required)])
def update_program(program_id: int, request: Request, data: ProgramUpdateRequest = Body(default=None)):
    data = data.model_dump(exclude_unset=True) if data is not None else None
    existing = db.get_program_by_id(program_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Program not found")
    if not data:
        raise HTTPException(status_code=400, detail="Request body required")
    allowed = {"name", "code", "description"}
    updates = {k: v for k, v in data.items() if k in allowed}
    program = db.update_program(program_id, **updates)
    log_security_event(
        "program_updated",
        actor=request.state.current_user,
        request=request,
        entity_type="program",
        entity_id=program_id,
        summary=f"Updated program {existing.get('name', '')}",
        details={"fields": sorted(updates.keys())},
    )
    return program


@router.delete("/api/programs/{program_id}", dependencies=[Depends(admin_required)])
def delete_program(program_id: int, request: Request):
    existing = db.get_program_by_id(program_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Program not found")
    used = db.count_theses_for_program(program_id)
    if used:
        raise HTTPException(
            status_code=409,
            detail=(
                f"{used} {'study uses' if used == 1 else 'studies use'} "
                f"this program. Reassign them to another program, or keep "
                f"this one. No studies were deleted."
            ),
        )
    try:
        db.delete_program(program_id)
    except psycopg.errors.ForeignKeyViolation:
        raise HTTPException(
            status_code=409,
            detail=(
                "This program is still referenced by a study. Refresh the "
                "page and try again. No studies were deleted."
            ),
        )
    log_security_event(
        "program_deleted",
        actor=request.state.current_user,
        request=request,
        entity_type="program",
        entity_id=program_id,
        summary=f"Deleted program {existing.get('name', '')}",
    )
    return {"message": "Program deleted", "id": program_id}


# -- Academic Years CRUD --

@router.post("/api/academic-years", status_code=201, dependencies=[Depends(admin_required)])
def create_academic_year(request: Request, data: AcademicYearCreateRequest = Body(default=None)):
    data = data.model_dump(exclude_unset=True) if data is not None else None
    if not data:
        raise HTTPException(status_code=400, detail="Request body required")
    name = data.get("name")
    if not name:
        raise HTTPException(status_code=400, detail="name is required")
    is_active = data.get("is_active", True)
    if isinstance(is_active, str):
        is_active = is_active.lower() in ("true", "1", "yes")
    academic_year = db.create_academic_year(
        name=name,
        start_year=data.get("start_year"),
        end_year=data.get("end_year"),
        is_active=is_active,
    )
    log_security_event(
        "academic_year_created",
        actor=request.state.current_user,
        request=request,
        entity_type="academic_year",
        entity_id=academic_year["id"],
        summary=f"Created academic year {name}",
    )
    return academic_year


@router.put("/api/academic-years/{year_id}", dependencies=[Depends(admin_required)])
def update_academic_year(year_id: int, request: Request, data: AcademicYearUpdateRequest = Body(default=None)):
    data = data.model_dump(exclude_unset=True) if data is not None else None
    existing = db.get_academic_year_by_id(year_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Academic year not found")
    if not data:
        raise HTTPException(status_code=400, detail="Request body required")
    allowed = {"name", "start_year", "end_year", "is_active"}
    updates = {k: v for k, v in data.items() if k in allowed}
    if "is_active" in updates and isinstance(updates["is_active"], str):
        updates["is_active"] = updates["is_active"].lower() in ("true", "1", "yes")
    academic_year = db.update_academic_year(year_id, **updates)
    log_security_event(
        "academic_year_updated",
        actor=request.state.current_user,
        request=request,
        entity_type="academic_year",
        entity_id=year_id,
        summary=f"Updated academic year {existing.get('name', '')}",
        details={"fields": sorted(updates.keys())},
    )
    return academic_year


@router.delete("/api/academic-years/{year_id}", dependencies=[Depends(admin_required)])
def delete_academic_year(year_id: int, request: Request):
    existing = db.get_academic_year_by_id(year_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Academic year not found")
    used = db.count_theses_for_academic_year(year_id)
    if used:
        raise HTTPException(
            status_code=409,
            detail=(
                f"{used} {'study uses' if used == 1 else 'studies use'} "
                f"this academic year. Set it inactive instead, or reassign "
                f"the studies. No studies were deleted."
            ),
        )
    try:
        db.delete_academic_year(year_id)
    except psycopg.errors.ForeignKeyViolation:
        raise HTTPException(
            status_code=409,
            detail=(
                "This academic year is still referenced by a study. Refresh "
                "the page and try again. No studies were deleted."
            ),
        )
    log_security_event(
        "academic_year_deleted",
        actor=request.state.current_user,
        request=request,
        entity_type="academic_year",
        entity_id=year_id,
        summary=f"Deleted academic year {existing.get('name', '')}",
    )
    return {"message": "Academic year deleted", "id": year_id}