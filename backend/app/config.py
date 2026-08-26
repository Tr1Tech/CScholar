"""Configuration loading for the CScholar backend.

Secrets and environment-specific values are read from a .env file
(or real environment variables). NEVER commit a real .env file.
"""

import os

from dotenv import load_dotenv

load_dotenv()


class Config:
    """Base configuration shared across environments."""

    # Flask
    SECRET_KEY = os.getenv("SECRET_KEY", "dev-change-me")
    FLASK_DEBUG = os.getenv("FLASK_DEBUG", "1") == "1"

    # Database (used starting Phase 2) — placeholder for now
    DATABASE_URL = os.getenv(
        "DATABASE_URL", "postgresql://user:password@localhost:5432/cscholar"
    )

    # AI/ML (used starting Phase 12)
    EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "all-MiniLM-L6-v2")
    EMBEDDING_DIM = int(os.getenv("EMBEDDING_DIM", "384"))
