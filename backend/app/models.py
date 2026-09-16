"""SQLAlchemy models for CScholar - matches db/schema.sql exactly.
Schema: ceit_repo (set via DATABASE_URL search_path).
"""

from __future__ import annotations
import datetime
from typing import Optional, List
from pgvector.sqlalchemy import Vector
from .extensions import db

# --- 1. users ---
class User(db.Model):
    __allow_unmapped__ = True
    __tablename__ = "users"
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(20), nullable=False)
    is_active = db.Column(db.Boolean, nullable=False, default=True)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.datetime.utcnow)
    updated_at = db.Column(db.DateTime, nullable=False, default=datetime.datetime.utcnow)

# --- 2. programs ---
class Program(db.Model):
    __allow_unmapped__ = True
    __tablename__ = "programs"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(150), nullable=False)
    code = db.Column(db.String(20), unique=True, nullable=False)
    description = db.Column(db.Text)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.datetime.utcnow)
    theses = db.relationship("Thesis", back_populates="program")

# --- 3. academic_years ---
class AcademicYear(db.Model):
    __allow_unmapped__ = True
    __tablename__ = "academic_years"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(20), unique=True, nullable=False)
    start_year = db.Column(db.Integer, nullable=False)
    end_year = db.Column(db.Integer, nullable=False)
    is_active = db.Column(db.Boolean, nullable=False, default=False)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.datetime.utcnow)
    theses = db.relationship("Thesis", back_populates="academic_year")

# --- 4. theses ---
class Thesis(db.Model):
    __allow_unmapped__ = True
    __tablename__ = "theses"
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(300), nullable=False)
    abstract = db.Column(db.Text, nullable=False)
    research_type = db.Column(db.String(20), nullable=False)
    program_id = db.Column(db.Integer, db.ForeignKey("programs.id"), nullable=False)
    academic_year_id = db.Column(db.Integer, db.ForeignKey("academic_years.id"), nullable=False)
    status = db.Column(db.String(20), nullable=False, default="draft")
    creator_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.datetime.utcnow)
    updated_at = db.Column(db.DateTime, nullable=False, default=datetime.datetime.utcnow)
    program = db.relationship("Program", back_populates="theses")
    academic_year = db.relationship("AcademicYear", back_populates="theses")

# --- association tables as Table objects ---
thesis_authors = db.Table(
    "thesis_authors",
    db.Column("thesis_id", db.Integer, db.ForeignKey("theses.id", ondelete="CASCADE"), primary_key=True),
    db.Column("author_id", db.Integer, db.ForeignKey("authors.id", ondelete="CASCADE"), primary_key=True),
    db.Column("order_index", db.Integer, nullable=False, default=1),
)
thesis_advisers = db.Table(
    "thesis_advisers",
    db.Column("thesis_id", db.Integer, db.ForeignKey("theses.id", ondelete="CASCADE"), primary_key=True),
    db.Column("adviser_id", db.Integer, db.ForeignKey("advisers.id", ondelete="CASCADE"), primary_key=True),
)
thesis_categories = db.Table(
    "thesis_categories",
    db.Column("thesis_id", db.Integer, db.ForeignKey("theses.id", ondelete="CASCADE"), primary_key=True),
    db.Column("category_id", db.Integer, db.ForeignKey("categories.id", ondelete="CASCADE"), primary_key=True),
)
thesis_keywords = db.Table(
    "thesis_keywords",
    db.Column("thesis_id", db.Integer, db.ForeignKey("theses.id", ondelete="CASCADE"), primary_key=True),
    db.Column("keyword_id", db.Integer, db.ForeignKey("keywords.id", ondelete="CASCADE"), primary_key=True),
)

# --- 5. authors ---
class Author(db.Model):
    __allow_unmapped__ = True
    __tablename__ = "authors"
    id = db.Column(db.Integer, primary_key=True)
    first_name = db.Column(db.String(80), nullable=False)
    middle_name = db.Column(db.String(80))
    last_name = db.Column(db.String(80), nullable=False)
    email = db.Column(db.String(120))
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.datetime.utcnow)

# --- 7. advisers ---
class Adviser(db.Model):
    __allow_unmapped__ = True
    __tablename__ = "advisers"
    id = db.Column(db.Integer, primary_key=True)
    first_name = db.Column(db.String(80), nullable=False)
    middle_name = db.Column(db.String(80))
    last_name = db.Column(db.String(80), nullable=False)
    email = db.Column(db.String(120))
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.datetime.utcnow)

# --- 9. categories ---
class Category(db.Model):
    __allow_unmapped__ = True
    __tablename__ = "categories"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), unique=True, nullable=False)
    description = db.Column(db.Text)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.datetime.utcnow)

# --- 11. keywords ---
class Keyword(db.Model):
    __allow_unmapped__ = True
    __tablename__ = "keywords"
    id = db.Column(db.Integer, primary_key=True)
    term = db.Column(db.String(100), unique=True, nullable=False)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.datetime.utcnow)

# --- 13. thesis_files ---
class ThesisFile(db.Model):
    __allow_unmapped__ = True
    __tablename__ = "thesis_files"
    id = db.Column(db.Integer, primary_key=True)
    thesis_id = db.Column(db.Integer, db.ForeignKey("theses.id", ondelete="CASCADE"), nullable=False)
    filename = db.Column(db.String(255), nullable=False)
    file_path = db.Column(db.String(512), nullable=False)
    file_size = db.Column(db.BigInteger)
    mime_type = db.Column(db.String(100))
    uploaded_by = db.Column(db.Integer, db.ForeignKey("users.id", ondelete="SET NULL"))
    uploaded_at = db.Column(db.DateTime, nullable=False, default=datetime.datetime.utcnow)

# --- 14. thesis_embeddings ---
class ThesisEmbedding(db.Model):
    __allow_unmapped__ = True
    __tablename__ = "thesis_embeddings"
    id = db.Column(db.Integer, primary_key=True)
    thesis_id = db.Column(db.Integer, db.ForeignKey("theses.id", ondelete="CASCADE"), nullable=False)
    chunk_text = db.Column(db.Text, nullable=False)
    embedding = db.Column(Vector(384))
    model_name = db.Column(db.String(100), nullable=False)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.datetime.utcnow)

# --- 15. search_logs ---
class SearchLog(db.Model):
    __allow_unmapped__ = True
    __tablename__ = "search_logs"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id", ondelete="SET NULL"))
    query = db.Column(db.Text)
    filters = db.Column(db.JSON)
    result_count = db.Column(db.Integer)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.datetime.utcnow)

# --- 16. recommendation_logs ---
class RecommendationLog(db.Model):
    __allow_unmapped__ = True
    __tablename__ = "recommendation_logs"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id", ondelete="SET NULL"))
    source_thesis_id = db.Column(db.Integer, db.ForeignKey("theses.id", ondelete="CASCADE"), nullable=False)
    recommended_thesis_id = db.Column(db.Integer, db.ForeignKey("theses.id", ondelete="CASCADE"), nullable=False)
    similarity_score = db.Column(db.Float)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.datetime.utcnow)
