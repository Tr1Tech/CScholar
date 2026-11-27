"""Staging and background execution for the admin Bulk Import screen.

The route layer only validates and stores the upload; the actual batch runs in
a daemon thread so the HTTP request returns immediately. Progress and the final
per-row report are written to ``import_jobs``, which the screen polls.
"""

import datetime
import logging
import shutil
import threading
from pathlib import Path

from .. import models as db
from ..config import UPLOAD_DIR
from . import importing

logger = logging.getLogger(__name__)

STAGING_ROOT = Path(UPLOAD_DIR) / "_import_jobs"
MAX_CSV_BYTES = 5 * 1024 * 1024
MAX_PDF_BYTES = 50 * 1024 * 1024
MAX_PDFS = 100

_run_lock = threading.Lock()


def job_dir(job_id):
    return STAGING_ROOT / str(job_id)


def pdf_dir(job_id):
    return job_dir(job_id) / "pdf"


def csv_path(job_id):
    return job_dir(job_id) / "metadata.csv"


def prepare_job_dir(job_id):
    directory = job_dir(job_id)
    (directory / "pdf").mkdir(parents=True, exist_ok=True)
    return directory


def save_csv(job_id, data):
    """Store the uploaded CSV as UTF-8; reject oversized or empty files."""
    if not data:
        raise ValueError("CSV file is empty")
    if len(data) > MAX_CSV_BYTES:
        raise ValueError("CSV is larger than 5 MB")
    prepare_job_dir(job_id)
    csv_path(job_id).write_bytes(data)


def _staging_filename(original):
    """Keep the staff's filename so it can match the CSV exactly.

    Only the *staging* copy keeps spaces: it is not web-served, and the CSV
    refers to names like ``CEIT_BSIT_2023_0142.pdf`` (or a name with spaces).
    The repository copy is still stored through ``secure_filename``.
    """
    name = (original or "").replace("\\", "/").rsplit("/", 1)[-1].strip()
    if (
        not name
        or name in (".", "..")
        or not name.lower().endswith(".pdf")
        or len(name) > 255
        or any(ord(char) < 32 for char in name)
    ):
        raise ValueError(f"Not a valid PDF filename: {original!r}")
    return name


def save_pdfs(job_id, uploads):
    """Stream uploaded PDFs into the job folder and return the stored names.

    ``uploads`` is a list of ``(filename, file_object)`` pairs. The staging
    name is the original basename, so the CSV's ``pdf_filename`` matches what
    the staff sees in Explorer.
    """
    if len(uploads) > MAX_PDFS:
        raise ValueError(f"Too many PDFs (maximum {MAX_PDFS})")
    prepare_job_dir(job_id)
    saved = []
    seen = set()
    for original, handle in uploads:
        name = _staging_filename(original)
        if name.lower() in seen:
            raise ValueError(f"Duplicate PDF filename: {name}")
        seen.add(name.lower())
        destination = pdf_dir(job_id) / name
        with destination.open("wb") as out:
            shutil.copyfileobj(handle, out)
        if destination.stat().st_size == 0:
            destination.unlink(missing_ok=True)
            raise ValueError(f"PDF is empty: {name}")
        if destination.stat().st_size > MAX_PDF_BYTES:
            destination.unlink(missing_ok=True)
            raise ValueError(f"PDF is larger than 50 MB: {name}")
        saved.append(name)
    return saved


def cleanup_job_dir(job_id):
    """Delete the job's staging folder. True when nothing is left behind."""
    directory = job_dir(job_id)
    shutil.rmtree(directory, ignore_errors=True)
    if directory.exists():
        # Windows keeps a handle open long enough for a first pass to fail;
        # the startup sweep retries rather than leaving the folder forever.
        logger.warning("Staging folder for import %s could not be removed", job_id)
        return False
    return True


def sweep_orphaned_job_dirs():
    """Remove staging folders whose ``import_jobs`` row no longer exists.

    A folder without a row can never be deleted through the UI (the route
    needs a job id), so it would sit on disk forever — including after a
    restart that interrupted a delete. Folders are listed before the row ids
    are read, and a job's row is always committed before its folder is
    created, so a listed folder is an orphan only when its row is really
    gone. Entries that are not numeric job ids are left alone.
    """
    if not STAGING_ROOT.is_dir():
        return []
    candidates = [
        entry
        for entry in STAGING_ROOT.iterdir()
        if entry.is_dir() and entry.name.isdigit()
    ]
    if not candidates:
        return []
    known_ids = db.list_import_job_ids()
    removed = []
    for entry in candidates:
        job_id = int(entry.name)
        if job_id in known_ids:
            continue
        shutil.rmtree(entry, ignore_errors=True)
        if entry.exists():
            logger.warning("Orphaned staging folder %s could not be removed", entry)
        else:
            removed.append(job_id)
    if removed:
        logger.info("Removed orphaned import staging folders: %s", removed)
    return removed


def counts(rows):
    return {
        "total_rows": len(rows),
        "processed_rows": sum(
            1 for row in rows if row.action in ("created", "updated", "skipped", "error")
        ),
        "created_count": sum(1 for row in rows if row.action == "created"),
        "updated_count": sum(1 for row in rows if row.action == "updated"),
        "skipped_count": sum(1 for row in rows if row.action == "skipped"),
        "error_count": sum(1 for row in rows if row.errors),
        "indexed_count": sum(1 for row in rows if row.indexed),
    }


def _progress_writer(job_id, rows):
    def write(event, _row):
        if event == "indexing":
            # Metadata is committed at this point; embeddings are the long
            # tail. Say so instead of leaving the bar at 100% with no reason.
            db.update_import_job(
                job_id,
                message="Records saved. Building the semantic search index…",
            )
            return
        db.update_import_job(
            job_id,
            **counts(rows),
            rows=[importing.row_json(row) for row in rows],
        )

    return write


def run_import_job(job_id):
    """Background worker. Never raises: failures are recorded on the job row."""
    if not _run_lock.acquire(blocking=False):
        db.update_import_job(
            job_id,
            status="failed",
            message="Another import is already running",
            finished_at=datetime.datetime.now(),
        )
        return
    try:
        db.update_import_job(
            job_id,
            status="running",
            started_at=datetime.datetime.now(),
            message=None,
        )
        directory = job_dir(job_id)
        rows = []
        try:
            raw_rows = importing.read_csv(csv_path(job_id))
            rows = importing.validate_rows(
                raw_rows, pdf_dir(job_id), importing.load_lookup()
            )
            errors = sum(1 for row in rows if row.errors)
            if errors:
                db.update_import_job(
                    job_id,
                    status="failed",
                    message=(
                        f"{errors} row(s) failed validation when the import started. "
                        "Run the check again."
                    ),
                    finished_at=datetime.datetime.now(),
                    rows=[importing.row_json(row) for row in rows],
                    **counts(rows),
                )
                return

            summary = importing.run_batch(
                rows, on_event=_progress_writer(job_id, rows)
            )
            message = None
            if summary["embedding_failures"]:
                message = (
                    f"{summary['embedding_failures']} row(s) imported but could not "
                    "be indexed; re-run the batch to repair them."
                )
            db.update_import_job(
                job_id,
                status="completed",
                message=message,
                finished_at=datetime.datetime.now(),
                rows=[importing.row_json(row) for row in rows],
                **counts(rows),
            )
            cleanup_job_dir(job_id)
        except Exception as exc:
            db.update_import_job(
                job_id,
                status="failed",
                message=str(exc)[:1000],
                finished_at=datetime.datetime.now(),
                rows=[importing.row_json(row) for row in rows] if rows else [],
                **counts(rows) if rows else {},
            )
    finally:
        _run_lock.release()
