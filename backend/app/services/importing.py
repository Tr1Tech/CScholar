"""Shared batch-import logic for the CLI script and the admin Bulk Import UI.

One CSV row becomes one ``draft`` thesis: metadata is resolved/created, the PDF
is copied into ``UPLOAD_DIR``, and title+abstract+PDF text are chunked and
embedded for semantic search.

The command-line entry point lives in ``backend/scripts/import_theses.py`` and
is a thin wrapper around [read_csv] -> [Lookup] -> [validate_rows] ->
[run_batch]. The admin API uses the same functions, so the screen and the
script can never disagree about validation rules.

Guarantees:

* Validation is read-only: it resolves programs/years and detects duplicates
  without writing anything.
* Re-running is idempotent. A thesis is recognised by normalized title +
  academic year + first author. Existing authors, advisers, categories, and
  keywords are reused instead of duplicated.
* Imported rows are always ``status='draft'``. Publication is a separate step.
* PDFs are stored under a uuid-prefixed ``secure_filename`` name, exactly like
  ``POST /api/upload/pdf``, and ``pdf_url`` always points at ``/api/uploads/``.
"""

from __future__ import annotations

import csv
import os
import re
import shutil
import uuid
from contextlib import contextmanager
from dataclasses import dataclass, field
from pathlib import Path

from .. import models as db
from ..config import UPLOAD_DIR
from ..extensions import get_conn, put_conn
from .chunking import build_thesis_chunks
from .uploads import UPLOAD_URL_PREFIX, secure_filename, upload_filename

REQUIRED_COLUMNS = [
    "title",
    "abstract",
    "research_type",
    "program_code",
    "academic_year",
    "authors",
    "pdf_filename",
]

TEMPLATE_COLUMNS = [
    "accession_no",
    "title",
    "abstract",
    "research_type",
    "program_code",
    "academic_year",
    "authors",
    "adviser",
    "keywords",
    "categories",
    "pdf_filename",
    "pages_scanned",
    "scanned_by",
    "notes",
]

TEMPLATE_EXAMPLE = {
    "accession_no": "",
    "title": "EXAMPLE — replace this row with a real study",
    "abstract": "Paste the printed abstract here, as one paragraph.",
    "research_type": "Capstone",
    "program_code": "BSIT",
    "academic_year": "2023-2024",
    "authors": "Dela Cruz, Juan P.; Santos, Maria L.",
    "adviser": "Reyes, Ana B.",
    "keywords": "semantic search; repository; web-based system",
    "categories": "Information Systems; Web Development",
    "pdf_filename": "example.pdf",
    "pages_scanned": "5",
    "scanned_by": "AB",
    "notes": "Delete this example row before uploading.",
}

# The sample row is useful in the downloaded template but must never become a
# thesis: a librarian who uploads the file without deleting it would otherwise
# import "EXAMPLE — replace this row..." into the repository. Matching is
# punctuation-insensitive because Excel round-trips mangle the em dash.
TEMPLATE_SENTINEL_PREFIX = "EXAMPLE"
TEMPLATE_SENTINEL_BODY = "REPLACE THIS ROW"

REPORT_COLUMNS = [
    "row",
    "action",
    "thesis_id",
    "pdf_filename",
    "title",
    "pages",
    "chunks",
    "warnings",
    "errors",
    "source_notes",
]

RESEARCH_TYPES = ("Thesis", "Capstone")
YEAR_RE = re.compile(r"^(\d{4})-(\d{4})$")
SUFFIX_RE = re.compile(r"^(jr|sr|ii|iii|iv|v)\.?$", re.IGNORECASE)
NAME_RE = re.compile(r"^[A-Za-zÀ-ÖØ-öø-ÿ][A-Za-zÀ-ÖØ-öø-ÿ.'\- ]*$")

# Same threshold the app uses to decide that a PDF has no usable text layer.
MIN_TEXT_CHARS = 200


# ── small helpers ──────────────────────────────────────────────────────────


def clean(text):
    """Collapse embedded newlines/tabs (Excel edits) into single spaces."""
    return re.sub(r"\s+", " ", str(text or "")).strip()


def split_list(raw):
    """Split a semicolon-separated CSV cell, dropping blanks and duplicates."""
    items = []
    seen = set()
    for part in str(raw or "").split(";"):
        value = clean(part)
        key = value.lower()
        if value and key not in seen:
            seen.add(key)
            items.append(value)
    return items


def parse_person(raw):
    """Parse ``Last, First M.`` (optionally ``Last, First M., Jr.``).

    Returns ``(first_name, middle_name, last_name)``. Raises ``ValueError``
    with a readable reason for anything that does not fit the printed-name
    convention. Suffixes have no column in the schema, so they are kept on the
    last name (``Serato, Jr.``), which renders as "Eduardo P. Serato, Jr.".
    """
    text = clean(raw)
    if not text:
        raise ValueError("empty name")

    parts = [part.strip() for part in text.split(",")]
    if len(parts) == 1:
        raise ValueError(f"expected 'Last, First M.', got {text!r}")
    if len(parts) > 3:
        raise ValueError(f"too many commas in {text!r}")

    last, first = parts[0], parts[1]
    suffix = None
    if len(parts) == 3:
        if not SUFFIX_RE.match(parts[2]):
            raise ValueError(f"unrecognised suffix {parts[2]!r} in {text!r}")
        suffix = parts[2].rstrip(".")
        suffix = suffix[:1].upper() + suffix[1:].lower()
        if suffix.lower() in ("ii", "iii", "iv", "v"):
            suffix = suffix.upper()
        else:
            suffix += "."

    if not last or not first:
        raise ValueError(f"missing last or first name in {text!r}")
    if not NAME_RE.match(last):
        raise ValueError(f"unexpected characters in last name {last!r}")
    if not NAME_RE.match(first):
        raise ValueError(f"unexpected characters in first name {first!r}")

    tokens = first.split()
    middle = None
    if len(tokens) >= 2 and re.fullmatch(r"[A-Za-z]\.?", tokens[-1]):
        middle = tokens[-1].upper()
        if not middle.endswith("."):
            middle += "."
        tokens = tokens[:-1]
    first = " ".join(tokens)

    if not first:
        raise ValueError(f"missing first name in {text!r}")
    if suffix:
        last = f"{last}, {suffix}"

    for label, value in (("first name", first), ("middle name", middle), ("last name", last)):
        if value and len(value) > 80:
            raise ValueError(f"{label} exceeds 80 characters in {text!r}")

    return first, middle, last


def parse_people(raw, field_name):
    people = []
    for part in str(raw or "").split(";"):
        if part.strip():
            try:
                people.append(parse_person(part))
            except ValueError as exc:
                raise ValueError(f"{field_name}: {exc}") from exc
    return people


def dedupe_key(title, year_name, first_author):
    """Idempotency key from the plan: title + year + first author."""
    if not first_author:
        return None
    first, _middle, last = first_author
    norm = lambda value: re.sub(r"\s+", " ", value or "").strip().lower()
    return (norm(title), year_name, norm(f"{first} {last}"))


def year_bounds(name):
    match = YEAR_RE.match(name or "")
    if not match:
        return None
    start, end = int(match.group(1)), int(match.group(2))
    if end != start + 1:
        return None
    return start, end


# ── validation model ───────────────────────────────────────────────────────


@dataclass
class Row:
    number: int
    raw: dict
    title: str = ""
    abstract: str = ""
    research_type: str = ""
    program_code: str = ""
    program_id: int | None = None
    academic_year: str = ""
    academic_year_id: int | None = None
    authors: list = field(default_factory=list)
    adviser: tuple | None = None
    keywords: list = field(default_factory=list)
    categories: list = field(default_factory=list)
    pdf_filename: str = ""
    pdf_path: Path | None = None
    pdf_url: str = ""
    pages: int | None = None
    text_chars: int = 0
    chunks: int | None = None
    accession_no: str | None = None
    notes: str = ""
    action: str = ""
    thesis_id: int | None = None
    indexed: bool = False
    warnings: list = field(default_factory=list)
    errors: list = field(default_factory=list)


class Lookup:
    """Read-only database state used by both dry-run and import."""

    def __init__(self, conn):
        self.programs = {}
        self.years = {}
        self.has_accession = False
        self.existing = {}
        self.accessions = {}
        with conn.cursor() as cur:
            cur.execute("SELECT code, id FROM programs")
            self.programs = {str(code).upper(): pid for code, pid in cur.fetchall()}

            cur.execute("SELECT name, id FROM academic_years")
            self.years = {name: ayid for name, ayid in cur.fetchall()}

            cur.execute(
                "SELECT 1 FROM information_schema.columns "
                "WHERE table_schema = 'ceit_repo' AND table_name = 'theses' "
                "AND column_name = 'accession_no'"
            )
            self.has_accession = cur.fetchone() is not None

            cur.execute(
                "SELECT t.id, t.academic_year_id, t.title, t.status, t.pdf_url, "
                "       ch.chunk_count, fa.first_name, fa.last_name "
                "FROM theses t "
                "LEFT JOIN LATERAL ("
                "    SELECT COUNT(*) AS chunk_count FROM thesis_embeddings e "
                "    WHERE e.thesis_id = t.id"
                ") ch ON TRUE "
                "LEFT JOIN LATERAL ("
                "    SELECT a.first_name, a.last_name "
                "    FROM thesis_authors ta JOIN authors a ON ta.author_id = a.id "
                "    WHERE ta.thesis_id = t.id ORDER BY ta.order_index LIMIT 1"
                ") fa ON TRUE"
            )
            for row in cur.fetchall():
                title_key = re.sub(r"\s+", " ", row[2] or "").strip().lower()
                self.existing[(row[1], title_key)] = {
                    "id": row[0],
                    "status": row[3],
                    "pdf_url": row[4],
                    "chunks": row[5] or 0,
                    "first_author": (row[6], row[7]),
                }

            if self.has_accession:
                cur.execute(
                    "SELECT accession_no, id FROM theses "
                    "WHERE accession_no IS NOT NULL AND accession_no <> ''"
                )
                self.accessions = {acc: tid for acc, tid in cur.fetchall()}


# ── row validation ─────────────────────────────────────────────────────────


def validate_rows(rows_raw, pdf_dir, lookup):
    rows = []
    seen_keys = {}
    seen_pdfs = {}

    for number, raw in enumerate(rows_raw, start=2):  # row 1 is the header
        row = Row(number=number, raw=raw)

        row.title = clean(raw.get("title"))
        row.abstract = clean(raw.get("abstract"))
        row.research_type = clean(raw.get("research_type"))
        row.program_code = clean(raw.get("program_code")).upper()
        row.academic_year = clean(raw.get("academic_year"))
        row.pdf_filename = clean(raw.get("pdf_filename"))
        row.notes = clean(raw.get("notes"))
        accession = clean(raw.get("accession_no"))
        row.accession_no = accession or None

        # Required fields.
        for value, label in (
            (row.title, "title"),
            (row.abstract, "abstract"),
            (row.research_type, "research_type"),
            (row.program_code, "program_code"),
            (row.academic_year, "academic_year"),
            (raw.get("authors"), "authors"),
            (row.pdf_filename, "pdf_filename"),
        ):
            if not clean(value):
                row.errors.append(f"missing required field: {label}")

        # The downloaded template ships with one sample row. It is a format
        # guide, not a record; reject it even if someone attached a PDF and
        # fixed the filename, so the sample can never land in the repository.
        title_key = re.sub(r"[^A-Z0-9 ]", " ", row.title.upper())
        if (
            title_key.startswith(TEMPLATE_SENTINEL_PREFIX)
            and TEMPLATE_SENTINEL_BODY in title_key
        ):
            row.errors.append(
                "this is the template's example row — delete it, or replace "
                "its title with a real study"
            )

        if row.title and len(row.title) > 300:
            row.errors.append(f"title is {len(row.title)} characters (max 300)")

        if row.research_type and row.research_type not in RESEARCH_TYPES:
            row.errors.append(
                f"research_type {row.research_type!r} is not one of {list(RESEARCH_TYPES)}"
            )

        # Program must already exist; an unknown code fails the batch.
        if row.program_code:
            row.program_id = lookup.programs.get(row.program_code)
            if row.program_id is None:
                row.errors.append(
                    f"unknown program_code {row.program_code!r} "
                    f"(known: {', '.join(sorted(lookup.programs))})"
                )

        # Academic year: existing row or created on import.
        if row.academic_year:
            bounds = year_bounds(row.academic_year)
            if not bounds:
                row.errors.append(
                    f"academic_year {row.academic_year!r} is not a YYYY-YYYY label "
                    "with consecutive years"
                )
            else:
                row.academic_year_id = lookup.years.get(row.academic_year)
                if row.academic_year_id is None:
                    row.warnings.append(
                        f"academic_year {row.academic_year} does not exist; it will be created"
                    )

        # Names.
        if clean(raw.get("authors")):
            try:
                row.authors = parse_people(raw.get("authors"), "authors")
                if not row.authors:
                    row.errors.append("authors: at least one author is required")
            except ValueError as exc:
                row.errors.append(str(exc))

        if clean(raw.get("adviser")):
            try:
                people = parse_people(raw.get("adviser"), "adviser")
                if len(people) > 1:
                    row.errors.append("adviser: exactly one adviser is supported")
                elif people:
                    row.adviser = people[0]
            except ValueError as exc:
                row.errors.append(str(exc))

        # Controlled vocabulary cells.
        row.keywords = split_list(raw.get("keywords"))
        row.categories = split_list(raw.get("categories"))
        for term in row.keywords:
            if len(term) > 100:
                row.errors.append(f"keyword exceeds 100 characters: {term[:40]!r}...")
        for name in row.categories:
            if len(name) > 100:
                row.errors.append(f"category exceeds 100 characters: {name[:40]!r}...")

        # PDF file.
        if row.pdf_filename:
            if row.pdf_filename != Path(row.pdf_filename).name or ".." in row.pdf_filename:
                row.errors.append("pdf_filename must be a bare filename, not a path")
            else:
                if secure_filename(row.pdf_filename) != row.pdf_filename:
                    row.warnings.append(
                        "the stored copy is renamed for safety (spaces/symbols "
                        "become _); the upload match still uses the original name"
                    )
                path = pdf_dir / row.pdf_filename
                if not path.is_file():
                    row.errors.append(f"PDF not found: {path}")
                else:
                    row.pdf_path = path
                    try:
                        import pymupdf

                        with pymupdf.open(path) as doc:
                            row.pages = doc.page_count
                            text = "".join(page.get_text() for page in doc)
                        row.text_chars = len(text.strip())
                        if row.pages <= 0:
                            row.errors.append("PDF has no pages")
                        if row.text_chars >= MIN_TEXT_CHARS:
                            row.chunks = len(
                                build_thesis_chunks(row.title, row.abstract, text)
                            )
                        else:
                            row.warnings.append(
                                "PDF has no usable text layer; Tesseract will OCR it "
                                "during import (chunk count unknown in dry-run)"
                            )
                    except Exception as exc:
                        row.errors.append(f"cannot read PDF: {exc}")

            scanned = clean(raw.get("pages_scanned"))
            if scanned and row.pages is not None:
                try:
                    if int(scanned) != row.pages:
                        row.warnings.append(
                            f"pages_scanned={scanned} but PDF has {row.pages} pages"
                        )
                except ValueError:
                    row.warnings.append(f"pages_scanned {scanned!r} is not an integer")

            previous = seen_pdfs.get(row.pdf_filename.lower())
            if previous is not None:
                row.errors.append(f"pdf_filename also used by row {previous}")
            else:
                seen_pdfs[row.pdf_filename.lower()] = number

        # Accession is deferred in this batch; validate only when supplied.
        if row.accession_no:
            if not lookup.has_accession:
                row.errors.append(
                    "accession_no is set but ceit_repo.theses has no accession_no column"
                )
            elif row.accession_no in lookup.accessions:
                row.errors.append(
                    f"accession_no {row.accession_no!r} already belongs to "
                    f"thesis {lookup.accessions[row.accession_no]}"
                )

        # Duplicate detection inside the batch and against the database.
        key = dedupe_key(row.title, row.academic_year, row.authors[0] if row.authors else None)
        if key:
            if key in seen_keys:
                row.errors.append(f"duplicate of row {seen_keys[key]} in this batch")
            else:
                seen_keys[key] = number

            existing = None
            if row.academic_year_id is not None:
                norm_title = re.sub(r"\s+", " ", row.title).strip().lower()
                existing = lookup.existing.get((row.academic_year_id, norm_title))

            if existing:
                first = existing.get("first_author") or (None, None)
                same_author = (
                    clean(first[0]).lower() == row.authors[0][0].lower()
                    and clean(first[1]).lower() == row.authors[0][2].lower()
                )
                if not same_author:
                    row.errors.append(
                        f"title+year already exists as thesis {existing['id']} "
                        "with a different first author"
                    )
                else:
                    row.thesis_id = existing["id"]
                    missing_pdf = not existing.get("pdf_url")
                    no_chunks = existing.get("chunks", 0) == 0
                    row.action = "would_update" if (missing_pdf or no_chunks) else "would_skip"
                    row.warnings.append(
                        f"already imported as thesis {existing['id']} "
                        f"(status={existing['status']})"
                    )

        if row.errors:
            row.action = "error"
        elif not row.action:
            row.action = "would_create"

        rows.append(row)

    return rows


# ── database writes ────────────────────────────────────────────────────────


def get_or_create_person(cur, table, first, middle, last):
    cur.execute(
        f"SELECT id FROM {table} "
        "WHERE lower(first_name) = lower(%s) "
        "  AND lower(last_name) = lower(%s) "
        "  AND coalesce(lower(middle_name), '') = coalesce(lower(%s), '')",
        (first, last, middle),
    )
    found = cur.fetchone()
    if found:
        return found[0]
    cur.execute(
        f"INSERT INTO {table} (first_name, middle_name, last_name) "
        "VALUES (%s, %s, %s) RETURNING id",
        (first, middle, last),
    )
    return cur.fetchone()[0]


def get_or_create_category(cur, name):
    cur.execute("SELECT id FROM categories WHERE lower(name) = lower(%s)", (name,))
    found = cur.fetchone()
    if found:
        return found[0]
    cur.execute(
        "INSERT INTO categories (name) VALUES (%s) RETURNING id",
        (clean(name),),
    )
    return cur.fetchone()[0]


def copy_pdf(row):
    """Copy a source PDF into UPLOAD_DIR under a unique, safe name."""
    os.makedirs(UPLOAD_DIR, exist_ok=True)
    stored = f"{uuid.uuid4().hex}_{secure_filename(row.pdf_filename)}"
    destination = Path(UPLOAD_DIR) / stored
    shutil.copy2(row.pdf_path, destination)
    pdf_url = f"{UPLOAD_URL_PREFIX}{stored}"
    if upload_filename(pdf_url) != stored:
        destination.unlink(missing_ok=True)
        raise RuntimeError(f"stored filename failed the upload safety rule: {stored!r}")
    return stored, pdf_url, destination


def write_file_row(cur, thesis_id, row, pdf_url):
    cur.execute("DELETE FROM thesis_files WHERE thesis_id = %s", (thesis_id,))
    cur.execute(
        "INSERT INTO thesis_files "
        "(thesis_id, filename, file_path, file_size, mime_type, uploaded_by) "
        "VALUES (%s, %s, %s, %s, %s, NULL)",
        (
            thesis_id,
            secure_filename(row.pdf_filename),
            pdf_url,
            row.pdf_path.stat().st_size,
            "application/pdf",
        ),
    )


def persist_metadata(cur, row):
    """Insert or update one thesis.

    Returns ``(thesis_id, action, pdf_url, new_pdf_path)`` where
    ``new_pdf_path`` is set only when a file was copied and must be removed if
    the transaction later rolls back.
    """
    existing = row.thesis_id is not None
    action = "skipped"
    new_pdf = None
    pdf_url = None

    try:
        if existing:
            cur.execute("SELECT pdf_url FROM theses WHERE id = %s", (row.thesis_id,))
            found = cur.fetchone()
            current_url = found[0] if found else None
            if current_url:
                stored = upload_filename(current_url)
                if stored and (Path(UPLOAD_DIR) / stored).is_file():
                    pdf_url = current_url
            if pdf_url is None:
                _stored, pdf_url, new_pdf = copy_pdf(row)

            set_parts = []
            params = []
            if row.action == "would_update" and pdf_url:
                # Only repair what is missing; admin edits are not overwritten
                # unless --update-metadata is explicit.
                set_parts.append("pdf_url = %s")
                params.append(pdf_url)
            if row.accession_no:
                set_parts.append("accession_no = %s")
                params.append(row.accession_no)
            if set_parts:
                params.append(row.thesis_id)
                cur.execute(
                    f"UPDATE theses SET {', '.join(set_parts)}, updated_at = NOW() "
                    "WHERE id = %s",
                    params,
                )
                action = "updated"
            if new_pdf is not None:
                write_file_row(cur, row.thesis_id, row, pdf_url)
        else:
            _stored, pdf_url, new_pdf = copy_pdf(row)

            columns = [
                "title",
                "abstract",
                "research_type",
                "program_id",
                "academic_year_id",
                "status",
                "pdf_url",
            ]
            values = [
                row.title,
                row.abstract,
                row.research_type,
                row.program_id,
                row.academic_year_id,
                "draft",
                pdf_url,
            ]
            if row.accession_no:
                columns.append("accession_no")
                values.append(row.accession_no)
            placeholders = ", ".join(["%s"] * len(values))
            cur.execute(
                f"INSERT INTO theses ({', '.join(columns)}) VALUES ({placeholders}) "
                "RETURNING id",
                values,
            )
            row.thesis_id = cur.fetchone()[0]

            author_ids = [
                get_or_create_person(cur, "authors", *person) for person in row.authors
            ]
            adviser_id = (
                get_or_create_person(cur, "advisers", *row.adviser)
                if row.adviser
                else None
            )
            category_ids = [
                get_or_create_category(cur, name) for name in row.categories
            ]

            # _persist_thesis_relations owns the keyword upsert and keeps the
            # link tables identical to what the API write path produces.
            db._persist_thesis_relations(
                cur,
                row.thesis_id,
                author_ids=author_ids,
                adviser_id=adviser_id,
                category_ids=category_ids,
                keyword_terms=row.keywords,
            )
            write_file_row(cur, row.thesis_id, row, pdf_url)
            action = "created"
    except Exception:
        if new_pdf and new_pdf.exists():
            try:
                new_pdf.unlink()
            except OSError:
                pass
        raise

    return row.thesis_id, action, pdf_url, new_pdf


@contextmanager
def conn_cursor():
    """Short-lived read cursor from the pool (never used for writes)."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            yield cur
    finally:
        put_conn(conn)


def resolve_year(cur, row):
    if row.academic_year_id is not None:
        return row.academic_year_id
    bounds = year_bounds(row.academic_year)
    if not bounds:
        raise ValueError(f"invalid academic_year {row.academic_year!r}")
    cur.execute(
        "INSERT INTO academic_years (name, start_year, end_year, is_active) "
        "VALUES (%s, %s, %s, FALSE) RETURNING id",
        (row.academic_year, bounds[0], bounds[1]),
    )
    row.academic_year_id = cur.fetchone()[0]
    return row.academic_year_id


def import_row(row, update_metadata=False):
    conn = get_conn()
    new_pdf = None
    try:
        with conn.cursor() as cur:
            resolve_year(cur, row)
            _thesis_id, action, pdf_url, new_pdf = persist_metadata(cur, row)
            row.pdf_url = pdf_url or ""
            if update_metadata and row.thesis_id is not None and action != "created":
                author_ids = [
                    get_or_create_person(cur, "authors", *person) for person in row.authors
                ]
                adviser_id = (
                    get_or_create_person(cur, "advisers", *row.adviser)
                    if row.adviser
                    else None
                )
                category_ids = [get_or_create_category(cur, name) for name in row.categories]
                set_clause = (
                    "title = %s, abstract = %s, research_type = %s, program_id = %s, "
                    "academic_year_id = %s, updated_at = NOW()"
                )
                cur.execute(
                    f"UPDATE theses SET {set_clause} WHERE id = %s",
                    (
                        row.title,
                        row.abstract,
                        row.research_type,
                        row.program_id,
                        row.academic_year_id,
                        row.thesis_id,
                    ),
                )
                db._persist_thesis_relations(
                    cur,
                    row.thesis_id,
                    author_ids=author_ids,
                    adviser_id=adviser_id,
                    category_ids=category_ids,
                    keyword_terms=row.keywords,
                )
                action = "updated"
        conn.commit()
        row.action = action
        return action
    except Exception:
        conn.rollback()
        if new_pdf and new_pdf.exists():
            try:
                new_pdf.unlink()
            except OSError:
                pass
        raise
    finally:
        put_conn(conn)


def index_thesis(row, no_ocr=False, embed_batch=32):
    """Build and store chunks for one thesis. Returns the chunk count."""
    if not upload_filename(row.pdf_url):
        return 0

    from .indexing import pdf_text_from_url

    pdf_text = pdf_text_from_url(row.pdf_url, allow_ocr=not no_ocr)
    chunks = build_thesis_chunks(row.title, row.abstract, pdf_text)
    if not chunks:
        return 0

    from .embeddings import embedding_service

    if not embedding_service.available:
        raise RuntimeError(
            "embedding model is unavailable; is sentence-transformers installed?"
        )
    vectors = embedding_service.embed_batch(chunks, batch_size=embed_batch)
    if not vectors or len(vectors) != len(chunks):
        raise RuntimeError(f"embedding failed for {len(chunks)} chunks")

    db.replace_thesis_embeddings(
        row.thesis_id, list(zip(chunks, vectors)), embedding_service.model_name
    )
    return len(chunks)


# ── reporting ──────────────────────────────────────────────────────────────


def row_record(row):
    return {
        "row": row.number,
        "action": row.action,
        "thesis_id": row.thesis_id if row.thesis_id is not None else "",
        "pdf_filename": row.pdf_filename,
        "title": row.title,
        "pages": row.pages if row.pages is not None else "",
        "chunks": row.chunks if row.chunks is not None else "",
        "warnings": " | ".join(row.warnings),
        "errors": " | ".join(row.errors),
        "source_notes": row.notes,
    }


def _author_label(person):
    first, middle, last = person
    return " ".join(part for part in (first, middle, last) if part)


def row_json(row):
    """Richer row shape for the admin UI; [row_record] stays the CSV shape."""
    return {
        "row": row.number,
        "action": row.action,
        "thesis_id": row.thesis_id,
        "pdf_filename": row.pdf_filename,
        "title": row.title,
        "program_code": row.program_code,
        "academic_year": row.academic_year,
        "authors": "; ".join(_author_label(person) for person in row.authors),
        "adviser": _author_label(row.adviser) if row.adviser else "",
        "pages": row.pages,
        "chunks": row.chunks,
        "indexed": row.indexed,
        "warnings": list(row.warnings),
        "errors": list(row.errors),
        "source_notes": row.notes,
    }


def write_report(path, rows):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=REPORT_COLUMNS)
        writer.writeheader()
        for row in rows:
            writer.writerow(row_record(row))
    return path


# ── shared entry points ────────────────────────────────────────────────────


def template_csv():
    """CSV text (without BOM) for the admin "Download template" button."""
    import io

    buffer = io.StringIO()
    writer = csv.DictWriter(buffer, fieldnames=TEMPLATE_COLUMNS)
    writer.writeheader()
    writer.writerow(TEMPLATE_EXAMPLE)
    return buffer.getvalue()


def read_csv(path):
    """Read a metadata CSV and fail loudly when a required column is absent."""
    with Path(path).open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        missing = [
            column
            for column in REQUIRED_COLUMNS
            if column not in (reader.fieldnames or [])
        ]
        if missing:
            raise ValueError(
                f"CSV is missing required columns: {', '.join(missing)}"
            )
        return list(reader)


def load_lookup():
    """Read the program/year/duplicate state from the database (read-only)."""
    conn = get_conn()
    try:
        return Lookup(conn)
    finally:
        put_conn(conn)


def run_batch(
    rows,
    *,
    update_metadata=False,
    reindex=False,
    no_ocr=False,
    embed_batch=32,
    on_event=None,
):
    """Import and index validated rows. Returns a summary dict.

    ``on_event(event, row)`` is called for ``imported``, ``indexed``,
    ``error``, and ``embedding_error`` so a caller (CLI or the admin job
    runner) can report progress without this module knowing how it is rendered.
    """
    failures = 0
    embed_failures = 0
    indexed = 0

    for row in rows:
        if row.errors:
            row.action = "error"
            continue
        try:
            import_row(row, update_metadata=update_metadata)
            if on_event:
                on_event("imported", row)
        except Exception as exc:
            row.action = "error"
            row.errors.append(str(exc))
            failures += 1
            if on_event:
                on_event("error", row)

    # Embeddings are a separate pass so a model/OCR failure never rolls back a
    # correct metadata import. Re-running repairs only the missing rows.
    if on_event:
        on_event("indexing", None)
    for row in rows:
        if row.errors or row.thesis_id is None:
            continue
        if row.action == "skipped" and not reindex:
            continue
        try:
            with conn_cursor() as cur:
                cur.execute(
                    "SELECT pdf_url FROM theses WHERE id = %s", (row.thesis_id,)
                )
                found = cur.fetchone()
            pdf_url = found[0] if found else None
            if not pdf_url:
                row.warnings.append("no pdf_url; skipped embeddings")
                continue
            row.pdf_url = pdf_url
            if not reindex:
                with conn_cursor() as cur:
                    cur.execute(
                        "SELECT COUNT(*) FROM thesis_embeddings WHERE thesis_id = %s",
                        (row.thesis_id,),
                    )
                    if cur.fetchone()[0] > 0:
                        row.warnings.append("embeddings already present")
                        continue
            row.chunks = index_thesis(
                row, no_ocr=no_ocr, embed_batch=embed_batch
            )
            row.indexed = True
            indexed += 1
            if on_event:
                on_event("indexed", row)
        except Exception as exc:
            embed_failures += 1
            row.warnings.append(f"embedding failed: {exc}")
            if on_event:
                on_event("embedding_error", row)

    return {
        "total": len(rows),
        "created": sum(1 for row in rows if row.action == "created"),
        "updated": sum(1 for row in rows if row.action == "updated"),
        "skipped": sum(1 for row in rows if row.action == "skipped"),
        "invalid": sum(1 for row in rows if row.errors),
        "failed": failures,
        "indexed": indexed,
        "embedding_failures": embed_failures,
    }
