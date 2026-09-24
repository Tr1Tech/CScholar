"""Configuration loading for the CScholar backend (raw psycopg2)."""

import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    """Base configuration shared across environments."""

    # Flask
    SECRET_KEY = os.getenv("SECRET_KEY", "dev-change-me")
    FLASK_DEBUG = os.getenv("FLASK_DEBUG", "0") == "1"

    # Database (raw psycopg2 connection params)
    DB_HOST = os.getenv("DB_HOST", "localhost")
    DB_PORT = os.getenv("DB_PORT", "5432")
    DB_NAME = os.getenv("DB_NAME", "cscholar")
    DB_USER = os.getenv("DB_USER", "postgres")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "")

    # AI/ML
    EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "all-MiniLM-L6-v2")
    EMBEDDING_DIM = int(os.getenv("EMBEDDING_DIM", "384"))
