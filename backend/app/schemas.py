"""Pydantic request models.

Fields are intentionally optional here: the routes keep their existing manual
validation and error messages, while FastAPI uses these models to generate
useful Swagger UI documentation (field names + examples instead of
`additionalProp1`).
"""

from pydantic import BaseModel, ConfigDict, Field


class _Base(BaseModel):
    model_config = ConfigDict(extra="ignore")


# -- Auth / Users ---------------------------------------------------------

class RegisterRequest(_Base):
    model_config = ConfigDict(extra="ignore", json_schema_extra={
        "example": {"username": "demostudent", "email": "demo@csu.edu.ph", "password": "demo1234"}
    })
    username: str | None = None
    email: str | None = None
    password: str | None = None


class LoginRequest(_Base):
    model_config = ConfigDict(extra="ignore", json_schema_extra={
        "example": {"username": "admin1", "password": "admin123"}
    })
    username: str | None = None
    email: str | None = None
    password: str | None = None


class CreateUserRequest(_Base):
    model_config = ConfigDict(extra="ignore", json_schema_extra={
        "example": {"username": "faculty2", "email": "faculty2@csu.edu.ph", "password": "secret123", "role": "faculty"}
    })
    username: str | None = None
    email: str | None = None
    password: str | None = None
    role: str | None = None


class UpdateUserRequest(_Base):
    model_config = ConfigDict(extra="ignore", json_schema_extra={
        "example": {"role": "faculty"}
    })
    username: str | None = None
    email: str | None = None
    role: str | None = None


class UpdateUserActiveRequest(_Base):
    model_config = ConfigDict(extra="ignore", json_schema_extra={
        "example": {"is_active": True}
    })
    is_active: bool | str | None = None


# -- Theses ---------------------------------------------------------------

class ThesisCreateRequest(_Base):
    model_config = ConfigDict(extra="ignore", json_schema_extra={
        "example": {
            "title": "Demo Thesis",
            "abstract": "Demo abstract.",
            "research_type": "Capstone",
            "program_id": 2,
            "academic_year_id": 1,
            "status": "draft",
            "author_ids": [1],
            "adviser_id": 1,
            "category_ids": [1],
            "keyword_terms": ["machine learning", "education"],
        }
    })
    title: str | None = None
    abstract: str | None = None
    research_type: str | None = None
    program_id: int | None = None
    academic_year_id: int | None = None
    status: str | None = None
    author_ids: list[int] | None = None
    adviser_id: int | None = None
    category_ids: list[int] | None = None
    keyword_terms: list[str] | None = None
    pdf_url: str | None = None
    confirm_duplicate: bool | None = None


class ThesisUpdateRequest(_Base):
    model_config = ConfigDict(extra="ignore", json_schema_extra={
        "example": {"status": "published"}
    })
    title: str | None = None
    abstract: str | None = None
    research_type: str | None = None
    program_id: int | None = None
    academic_year_id: int | None = None
    status: str | None = None
    pdf_url: str | None = None
    author_ids: list[int] | None = None
    adviser_id: int | None = None
    co_adviser_id: int | None = None
    category_ids: list[int] | None = None
    keyword_terms: list[str] | None = None


# -- Metadata -------------------------------------------------------------

class AuthorCreateRequest(_Base):
    model_config = ConfigDict(extra="ignore", json_schema_extra={
        "example": {"first_name": "Maria", "middle_name": "S.", "last_name": "Santos", "email": "maria.santos@csu.edu.ph"}
    })
    first_name: str | None = None
    middle_name: str | None = None
    last_name: str | None = None
    email: str | None = None


class AuthorUpdateRequest(AuthorCreateRequest):
    pass


class AdviserCreateRequest(_Base):
    model_config = ConfigDict(extra="ignore", json_schema_extra={
        "example": {"first_name": "Jose", "middle_name": "P.", "last_name": "Rizal", "email": "jose.rizal@csu.edu.ph"}
    })
    first_name: str | None = None
    middle_name: str | None = None
    last_name: str | None = None
    email: str | None = None


class AdviserUpdateRequest(AdviserCreateRequest):
    pass


class CategoryCreateRequest(_Base):
    model_config = ConfigDict(extra="ignore", json_schema_extra={
        "example": {"name": "Artificial Intelligence", "description": "AI and machine learning studies"}
    })
    name: str | None = None
    description: str | None = None


class CategoryUpdateRequest(CategoryCreateRequest):
    pass


class ProgramCreateRequest(_Base):
    model_config = ConfigDict(extra="ignore", json_schema_extra={
        "example": {"name": "BS Computer Science", "code": "BSCS", "description": "Bachelor of Science in Computer Science"}
    })
    name: str | None = None
    code: str | None = None
    description: str | None = None


class ProgramUpdateRequest(ProgramCreateRequest):
    pass


class AcademicYearCreateRequest(_Base):
    model_config = ConfigDict(extra="ignore", json_schema_extra={
        "example": {"name": "2025-2026", "start_year": 2025, "end_year": 2026, "is_active": True}
    })
    name: str | None = None
    start_year: int | None = None
    end_year: int | None = None
    is_active: bool | str | None = None


class AcademicYearUpdateRequest(AcademicYearCreateRequest):
    pass


# -- Embeddings / Search --------------------------------------------------

class SemanticSearchRequest(_Base):
    model_config = ConfigDict(extra="ignore", json_schema_extra={
        "example": {"query": "machine learning for student performance", "limit": 10}
    })
    query: str | None = None
    limit: int | None = None
