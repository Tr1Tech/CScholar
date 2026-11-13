"""Background embedding index maintenance.

The embedding model takes tens of seconds to import/load on a cold process.
Loading it inside a write request made the first thesis submission after every
backend restart appear to hang. These helpers hand that work to a daemon
thread so create/update responses are never blocked by model startup.
"""

import os
import threading

from .uploads import upload_path


def pdf_text_from_url(pdf_url):
    """Return the text of a stored thesis PDF, or "" when unreadable.

    The path rules live in [upload_path], shared with the download and
    validation routes: only a bare filename under UPLOAD_DIR is accepted.
    """
    try:
        path = upload_path(pdf_url)
        if not path or not os.path.isfile(path):
            return ""
        import pymupdf

        with pymupdf.open(path) as doc:
            return "".join(page.get_text() for page in doc)
    except Exception:
        # A missing/corrupt PDF must not stop title+abstract indexing.
        return ""


def embed_thesis_async(thesis_id, title, abstract, pdf_text=None, pdf_url=None):
    """Recompute and store a thesis' chunks/vectors off the request thread.

    When ``pdf_text`` is not supplied but ``pdf_url`` is, the manuscript is
    read from disk in the worker thread. That is what makes a thesis created
    with an attached PDF indexed on title + abstract + full PDF content.
    """

    def _work():
        try:
            from .. import models as db
            from .chunking import build_thesis_chunks
            from .embeddings import embedding_service

            if not embedding_service.available:
                return
            text = pdf_text
            if not text and pdf_url:
                text = pdf_text_from_url(pdf_url)
            chunks = build_thesis_chunks(title or "", abstract or "", text)
            if not chunks:
                return
            vectors = embedding_service.embed_batch(chunks)
            if not vectors or len(vectors) != len(chunks):
                return
            db.replace_thesis_embeddings(
                thesis_id,
                list(zip(chunks, vectors)),
                embedding_service.model_name,
            )
        except Exception:
            # Indexing is best-effort; a failure must never surface as a 500 on
            # the submission that triggered it.
            pass

    threading.Thread(
        target=_work, daemon=True, name=f"embed-thesis-{thesis_id}"
    ).start()
