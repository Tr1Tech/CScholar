"""Embedding routes -- generate and store thesis embeddings (full-PDF chunking)."""

import os
import threading

from fastapi import APIRouter, Request, Depends, HTTPException, Body, Query
from .. import models as db
from ..auth import login_required, admin_required
from ..services.embeddings import embedding_service
from ..services.chunking import build_thesis_chunks
from ..config import UPLOAD_DIR
from ..schemas import SemanticSearchRequest

router = APIRouter(tags=["Embeddings"])

_bulk_lock = threading.Lock()
_bulk_state = {
    "running": False,
    "total": 0,
    "processed": 0,
    "embedded": 0,
    "skipped": 0,
    "failed": 0,
    "error": None,
}


def _extract_pdf_text_for_thesis(thesis, upload_dir):
    try:
        pdf_url = (thesis.get("pdf_url") or "")
        prefix = "/api/uploads/"
        if not pdf_url.startswith(prefix):
            return ""
        filename = pdf_url[len(prefix):]
        if (not filename or ".." in filename or "/" in filename
                or "\\" in filename or filename.startswith((".",))):
            return ""
        path = os.path.join(upload_dir, filename)
        if not os.path.exists(path):
            return ""
        import pymupdf
        text_parts = []
        with pymupdf.open(path) as doc:
            for page in doc:
                try:
                    text_parts.append(page.get_text())
                except Exception:
                    continue
        return "".join(text_parts)
    except Exception:
        return ""


def _embed_thesis_chunks(thesis_id, title, abstract, pdf_text=None):
    chunks = build_thesis_chunks(title, abstract, pdf_text)
    if not chunks:
        return None
    vectors = embedding_service.embed_batch(chunks)
    if not vectors or len(vectors) != len(chunks):
        return None
    db.replace_thesis_embeddings(
        thesis_id,
        list(zip(chunks, vectors)),
        embedding_service.model_name,
    )
    return len(chunks)


def _iter_all_theses(statuses, page_size=100):
    page = 1
    while True:
        result = db.list_theses(status=statuses, page=page, per_page=page_size)
        rows = result.get("theses", [])
        if not rows:
            return
        for row in rows:
            yield row
        if page >= result.get("pages", page):
            return
        page += 1


def _bulk_worker(upload_dir, refresh):
    with _bulk_lock:
        _bulk_state.update(running=True, processed=0, embedded=0,
                           skipped=0, failed=0, error=None)
    try:
        theses = list(_iter_all_theses(["published", "approved"]))
        with _bulk_lock:
            _bulk_state["total"] = len(theses)
        for t in theses:
            tid = t["id"]
            try:
                if not refresh and db.count_thesis_embedding_chunks(tid) > 0:
                    with _bulk_lock:
                        _bulk_state["skipped"] += 1
                else:
                    full = db.get_thesis_by_id(tid)
                    pdf_text = _extract_pdf_text_for_thesis(full or t, upload_dir)
                    n = _embed_thesis_chunks(
                        tid, t.get("title", ""), t.get("abstract", ""), pdf_text)
                    with _bulk_lock:
                        if n:
                            _bulk_state["embedded"] += 1
                        else:
                            _bulk_state["failed"] += 1
            except Exception:
                with _bulk_lock:
                    _bulk_state["failed"] += 1
            finally:
                with _bulk_lock:
                    _bulk_state["processed"] += 1
    except Exception as e:
        with _bulk_lock:
            _bulk_state["error"] = str(e)[:500]
    finally:
        with _bulk_lock:
            _bulk_state["running"] = False


@router.post("/api/embeddings/generate/{thesis_id}", dependencies=[Depends(admin_required)])
def generate_embedding(thesis_id: int):
    thesis = db.get_thesis_by_id(thesis_id)
    if not thesis:
        raise HTTPException(status_code=404, detail="Thesis not found")
    if not embedding_service.available:
        raise HTTPException(status_code=503, detail="Embedding service not available. Install sentence-transformers.")
    upload_dir = UPLOAD_DIR
    pdf_text = _extract_pdf_text_for_thesis(thesis, upload_dir)
    try:
        n = _embed_thesis_chunks(
            thesis_id, thesis.get("title", ""), thesis.get("abstract", ""), pdf_text)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to store embeddings: {str(e)[:300]}")
    if not n:
        raise HTTPException(status_code=500, detail="Failed to generate embedding")
    return {
        "message": "Embeddings generated",
        "thesis_id": thesis_id,
        "model": embedding_service.model_name,
        "chunks": n,
        "used_pdf": bool(pdf_text and pdf_text.strip()),
    }


@router.post("/api/embeddings/generate-bulk", status_code=202, dependencies=[Depends(admin_required)])
def generate_bulk_embeddings(request: Request, refresh: str = Query("false")):
    if not embedding_service.available:
        raise HTTPException(status_code=503, detail="Embedding service not available")
    with _bulk_lock:
        if _bulk_state["running"]:
            return {"message": "Backfill already running", "status": dict(_bulk_state)}
        _bulk_state.update(running=True, total=0, processed=0, embedded=0,
                           skipped=0, failed=0, error=None)
    refresh_bool = refresh.lower() == "true"
    upload_dir = UPLOAD_DIR
    worker = threading.Thread(target=_bulk_worker, args=(upload_dir, refresh_bool), daemon=True)
    worker.start()
    return {"message": "Backfill started", "refresh": refresh_bool}


@router.get("/api/embeddings/bulk-status", dependencies=[Depends(admin_required)])
def bulk_status():
    with _bulk_lock:
        return dict(_bulk_state)


@router.post("/api/embeddings/search", dependencies=[Depends(login_required)], tags=["Search"])
def search(data: SemanticSearchRequest = Body(default=None)):
    data = data.model_dump(exclude_unset=True) if data is not None else None
    if not data or "query" not in data:
        raise HTTPException(status_code=400, detail="Query is required")
    if not embedding_service.available:
        raise HTTPException(status_code=503, detail="Embedding service not available")
    query = data["query"]
    if not isinstance(query, str) or not query.strip():
        raise HTTPException(status_code=400, detail="Query must be a non-empty string")
    try:
        limit = int(data.get("limit", 10))
    except (TypeError, ValueError):
        raise HTTPException(status_code=400, detail="limit must be between 1 and 20")
    if not 1 <= limit <= 20:
        raise HTTPException(status_code=400, detail="limit must be between 1 and 20")
    query_vector = embedding_service.embed(query)
    if query_vector is None:
        raise HTTPException(status_code=500, detail="Failed to generate query embedding")
    theses = db.semantic_search(query_vector, limit=limit)
    return {"query": query, "results": theses, "count": len(theses)}