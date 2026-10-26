"""Configuration loading for the CScholar backend (raw psycopg2)."""

import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    """Base configuration shared across environments."""

    # App
    SECRET_KEY = os.getenv("SECRET_KEY", "dev-change-me")
    DEBUG = os.getenv("DEBUG", "0") == "1"

    # Database (raw psycopg2 connection params)
    DB_HOST = os.getenv("DB_HOST", "localhost")
    DB_PORT = os.getenv("DB_PORT", "5432")
    DB_NAME = os.getenv("DB_NAME", "cscholar")
    DB_USER = os.getenv("DB_USER", "postgres")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "")

    # AI/ML
    EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "all-MiniLM-L6-v2")
    EMBEDDING_DIM = int(os.getenv("EMBEDDING_DIM", "384"))


# Module-level paths (FastAPI has no app.root_path equivalent).
import os as _os
APP_DIR = _os.path.dirname(_os.path.abspath(__file__))
UPLOAD_DIR = _os.path.join(APP_DIR, "uploads")
BASE_DIR = _os.path.dirname(APP_DIR)
