"""Configuration loading for the CScholar backend.

Secrets and environment-specific values are read from a .env file
(or real environment variables). NEVER commit a real .env file.
"""

import os

from dotenv import load_dotenv

load_dotenv()


def _database_uri() -> str:
    uri = os.getenv(
        "DATABASE_URL",
        "postgresql+psycopg://user:pass@localhost:5432/cscholar",
    )
    # Ensure search_path=ceit_repo so unqualified tables resolve correctly
    if "ceit_repo" not in uri:
        sep = "&" if "?" in uri else "?"
        uri = f"{uri}{sep}options=-c%20search_path%3Dceit_repo"
    uri = uri.replace("postgresql://", "postgresql+psycopg://", 1) if uri.startswith("postgresql://") else uri
    return uri


class Config:
    """Base configuration shared across environments."""

    # Flask
    SECRET_KEY = os.getenv("SECRET_KEY", "dev-change-me")
    FLASK_DEBUG = os.getenv("FLASK_DEBUG", "1") == "1"

    SQLALCHEMY_DATABASE_URI = _database_uri()
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ENGINE_OPTIONS = {
        "pool_pre_ping": True,
    }

    # AI/ML (used starting Phase 12)
    EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "all-MiniLM-L6-v2")
    EMBEDDING_DIM = int(os.getenv("EMBEDDING_DIM", "384"))
