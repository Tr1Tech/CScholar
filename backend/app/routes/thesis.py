"""Thesis routes -- list, detail, create, update, delete."""

import os
from fastapi import APIRouter, Request, Depends, HTTPException, Body, Query
from fastapi import status as http_status
from .. import models as db
from ..auth import login_required, admin_required, decode_token
from ..models import get_user_by_id, ThesisStatusConflict
from ..config import UPLOAD_DIR

router = APIRouter()


def _pagination_args(page, per_page):
    if page is None or page < 1:
        raise HTTPException(status_code=400, detail="page must be a positive integer")
    if per_page is None or not 1 <= per_page <= 100:
        raise HTTPException(status_code=400, detail="per_page must be between 1 and 100")
    return page, per_page


@router.get("/api/theses")
def list_theses(
    request: Request,
    q: str = None,
    program_id: int = None,
    year_id: int = None,
    category_id: int = None,
    keyword: str = None,
    sort_by: str = None,
    research_type: str = None,
    status: str = None,
    show_all: str = "false",
    page: int = Query(1),
    per_page: int = Query(20),
):
    show_all_bool = show_all.lower() == "true"
    if show_all_bool:
        auth = request.headers.get("Authorization", "")
        if not auth.startswith("Bearer "):
            raise HTTPException(status_code=403, detail="Admin access required")
        try:
            payload = decode_token(auth.split(" ", 1)[1])
            user = get_user_by_id(int(payload.get("sub")))
        except Exception:
            raise HTTPException(status_code=403, detail="Admin access required")
        if not user or not user.get("is_active") or user.get("role") != "admin":
            raise HTTPException(status_code=403, detail="Admin access required")
        status = None
    elif not status:
        status = ["published", "approved"]

    page, per_page = _pagination_args(page, per_page)
    result = db.list_theses(
        q=q,
        program_id=program_id,
        year_id=year_id,
        category_id=category_id,
        keyword=keyword,
        sort_by=sort_by,
        research_type=research_type,
        status=status,
        page=page,
        per_page=per_page,
    )
    return result


@router.get("/api/theses/{id}")
def get_thesis(id: int, request: Request):
    thesis = db.get_thesis_by_id(id)
    if not thesis:
        raise HTTPException(status_code=404, detail="Thesis not found")
    if thesis.get("status") not in ("published", "approved"):
        auth = request.headers.get("Authorization", "")
        if not auth.startswith("Bearer "):
            raise HTTPException(status_code=404, detail="Thesis not found")
        try:
            payload = decode_token(auth.split(" ", 1)[1])
            user = get_user_by_id(int(payload.get("sub")))
        except Exception:
            raise HTTPException(status_code=404, detail="Thesis not found")
        if not user or not user.get("is_active") or user.get("role") not in ("admin", "faculty"):
            raise HTTPException(status_code=404, detail="Thesis not found")
    return thesis


@router.get("/api/theses/{id}/recommend")
def recommend_theses(id: int, limit: int = Query(5)):
    from ..services.embeddings import embedding_service
    thesis = db.get_thesis_by_id(id)
    if not thesis:
        raise HTTPException(status_code=404, detail="Thesis not found")
    if not embedding_service.available:
        raise HTTPException(status_code=503, detail="Embedding service not available")
    if limit is None or not 1 <= limit <= 20:
        raise HTTPException(status_code=400, detail="limit must be between 1 and 20")
    theses = db.recommend_for_thesis(id, limit=limit)
    return {"thesis_id": id, "theses": theses, "count": len(theses)}


@router.get("/api/dashboard/stats", dependencies=[Depends(admin_required)])
def dashboard_stats():
    stats = db.get_dashboard_stats()
    return stats


@router.get("/api/stats/summary")
def public_stats():
    return db.get_public_stats()


@router.get("/api/dashboard/recent-activity", dependencies=[Depends(login_required)])
def dashboard_recent_activity(limit: int = Query(10)):
    if limit is None or not 1 <= limit <= 100:
        raise HTTPException(status_code=400, detail="limit must be between 1 and 100")
    activity = db.recent_activity(limit=limit)
    return {"activity": activity}


@router.get("/api/faculty/dashboard", dependencies=[Depends(login_required)])
def faculty_dashboard(request: Request):
    if request.state.current_user["role"] != "faculty":
        raise HTTPException(status_code=403, detail="Faculty access required")
    stats = db.get_faculty_stats(request.state.current_user["email"])
    return stats


@router.get("/api/faculty/activity", dependencies=[Depends(login_required)])
def faculty_activity(request: Request, limit: int = Query(10)):
    if request.state.current_user["role"] != "faculty":
        raise HTTPException(status_code=403, detail="Faculty access required")
    if limit is None or not 1 <= limit <= 100:
        raise HTTPException(status_code=400, detail="limit must be between 1 and 100")
    activity = db.get_faculty_activity(request.state.current_user["email"], limit=limit)
    return {"activity": activity}


def _require_faculty(request):
    user = request.state.current_user
    if user["role"] != "faculty":
        raise HTTPException(status_code=403, detail="Faculty access required")
    return user


def _valid_upload_url(pdf_url):
    prefix = "/api/uploads/"
    if not pdf_url or not pdf_url.startswith(prefix):
        return False
    filename = pdf_url[len(prefix):]
    if (not filename or ".." in filename or filename.startswith(("/", "\\")) or "/" in filename or "\\" in filename or "%" in filename or ":" in filename):
        return False
    upload_dir = UPLOAD_DIR
    return os.path.exists(os.path.join(upload_dir, filename))


@router.get("/api/faculty/theses", dependencies=[Depends(login_required)])
def faculty_theses(request: Request, page: int = Query(1), per_page: int = Query(20)):
    user = _require_faculty(request)
    page, per_page = _pagination_args(page, per_page)
    result = db.get_faculty_theses(user["email"], user_id=user["id"], page=page, per_page=per_page)
    return result


@router.get("/api/faculty/advisees", dependencies=[Depends(login_required)])
def faculty_advisees(request: Request):
    user = _require_faculty(request)
    advisees = db.get_faculty_advisees(user["email"])
    return {"advisees": advisees, "total": len(advisees)}


@router.get("/api/faculty/analytics", dependencies=[Depends(login_required)])
def faculty_analytics(request: Request):
    user = _require_faculty(request)
    return db.get_faculty_analytics(user["email"])


@router.post("/api/theses", status_code=201, dependencies=[Depends(login_required)])
def create_thesis(request: Request, data: dict = Body(default=None)):
    role = request.state.current_user["role"]
    if role not in ("admin", "faculty"):
        raise HTTPException(status_code=403, detail="Admin or faculty access required")
    if not data:
        raise HTTPException(status_code=400, detail="Missing request body")
    required = ["title", "abstract", "research_type", "program_id", "academic_year_id"]
    for field in required:
        if not data.get(field):
            raise HTTPException(status_code=400, detail=f"{field} is required")

    status = data.get("status", "draft")
    if role == "faculty":
        status = "draft"
        me = request.state.current_user
        data_adviser_id = db.ensure_adviser_for_email(me["email"], me["username"])
    else:
        if status not in ("draft", "approved", "published", "archived"):
            raise HTTPException(status_code=400, detail="Invalid status")
        data_adviser_id = data.get("adviser_id")
        if data_adviser_id is not None:
            try:
                data_adviser_id = int(data_adviser_id)
            except (TypeError, ValueError):
                raise HTTPException(status_code=400, detail="adviser_id must be an integer")
            if not db.get_adviser_by_id(data_adviser_id):
                raise HTTPException(status_code=404, detail="Adviser not found")

    faculty_pdf_url = None
    if role == "faculty" and data.get("pdf_url"):
        if not _valid_upload_url(data["pdf_url"]):
            raise HTTPException(status_code=400, detail="Invalid pdf_url - upload the PDF first")
        faculty_pdf_url = data["pdf_url"]

    try:
        dupes = db.find_possible_duplicates(data.get("title", ""), data.get("abstract", ""))
    except Exception:
        dupes = []
    if dupes and not data.get("confirm_duplicate"):
        raise HTTPException(status_code=409, detail={
            "error": "Possible duplicate thesis found. Resubmit with confirm_duplicate:true to proceed anyway.",
            "possible_duplicates": dupes,
        })

    thesis_id = db.create_thesis(
        title=data["title"],
        abstract=data["abstract"],
        research_type=data["research_type"],
        program_id=data["program_id"],
        academic_year_id=data["academic_year_id"],
        creator_id=request.state.current_user["id"],
        status=status,
        author_ids=data.get("author_ids"),
        adviser_id=data_adviser_id,
        category_ids=data.get("category_ids"),
        keyword_terms=data.get("keyword_terms"),
        pdf_url=data.get("pdf_url") if role == "admin" else faculty_pdf_url,
    )

    try:
        from ..services.chunking import build_thesis_chunks
        from ..services.embeddings import embedding_service
        if embedding_service.available:
            chunks = build_thesis_chunks(data["title"], data["abstract"])
            if chunks:
                vectors = embedding_service.embed_batch(chunks)
                if vectors and len(vectors) == len(chunks):
                    db.replace_thesis_embeddings(
                        thesis_id,
                        list(zip(chunks, vectors)),
                        embedding_service.model_name,
                    )
    except Exception:
        pass

    thesis = db.get_thesis_by_id(thesis_id)
    if dupes:
        thesis["duplicate_warning"] = dupes
    return thesis


@router.put("/api/theses/{id}", dependencies=[Depends(login_required)])
def update_thesis(id: int, request: Request, data: dict = Body(default=None)):
    existing = db.get_thesis_by_id(id)
    if not existing:
        raise HTTPException(status_code=404, detail="Thesis not found")
    if not data:
        raise HTTPException(status_code=400, detail="Missing request body")

    role = request.state.current_user["role"]
    if role == "faculty":
        if existing.get("creator_id") != request.state.current_user["id"]:
            raise HTTPException(status_code=403, detail="You can only edit theses you submitted")
        if existing.get("status") != "draft":
            raise HTTPException(status_code=403, detail="Only drafts can be edited")
        data = {k: v for k, v in data.items() if k not in ("status", "pdf_url", "adviser_id", "co_adviser_id")}
        if not data:
            raise HTTPException(status_code=400, detail="Nothing editable in request body")
    elif role != "admin":
        raise HTTPException(status_code=403, detail="Admin or faculty access required")
    else:
        data.pop("co_adviser_id", None)
        if "adviser_id" in data:
            primary = data.pop("adviser_id")
            if primary is None:
                data["adviser_id"] = None
            else:
                try:
                    primary = int(primary)
                except (TypeError, ValueError):
                    raise HTTPException(status_code=400, detail="adviser_id must be an integer")
                if not db.get_adviser_by_id(primary):
                    raise HTTPException(status_code=404, detail="Adviser not found")
                data["adviser_id"] = primary

    try:
        db.update_thesis(id, **data)
    except ThesisStatusConflict as e:
        raise HTTPException(status_code=409, detail={
            "error": "Thesis is no longer pending review.",
            "thesis_id": e.thesis_id,
            "required_statuses": e.required_statuses,
            "current_status": e.current_status,
        })
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Update failed: {str(e)}")
    thesis = db.get_thesis_by_id(id)

    if "title" in data or "abstract" in data:
        try:
            from ..services.chunking import build_thesis_chunks
            from ..services.embeddings import embedding_service
            if (embedding_service.available and not (thesis.get("pdf_url") or "")):
                chunks = build_thesis_chunks(thesis["title"], thesis["abstract"])
                if chunks:
                    vectors = embedding_service.embed_batch(chunks)
                    if vectors and len(vectors) == len(chunks):
                        db.replace_thesis_embeddings(
                            id, list(zip(chunks, vectors)),
                            embedding_service.model_name)
        except Exception:
            pass
    return thesis


@router.delete("/api/theses/{id}", dependencies=[Depends(login_required)])
def delete_thesis(id: int, request: Request):
    existing = db.get_thesis_by_id(id)
    if not existing:
        raise HTTPException(status_code=404, detail="Thesis not found")
    role = request.state.current_user["role"]
    if role == "faculty":
        if existing.get("creator_id") != request.state.current_user["id"]:
            raise HTTPException(status_code=403, detail="You can only delete theses you submitted")
        if existing.get("status") != "draft":
            raise HTTPException(status_code=403, detail="Only drafts can be deleted")
    elif role != "admin":
        raise HTTPException(status_code=403, detail="Admin or faculty access required")
    db.delete_thesis(id)
    return {"message": "Thesis deleted"}