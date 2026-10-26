"""Pydantic request models.

Fields are intentionally optional here: the routes keep their existing manual
validation and error messages, while FastAPI uses these models to generate
useful Swagger UI documentation (field names + examples instead of
`additionalProp1`).

Field order mirrors the JSON body the Flutter frontend actually sends, so the
Swagger "Example Value" reads in the same order as the app's forms.
"""

from pydantic import BaseModel, ConfigDict, Field


class _Base(BaseModel):
    model_config = ConfigDict(extra="ignore")


# -- Auth / Users ---------------------------------------------------------

class RegisterRequest(_Base):
    model_config = ConfigDict(extra="ignore", json_schema_extra={
        "example": {"username": "demostudent", "email": "demo@csu.edu.ph", "password": "demo1234"}
    })
    username: str | None = Field(default=None, description="Display name for the account")
    email: str | None = Field(default=None, description="Institutional email address")
    password: str | None = Field(default=None, description="At least 6 characters")


class LoginRequest(_Base):
    model_config = ConfigDict(extra="ignore", json_schema_extra={
        "example": {"email": "admin@csu.edu.ph", "password": "admin123"}
    })
    email: str | None = Field(default=None, description="Registered institutional email")
    password: str | None = Field(default=None, description="Account password")


class CreateUserRequest(_Base):
    model_config = ConfigDict(extra="ignore", json_schema_extra={
        "example": {"username": "faculty2", "email": "faculty2@csu.edu.ph", "password": "secret123", "role": "faculty"}
    })
    username: str | None = Field(default=None, description="Display name for the account")
    email: str | None = Field(default=None, description="Institutional email address")
    password: str | None = Field(default=None, description="At least 6 characters")
    role: str | None = Field(default=None, description="student, faculty, or admin")


class UpdateUserRequest(_Base):
    model_config = ConfigDict(extra="ignore", json_schema_extra={
        "example": {"username": "faculty2", "email": "faculty2@csu.edu.ph", "role": "faculty"}
    })
    username: str | None = None
    email: str | None = None
    role: str | None = Field(default=None, description="student, faculty, or admin")


class UpdateUserActiveRequest(_Base):
    model_config = ConfigDict(extra="ignore", json_schema_extra={
        "example": {"is_active": True}
    })
    is_active: bool | None = None


# -- Theses ---------------------------------------------------------------

class ThesisCreateRequest(_Base):
    model_config = ConfigDict(extra="ignore", json_schema_extra={
        "example": {
            "title": "Demo Thesis",
            "abstract": "Demo abstract.",
            "program_id": 2,
            "academic_year_id": 1,
            "research_type": "Capstone",
            "author_ids": [1],
            "adviser_id": 1,
            "category_ids": [1],
            "keyword_terms": ["machine learning", "education"],
            "pdf_url": "/api/uploads/demo.pdf",
            "status": "draft",
            "confirm_duplicate": False,
        }
    })
    title: str | None = None
    abstract: str | None = None
    program_id: int | None = None
    academic_year_id: int | None = None
    research_type: str | None = Field(default=None, description="Thesis or Capstone")
    author_ids: list[int] | None = None
    adviser_id: int | None = None
    category_ids: list[int] | None = None
    keyword_terms: list[str] | None = None
    pdf_url: str | None = Field(default=None, description="Uploaded PDF URL from /api/upload/pdf")
    status: str | None = Field(default=None, description="draft, approved, published, or archived (admin only)")
    confirm_duplicate: bool | None = Field(
        default=None,
        description="Resubmit with true after a 409 duplicate warning",
    )


class ThesisUpdateRequest(_Base):
    model_config = ConfigDict(extra="ignore", json_schema_extra={
        "example": {
            "title": "Demo Thesis",
            "abstract": "Demo abstract.",
            "program_id": 2,
            "academic_year_id": 1,
            "research_type": "Capstone",
            "author_ids": [1],
            "adviser_id": 1,
            "category_ids": [1],
            "keyword_terms": ["machine learning", "education"],
            "pdf_url": "/api/uploads/demo.pdf",
            "status": "published",
        }
    })
    title: str | None = None
    abstract: str | None = None
    program_id: int | None = None
    academic_year_id: int | None = None
    research_type: str | None = Field(default=None, description="Thesis or Capstone")
    author_ids: list[int] | None = None
    adviser_id: int | None = None
    category_ids: list[int] | None = None
    keyword_terms: list[str] | None = None
    pdf_url: str | None = Field(default=None, description="Uploaded PDF URL from /api/upload/pdf")
    status: str | None = Field(default=None, description="draft, approved, published, or archived (admin only)")


# -- Metadata -------------------------------------------------------------

class AuthorCreateRequest(_Base):
    model_config = ConfigDict(extra="ignore", json_schema_extra={
        "example": {"first_name": "Maria", "last_name": "Santos", "email": "maria.santos@csu.edu.ph", "middle_name": "S."}
    })
    first_name: str | None = None
    last_name: str | None = None
    email: str | None = None
    middle_name: str | None = None


class AuthorUpdateRequest(AuthorCreateRequest):
    pass


class AdviserCreateRequest(_Base):
    model_config = ConfigDict(extra="ignore", json_schema_extra={
        "example": {"first_name": "Jose", "last_name": "Rizal", "email": "jose.rizal@csu.edu.ph", "middle_name": "P."}
    })
    first_name: str | None = None
    last_name: str | None = None
    email: str | None = None
    middle_name: str | None = None


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
    is_active: bool | None = None


class AcademicYearUpdateRequest(AcademicYearCreateRequest):
    pass


# -- Embeddings / Search --------------------------------------------------

class SemanticSearchRequest(_Base):
    model_config = ConfigDict(extra="ignore", json_schema_extra={
        "example": {"query": "machine learning for student performance", "limit": 10}
    })
    query: str | None = None
    limit: int | None = Field(default=None, description="1-20 results")
