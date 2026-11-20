"""Meta routes -- programs, academic years, categories, keywords, authors, advisers."""

from fastapi import APIRouter, Depends, HTTPException, Body, Request, Response
from ..auth import admin_required, login_required, optional_user
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
    return author


@router.put("/api/authors/{author_id}", dependencies=[Depends(admin_required)])
def update_author(author_id: int, data: AuthorUpdateRequest = Body(default=None)):
    data = data.model_dump(exclude_unset=True) if data is not None else None
    existing = db.get_author_by_id(author_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Author not found")
    if not data:
        raise HTTPException(status_code=400, detail="Request body required")
    allowed = {"first_name", "last_name", "email", "middle_name"}
    updates = {k: v for k, v in data.items() if k in allowed}
    author = db.update_author(author_id, **updates)
    return author


@router.delete("/api/authors/{author_id}", dependencies=[Depends(admin_required)])
def delete_author(author_id: int):
    existing = db.get_author_by_id(author_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Author not found")
    db.delete_author(author_id)
    return {"message": "Author deleted", "id": author_id}


# -- Advisers CRUD --

@router.post("/api/advisers", status_code=201, dependencies=[Depends(admin_required)])
def create_adviser(data: AdviserCreateRequest = Body(default=None)):
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
    return adviser


@router.put("/api/advisers/{adviser_id}", dependencies=[Depends(admin_required)])
def update_adviser(adviser_id: int, data: AdviserUpdateRequest = Body(default=None)):
    data = data.model_dump(exclude_unset=True) if data is not None else None
    existing = db.get_adviser_by_id(adviser_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Adviser not found")
    if not data:
        raise HTTPException(status_code=400, detail="Request body required")
    allowed = {"first_name", "last_name", "email", "middle_name"}
    updates = {k: v for k, v in data.items() if k in allowed}
    adviser = db.update_adviser(adviser_id, **updates)
    return adviser


@router.delete("/api/advisers/{adviser_id}", dependencies=[Depends(admin_required)])
def delete_adviser(adviser_id: int):
    existing = db.get_adviser_by_id(adviser_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Adviser not found")
    db.delete_adviser(adviser_id)
    return {"message": "Adviser deleted", "id": adviser_id}


# -- Categories CRUD --

@router.post("/api/categories", status_code=201, dependencies=[Depends(admin_required)])
def create_category(data: CategoryCreateRequest = Body(default=None)):
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
    return category


@router.put("/api/categories/{category_id}", dependencies=[Depends(admin_required)])
def update_category(category_id: int, data: CategoryUpdateRequest = Body(default=None)):
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
    return category


@router.delete("/api/categories/{category_id}", dependencies=[Depends(admin_required)])
def delete_category(category_id: int):
    existing = db.get_category_by_id(category_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Category not found")
    db.delete_category(category_id)
    return {"message": "Category deleted", "id": category_id}


# -- Programs CRUD --

@router.post("/api/programs", status_code=201, dependencies=[Depends(admin_required)])
def create_program(data: ProgramCreateRequest = Body(default=None)):
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
    return program


@router.put("/api/programs/{program_id}", dependencies=[Depends(admin_required)])
def update_program(program_id: int, data: ProgramUpdateRequest = Body(default=None)):
    data = data.model_dump(exclude_unset=True) if data is not None else None
    existing = db.get_program_by_id(program_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Program not found")
    if not data:
        raise HTTPException(status_code=400, detail="Request body required")
    allowed = {"name", "code", "description"}
    updates = {k: v for k, v in data.items() if k in allowed}
    program = db.update_program(program_id, **updates)
    return program


@router.delete("/api/programs/{program_id}", dependencies=[Depends(admin_required)])
def delete_program(program_id: int):
    existing = db.get_program_by_id(program_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Program not found")
    db.delete_program(program_id)
    return {"message": "Program deleted", "id": program_id}


# -- Academic Years CRUD --

@router.post("/api/academic-years", status_code=201, dependencies=[Depends(admin_required)])
def create_academic_year(data: AcademicYearCreateRequest = Body(default=None)):
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
    return academic_year


@router.put("/api/academic-years/{year_id}", dependencies=[Depends(admin_required)])
def update_academic_year(year_id: int, data: AcademicYearUpdateRequest = Body(default=None)):
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
    return academic_year


@router.delete("/api/academic-years/{year_id}", dependencies=[Depends(admin_required)])
def delete_academic_year(year_id: int):
    existing = db.get_academic_year_by_id(year_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Academic year not found")
    db.delete_academic_year(year_id)
    return {"message": "Academic year deleted", "id": year_id}