"""Embedding routes -- generate and store thesis embeddings (full-PDF chunking)."""

import threading

from fastapi import APIRouter, Request, Depends, HTTPException, Body, Query
from .. import models as db
from ..audit import log_security_event
from ..auth import login_required, admin_required
from ..services.embeddings import embedding_service
from ..services.chunking import build_thesis_chunks
from ..services.indexing import pdf_text_from_url
from ..schemas import SemanticSearchRequest

router = APIRouter()

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


def _bulk_worker(refresh):
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
                    pdf_text = pdf_text_from_url((full or t).get("pdf_url"))
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


@router.post("/api/embeddings/generate/{thesis_id}", dependencies=[Depends(admin_required)], tags=["Embeddings"])
def generate_embedding(thesis_id: int, request: Request):
    thesis = db.get_thesis_by_id(thesis_id)
    if not thesis:
        raise HTTPException(status_code=404, detail="Thesis not found")
    if not embedding_service.available:
        raise HTTPException(status_code=503, detail="Embedding service not available. Install sentence-transformers.")
    pdf_text = pdf_text_from_url(thesis.get("pdf_url"))
    try:
        n = _embed_thesis_chunks(
            thesis_id, thesis.get("title", ""), thesis.get("abstract", ""), pdf_text)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to store embeddings: {str(e)[:300]}")
    if not n:
        raise HTTPException(status_code=500, detail="Failed to generate embedding")
    log_security_event(
        "embeddings_generated",
        actor=request.state.current_user,
        request=request,
        entity_type="thesis",
        entity_id=thesis_id,
        summary=f"Generated embeddings for study {thesis_id}",
        details={"chunks": n, "model": embedding_service.model_name},
    )
    return {
        "message": "Embeddings generated",
        "thesis_id": thesis_id,
        "model": embedding_service.model_name,
        "chunks": n,
        "used_pdf": bool(pdf_text and pdf_text.strip()),
    }


@router.post("/api/embeddings/generate-bulk", status_code=202, dependencies=[Depends(admin_required)], tags=["Embeddings"])
def generate_bulk_embeddings(request: Request, refresh: str = Query("false")):
    if not embedding_service.available:
        raise HTTPException(status_code=503, detail="Embedding service not available")
    with _bulk_lock:
        if _bulk_state["running"]:
            return {"message": "Backfill already running", "status": dict(_bulk_state)}
        _bulk_state.update(running=True, total=0, processed=0, embedded=0,
                           skipped=0, failed=0, error=None)
    refresh_bool = refresh.lower() == "true"
    worker = threading.Thread(target=_bulk_worker, args=(refresh_bool,), daemon=True)
    worker.start()
    log_security_event(
        "embeddings_backfill_started",
        actor=request.state.current_user,
        request=request,
        entity_type="embedding_index",
        summary=f"Started embedding backfill (refresh={refresh_bool})",
    )
    return {"message": "Backfill started", "refresh": refresh_bool}


@router.get("/api/embeddings/bulk-status", dependencies=[Depends(admin_required)], tags=["Embeddings"])
def bulk_status():
    with _bulk_lock:
        return dict(_bulk_state)


@router.post("/api/embeddings/search", dependencies=[Depends(login_required)], tags=["Search"])
def search(request: Request, data: SemanticSearchRequest = Body(default=None)):
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
    # search_logs is an existing, documented table. Logging is diagnostics:
    # it must never fail the search itself. `mode` keeps the semantic call
    # distinguishable from the keyword listing the repository also requests.
    try:
        db.log_search(
            request.state.current_user["id"],
            query,
            len(theses),
            {"mode": "semantic"},
        )
    except Exception:
        pass
    return {"query": query, "results": theses, "count": len(theses)}