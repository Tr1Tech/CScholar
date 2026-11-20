"""Thesis routes -- list, detail, create, update, delete."""

import os
import re
from fastapi import APIRouter, Request, Depends, HTTPException, Body, Query
from .. import models as db
from ..auth import login_required, admin_required, decode_token
from ..models import get_user_by_id, ThesisStatusConflict
from ..config import UPLOAD_DIR
from ..services.uploads import upload_path
from ..schemas import BulkStatusRequest, ThesisCreateRequest, ThesisUpdateRequest

router = APIRouter()


def _pagination_args(page, per_page):
    if page is None or page < 1:
        raise HTTPException(status_code=400, detail="page must be a positive integer")
    if per_page is None or not 1 <= per_page <= 100:
        raise HTTPException(status_code=400, detail="per_page must be between 1 and 100")
    return page, per_page


@router.get("/api/theses", tags=["Theses"])
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
    elif not status:
        # The student-facing repository is publication-only. `approved` is an
        # internal review state; it stays visible to staff and the study's own
        # people through the detail guards, not in public search/browse.
        status = ["published"]

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
    if not show_all_bool:
        # Reviewer notes are internal. The public list never carries them, even
        # for a published record that was once returned.
        for item in result["theses"]:
            item.pop("review_notes", None)
    return result


@router.get("/api/theses/{id}", tags=["Theses"])
def get_thesis(id: int, request: Request):
    thesis = db.get_thesis_by_id(id)
    if not thesis:
        raise HTTPException(status_code=404, detail="Thesis not found")
    user = None
    auth = request.headers.get("Authorization", "")
    if auth.startswith("Bearer "):
        try:
            payload = decode_token(auth.split(" ", 1)[1])
            user = get_user_by_id(int(payload.get("sub")))
        except Exception:
            user = None
    if thesis.get("status") != "published":
        if not user or not user.get("is_active"):
            raise HTTPException(status_code=404, detail="Thesis not found")
        if not db.user_can_view_unpublished(thesis, user):
            raise HTTPException(status_code=404, detail="Thesis not found")
    else:
        can_see_notes = bool(
            user
            and user.get("is_active")
            and db.user_can_view_unpublished(thesis, user)
        )
        if not can_see_notes:
            # A published record is public, but its review trail is internal.
            thesis.pop("review_notes", None)
            thesis["reviews"] = []
    return thesis


@router.get("/api/theses/{id}/recommend", tags=["Search"])
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


@router.get("/api/dashboard/stats", dependencies=[Depends(admin_required)], tags=["Dashboard"])
def dashboard_stats():
    stats = db.get_dashboard_stats()
    return stats


@router.get("/api/stats/summary", tags=["System"])
def public_stats():
    return db.get_public_stats()


@router.get("/api/dashboard/recent-activity", dependencies=[Depends(login_required)], tags=["Dashboard"])
def dashboard_recent_activity(limit: int = Query(10), page: int = Query(1)):
    if limit is None or not 1 <= limit <= 100:
        raise HTTPException(status_code=400, detail="limit must be between 1 and 100")
    if page is None or page < 1:
        raise HTTPException(status_code=400, detail="page must be 1 or greater")
    activity, total = db.recent_activity(limit=limit, offset=(page - 1) * limit)
    return {"activity": activity, "total": total, "page": page, "limit": limit}


@router.get("/api/faculty/dashboard", dependencies=[Depends(login_required)], tags=["Dashboard"],
            openapi_extra={"x-required-roles": ["faculty"]})
def faculty_dashboard(request: Request):
    if request.state.current_user["role"] != "faculty":
        raise HTTPException(status_code=403, detail="Faculty access required")
    stats = db.get_faculty_stats(request.state.current_user["email"])
    return stats


@router.get("/api/faculty/activity", dependencies=[Depends(login_required)], tags=["Dashboard"],
            openapi_extra={"x-required-roles": ["faculty"]})
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
    path = upload_path(pdf_url)
    return bool(path) and os.path.isfile(path)


def _original_upload_name(pdf_url):
    """Recover the user's filename from '<uuid32>_<original>' storage names."""
    stored = pdf_url.rsplit("/", 1)[-1]
    return re.sub(r"^[0-9a-fA-F]{32}_", "", stored) or stored


@router.get("/api/faculty/theses", dependencies=[Depends(login_required)], tags=["Theses"],
            openapi_extra={"x-required-roles": ["faculty"]})
def faculty_theses(request: Request, page: int = Query(1), per_page: int = Query(20)):
    user = _require_faculty(request)
    page, per_page = _pagination_args(page, per_page)
    result = db.get_faculty_theses(user["email"], user_id=user["id"], page=page, per_page=per_page)
    return result


@router.get("/api/faculty/advisees", dependencies=[Depends(login_required)], tags=["Metadata"],
            openapi_extra={"x-required-roles": ["faculty"]})
def faculty_advisees(request: Request):
    user = _require_faculty(request)
    advisees = db.get_faculty_advisees(user["email"])
    return {"advisees": advisees, "total": len(advisees)}


@router.get("/api/faculty/analytics", dependencies=[Depends(login_required)], tags=["Dashboard"],
            openapi_extra={"x-required-roles": ["faculty"]})
def faculty_analytics(request: Request):
    user = _require_faculty(request)
    return db.get_faculty_analytics(user["email"])


@router.post("/api/theses", status_code=201, dependencies=[Depends(login_required)], tags=["Theses"],
             openapi_extra={"x-required-roles": ["admin", "faculty"]})
def create_thesis(request: Request, data: ThesisCreateRequest = Body(default=None)):
    data = data.model_dump(exclude_unset=True) if data is not None else None
    role = request.state.current_user["role"]
    if role not in ("admin", "faculty"):
        raise HTTPException(status_code=403, detail="Admin or faculty access required")
    if not data:
        raise HTTPException(status_code=400, detail="Missing request body")
    required = ["title", "abstract", "research_type", "program_id", "academic_year_id"]
    for field in required:
        if not data.get(field):
            raise HTTPException(status_code=400, detail=f"{field} is required")

    # Validate foreign keys before insert. Without this, a missing program or
    # academic year (easy to hit on a fresh database with empty dropdowns)
    # surfaces as a ForeignKeyViolation and a 500 instead of a usable error.
    if not db.get_program_by_id(data["program_id"]):
        raise HTTPException(status_code=400, detail="program_id does not exist")
    if not db.get_academic_year_by_id(data["academic_year_id"]):
        raise HTTPException(status_code=400, detail="academic_year_id does not exist")
    if data["research_type"] not in ("Thesis", "Capstone"):
        raise HTTPException(
            status_code=400, detail="research_type must be 'Thesis' or 'Capstone'"
        )

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

    stored_pdf_url = data.get("pdf_url") if role == "admin" else faculty_pdf_url
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
        pdf_url=stored_pdf_url,
        approved_by=request.state.current_user["id"] if role == "admin" else None,
    )

    # Persist the upload metadata for a PDF attached during creation. The
    # upload endpoint could not do it (no thesis id existed yet), which left
    # v_thesis_admin_overview.file_count at 0 while has_pdf was true.
    if stored_pdf_url and _valid_upload_url(stored_pdf_url):
        try:
            stored_name = stored_pdf_url.rsplit("/", 1)[-1]
            db.create_thesis_file(
                thesis_id=thesis_id,
                filename=_original_upload_name(stored_pdf_url),
                file_path=stored_pdf_url,
                file_size=os.path.getsize(os.path.join(UPLOAD_DIR, stored_name)),
                mime_type="application/pdf",
                uploaded_by=request.state.current_user["id"],
            )
        except Exception:
            pass

    # Index for semantic search off the request thread. Loading the embedding
    # model on a cold process takes tens of seconds; doing it inline made the
    # first submission after every backend restart look like a hang. Passing
    # the PDF URL makes the worker include the manuscript body, so a study
    # created with an attachment is indexed on title + abstract + PDF content.
    try:
        from ..services.indexing import embed_thesis_async
        embed_thesis_async(
            thesis_id, data["title"], data["abstract"],
            pdf_url=stored_pdf_url,
        )
    except Exception:
        pass

    thesis = db.get_thesis_by_id(thesis_id)
    if dupes:
        thesis["duplicate_warning"] = dupes
    return thesis


@router.put("/api/theses/{id}", dependencies=[Depends(login_required)], tags=["Theses"],
            openapi_extra={"x-required-roles": ["admin", "faculty"]})
def update_thesis(id: int, request: Request, data: ThesisUpdateRequest = Body(default=None)):
    data = data.model_dump(exclude_unset=True) if data is not None else None
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
        data = {k: v for k, v in data.items() if k not in ("status", "pdf_url", "adviser_id", "co_adviser_id", "review_notes")}
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

        # Status changes are admin decisions: stamp who released it and record
        # the decision in the review trail. The DB layer sets approved_at and
        # clears the stamp again when it returns to draft.
        if data.get("status") is not None:
            data["actor_id"] = request.state.current_user["id"]
            if data["status"] == "approved":
                data["approved_by"] = request.state.current_user["id"]

    if data.get("status") is not None and data.get("status") not in (
        "draft", "approved", "published", "archived"
    ):
        raise HTTPException(status_code=400, detail="Invalid status")

    try:
        db.update_thesis(id, **data)
    except ThesisStatusConflict as e:
        raise HTTPException(status_code=409, detail={
            "error": "This status change is not allowed from the study's current status.",
            "thesis_id": e.thesis_id,
            "required_statuses": e.required_statuses,
            "current_status": e.current_status,
        })
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Update failed: {str(e)}")
    thesis = db.get_thesis_by_id(id)

    # Admin PUTs can set pdf_url directly, bypassing /api/upload/pdf. Keep
    # thesis_files in sync so v_thesis_admin_overview.file_count never
    # disagrees with theses.pdf_url.
    if role == "admin" and isinstance(data.get("pdf_url"), str):
        try:
            new_pdf_url = data["pdf_url"]
            current_path = (db.get_thesis_file(id) or {}).get("file_path")
            if not new_pdf_url:
                # Explicitly cleared: the stored file is no longer active.
                db.delete_thesis_files(id)
            elif _valid_upload_url(new_pdf_url):
                # Only rewrite when the active file actually changed; leaving
                # an unchanged attachment alone preserves uploaded_at.
                if current_path != new_pdf_url:
                    stored_name = new_pdf_url.rsplit("/", 1)[-1]
                    db.replace_thesis_file(
                        thesis_id=id,
                        filename=_original_upload_name(new_pdf_url),
                        file_path=new_pdf_url,
                        file_size=os.path.getsize(
                            os.path.join(UPLOAD_DIR, stored_name)
                        ),
                        mime_type="application/pdf",
                        uploaded_by=request.state.current_user["id"],
                    )
            elif current_path is not None:
                # The active PDF is no longer a managed upload, so the old
                # metadata row is stale.
                db.delete_thesis_files(id)
        except Exception:
            pass

    if "title" in data or "abstract" in data:
        try:
            from ..services.indexing import embed_thesis_async
            # Pass the stored PDF URL when there is one so an edit rebuilds the
            # full index (title + abstract + manuscript) instead of dropping
            # the PDF chunks that upload.py wrote.
            embed_thesis_async(
                id, thesis["title"], thesis["abstract"],
                pdf_url=thesis.get("pdf_url") or None,
            )
        except Exception:
            pass
    return thesis


@router.post(
    "/api/theses/bulk-status",
    dependencies=[Depends(admin_required)],
    tags=["Theses"],
    openapi_extra={"x-required-roles": ["admin"]},
)
def bulk_status(request: Request, data: BulkStatusRequest = Body(default=None)):
    """Move many studies through the same guarded lifecycle, row by row.

    The per-row guard is shared with the single-record route: a draft can be
    approved, an approved study can be published, and anything else is
    reported as skipped instead of failing the whole batch.
    """
    if not data or not data.ids:
        raise HTTPException(status_code=400, detail="ids is required")
    target = (data.status or "").strip().lower()
    if target not in ("approved", "published"):
        raise HTTPException(
            status_code=400, detail="status must be 'approved' or 'published'"
        )

    ids = list(dict.fromkeys(int(i) for i in data.ids))[:100]
    allowed = db.THESIS_STATUS_SOURCES.get(target, ())
    verb = "approve" if target == "approved" else "publish"
    actor_id = request.state.current_user["id"]
    updated = []
    skipped = []

    for thesis_id in ids:
        thesis = db.get_thesis_by_id(thesis_id)
        if not thesis:
            skipped.append({"id": thesis_id, "reason": "not found"})
            continue
        if thesis.get("status") not in allowed:
            skipped.append(
                {
                    "id": thesis_id,
                    "reason": f"cannot {verb} from status '{thesis.get('status')}'",
                }
            )
            continue
        changes = {"status": target, "actor_id": actor_id}
        if target == "approved":
            changes["approved_by"] = actor_id
        try:
            db.update_thesis(thesis_id, **changes)
            updated.append(thesis_id)
        except ThesisStatusConflict:
            skipped.append(
                {"id": thesis_id, "reason": "changed by another reviewer"}
            )
        except Exception as exc:
            skipped.append({"id": thesis_id, "reason": str(exc)[:200]})

    return {
        "requested": len(ids),
        "status": target,
        "updated": updated,
        "skipped": skipped,
    }


@router.delete("/api/theses/{id}", dependencies=[Depends(login_required)], tags=["Theses"],
               openapi_extra={"x-required-roles": ["admin", "faculty"]})
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