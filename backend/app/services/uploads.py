"""Shared resolution of stored thesis PDFs.

Uploads are served from ``/api/uploads/<stored name>``, so every caller that
needs the file behind a ``pdf_url`` has to enforce the same rule: the URL may
name a bare filename under ``UPLOAD_DIR`` and nothing else. Keeping that check
in one place means the reader (embedding/indexing), the downloader (auth), and
the validator (thesis create) cannot drift into accepting different paths.
"""

import logging
import os
import re

from ..config import UPLOAD_DIR
from . import object_store

logger = logging.getLogger(__name__)

UPLOAD_URL_PREFIX = "/api/uploads/"


def secure_filename(name):
    """Basename-only, storage-safe filename.

    Mirrors the rule used by ``/api/upload/pdf``: strip any directory part and
    replace everything outside ``[A-Za-z0-9._-]`` with ``_``. Kept here so the
    batch importer and the upload route cannot store different names for the
    same file.
    """
    name = (name or "").rsplit("/", 1)[-1].rsplit("\\", 1)[-1]
    name = re.sub(r"[^A-Za-z0-9._-]", "_", name)
    return name.strip("._") or "upload.pdf"


def upload_filename(pdf_url):
    """Return the stored filename named by [pdf_url], or None if unsafe."""
    if not pdf_url or not pdf_url.startswith(UPLOAD_URL_PREFIX):
        return None
    filename = pdf_url[len(UPLOAD_URL_PREFIX):]
    if (
        not filename
        or filename.startswith(".")
        or ".." in filename
        or "/" in filename
        or "\\" in filename
        or ":" in filename
        or "%" in filename
    ):
        return None
    return filename


def upload_path(pdf_url):
    """Absolute path for [pdf_url], or None when the URL is not a safe upload."""
    filename = upload_filename(pdf_url)
    if not filename:
        return None
    return os.path.join(UPLOAD_DIR, filename)


def remove_stored_file(pdf_url):
    """Best-effort removal of the blob behind [pdf_url].

    Call this only after the database no longer references the file. A failure
    must not fail the request that already committed: an orphaned blob is
    cheaper than a resurrected row, so both the local and the bucket copy are
    logged and skipped rather than raised. Returns True when anything was
    actually removed.
    """
    filename = upload_filename(pdf_url)
    if not filename:
        return False

    removed = False
    path = os.path.join(UPLOAD_DIR, filename)
    try:
        os.remove(path)
        removed = True
    except FileNotFoundError:
        pass
    except OSError as exc:
        logger.warning("Could not remove upload %s: %s", path, exc)

    if object_store.enabled():
        try:
            if object_store.delete_key(filename):
                removed = True
        except Exception as exc:  # pragma: no cover - credential/client failure
            logger.warning("Could not remove stored upload %s: %s", filename, exc)
    return removed


def remove_unreferenced_uploads(urls, is_referenced):
    """Remove each of [urls] that [is_referenced] reports as unused.

    The database check is injected so this module stays free of SQL. Every
    caller runs it after its write has committed; a shared PDF — one attached
    to more than one thesis — must survive, and a failed check or unlink is
    logged and skipped rather than raised. Returns True when any blob was
    removed.
    """
    removed = False
    for pdf_url in dict.fromkeys(u for u in urls if u):
        try:
            if is_referenced(pdf_url):
                continue
            if remove_stored_file(pdf_url):
                removed = True
        except Exception as exc:
            logger.warning("Could not clean up %s: %s", pdf_url, exc)
    return removed
