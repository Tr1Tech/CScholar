"""Shared resolution of stored thesis PDFs.

Uploads are served from ``/api/uploads/<stored name>``, so every caller that
needs the file behind a ``pdf_url`` has to enforce the same rule: the URL may
name a bare filename under ``UPLOAD_DIR`` and nothing else. Keeping that check
in one place means the reader (embedding/indexing), the downloader (auth), and
the validator (thesis create) cannot drift into accepting different paths.
"""

import os

from ..config import UPLOAD_DIR

UPLOAD_URL_PREFIX = "/api/uploads/"


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
