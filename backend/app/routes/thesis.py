"""Thesis routes — list, detail, create, update, delete."""

import os
from flask import Blueprint, request, jsonify, current_app
from .. import models as db
from ..auth import login_required, admin_required, decode_token
from ..models import get_user_by_id

thesis_bp = Blueprint("thesis", __name__)


def _pagination_args():
    """Return validated pagination parameters or an error response."""
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 20, type=int)
    if page is None or page < 1:
        return None, jsonify({"error": "page must be a positive integer"}), 400
    if per_page is None or not 1 <= per_page <= 100:
        return None, jsonify({"error": "per_page must be between 1 and 100"}), 400
    return (page, per_page), None, None


@thesis_bp.route("/api/theses", methods=["GET"])
def list_theses():
    """List theses with optional filters."""
    q = request.args.get("q")
    program_id = request.args.get("program_id", type=int)
    year_id = request.args.get("year_id", type=int)
    category_id = request.args.get("category_id", type=int)
    keyword = request.args.get("keyword")
    sort_by = request.args.get("sort_by")
    research_type = request.args.get("research_type")
    status = request.args.get("status")
    show_all = request.args.get("show_all", "false").lower() == "true"
    if show_all:
        # show_all exposes drafts/archived — require an admin token.
        auth = request.headers.get("Authorization", "")
        if not auth.startswith("Bearer "):
            return jsonify({"error": "Admin access required"}), 403
        try:
            payload = decode_token(auth.split(" ", 1)[1])
            user = get_user_by_id(int(payload.get("sub")))
        except Exception:
            return jsonify({"error": "Admin access required"}), 403
        if not user or not user.get("is_active") or user.get("role") != "admin":
            return jsonify({"error": "Admin access required"}), 403
        status = None  # show all statuses (admin only)
    elif not status:
        status = ['published', 'approved']
    
    pagination, error, status_code = _pagination_args()
    if error:
        return error, status_code
    page, per_page = pagination

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
    return jsonify(result), 200


@thesis_bp.route("/api/theses/<int:id>", methods=["GET"])
def get_thesis(id):
    """Get a single thesis by ID (drafts/archived require admin/faculty)."""
    thesis = db.get_thesis_by_id(id)
    if not thesis:
        return jsonify({"error": "Thesis not found"}), 404
    if thesis.get("status") not in ("published", "approved"):
        auth = request.headers.get("Authorization", "")
        if not auth.startswith("Bearer "):
            return jsonify({"error": "Thesis not found"}), 404
        try:
            payload = decode_token(auth.split(" ", 1)[1])
            user = get_user_by_id(int(payload.get("sub")))
        except Exception:
            return jsonify({"error": "Thesis not found"}), 404
        if not user or not user.get("is_active") or user.get("role") not in ("admin", "faculty"):
            return jsonify({"error": "Thesis not found"}), 404
    return jsonify(thesis), 200


@thesis_bp.route("/api/theses/<int:id>/recommend", methods=["GET"])
def recommend_theses(id):
    """Get recommended theses similar to the given thesis."""
    from ..services.embeddings import embedding_service
    
    thesis = db.get_thesis_by_id(id)
    if not thesis:
        return jsonify({"error": "Thesis not found"}), 404

    if not embedding_service.available:
        return jsonify({"error": "Embedding service not available"}), 503

    limit = request.args.get("limit", 5, type=int)
    if limit is None or not 1 <= limit <= 20:
        return jsonify({"error": "limit must be between 1 and 20"}), 400
    theses = db.recommend_for_thesis(id, limit=limit)

    return jsonify({
        "thesis_id": id,
        "theses": theses,
        "count": len(theses),
    }), 200


@thesis_bp.route("/api/dashboard/stats", methods=["GET"])
@admin_required
def dashboard_stats():
    """Get admin dashboard statistics."""
    stats = db.get_dashboard_stats()
    return jsonify(stats), 200


@thesis_bp.route("/api/stats/summary", methods=["GET"])
def public_stats():
    """Public repository summary for student/landing dashboards (no auth)."""
    return jsonify(db.get_public_stats()), 200


@thesis_bp.route("/api/dashboard/recent-activity", methods=["GET"])
@login_required
def dashboard_recent_activity():
    """Get recent activity for dashboards."""
    limit = request.args.get("limit", 10, type=int)
    if limit is None or not 1 <= limit <= 100:
        return jsonify({"error": "limit must be between 1 and 100"}), 400
    activity = db.recent_activity(limit=limit)
    return jsonify({"activity": activity}), 200


@thesis_bp.route("/api/faculty/dashboard", methods=["GET"])
@login_required
def faculty_dashboard():
    """Get faculty-specific dashboard data."""
    if request.current_user["role"] != "faculty":
        return jsonify({"error": "Faculty access required"}), 403
    stats = db.get_faculty_stats(request.current_user["email"])
    return jsonify(stats), 200


@thesis_bp.route("/api/faculty/activity", methods=["GET"])
@login_required
def faculty_activity():
    """Get activity for the current faculty's advisees."""
    limit = request.args.get("limit", 10, type=int)
    if request.current_user["role"] != "faculty":
        return jsonify({"error": "Faculty access required"}), 403
    if limit is None or not 1 <= limit <= 100:
        return jsonify({"error": "limit must be between 1 and 100"}), 400
    activity = db.get_faculty_activity(request.current_user["email"], limit=limit)
    return jsonify({"activity": activity}), 200


def _require_faculty():
    """Return (user, error_response, status_code) for faculty-only routes."""
    user = request.current_user
    if user["role"] != "faculty":
        return None, jsonify({"error": "Faculty access required"}), 403
    return user, None, None


def _valid_upload_url(pdf_url):
    """Check a client-supplied pdf_url points at a real file in uploads/.

    Lets faculty attach the PDF they just uploaded (server-generated name)
    without letting them write arbitrary paths into the column.
    """
    prefix = "/api/uploads/"
    if not pdf_url or not pdf_url.startswith(prefix):
        return False
    filename = pdf_url[len(prefix):]
    if (not filename or ".." in filename or filename.startswith(("/", "\\"))
            or "/" in filename or "\\" in filename or "%" in filename
            or ":" in filename):
        return False
    upload_dir = os.path.join(current_app.root_path, "uploads")
    return os.path.exists(os.path.join(upload_dir, filename))


@thesis_bp.route("/api/faculty/theses", methods=["GET"])
@login_required
def faculty_theses():
    """Full thesis records advised by the current faculty member."""
    user, error, code = _require_faculty()
    if error:
        return error, code
    pagination, error, code = _pagination_args()
    if error:
        return error, code
    page, per_page = pagination
    result = db.get_faculty_theses(user["email"], user_id=user["id"], page=page, per_page=per_page)
    return jsonify(result), 200


@thesis_bp.route("/api/faculty/advisees", methods=["GET"])
@login_required
def faculty_advisees():
    """Authors linked to theses advised by the current faculty member."""
    user, error, code = _require_faculty()
    if error:
        return error, code
    advisees = db.get_faculty_advisees(user["email"])
    return jsonify({"advisees": advisees, "total": len(advisees)}), 200


@thesis_bp.route("/api/faculty/analytics", methods=["GET"])
@login_required
def faculty_analytics():
    """Status/program/year breakdown of the faculty member's advised theses."""
    user, error, code = _require_faculty()
    if error:
        return error, code
    return jsonify(db.get_faculty_analytics(user["email"])), 200


@thesis_bp.route("/api/theses", methods=["POST"])
@login_required
def create_thesis():
    """Create a new thesis. Admins may set any status; faculty submissions
    are always forced to draft for admin review."""
    role = request.current_user["role"]
    if role not in ("admin", "faculty"):
        return jsonify({"error": "Admin or faculty access required"}), 403
    data = request.get_json()
    if not data:
        return jsonify({"error": "Missing request body"}), 400

    required = ["title", "abstract", "research_type", "program_id", "academic_year_id"]
    for field in required:
        if not data.get(field):
            return jsonify({"error": f"{field} is required"}), 400

    status = data.get("status", "draft")
    if role == "faculty":
        status = "draft"  # faculty cannot self-publish/archive
        # The submitter is always the single adviser (auto-provisioned).
        me = request.current_user
        data_adviser_id = db.ensure_adviser_for_email(me["email"], me["username"])
    else:
        if status not in ("draft", "approved", "published", "archived"):
            return jsonify({"error": "Invalid status"}), 400
        data_adviser_id = data.get("adviser_id")
        if data_adviser_id is not None:
            try:
                data_adviser_id = int(data_adviser_id)
            except (TypeError, ValueError):
                return jsonify({"error": "adviser_id must be an integer"}), 400
            if not db.get_adviser_by_id(data_adviser_id):
                return jsonify({"error": "Adviser not found"}), 404

    # Faculty pdf_url: only a just-uploaded file that really exists in
    # uploads/ is accepted — validated BEFORE the insert so a bad URL
    # can't leave an orphan draft behind.
    faculty_pdf_url = None
    if role == "faculty" and data.get("pdf_url"):
        if not _valid_upload_url(data["pdf_url"]):
            return jsonify({"error": "Invalid pdf_url — upload the PDF first"}), 400
        faculty_pdf_url = data["pdf_url"]

    thesis_id = db.create_thesis(
        title=data["title"],
        abstract=data["abstract"],
        research_type=data["research_type"],
        program_id=data["program_id"],
        academic_year_id=data["academic_year_id"],
        creator_id=request.current_user["id"],
        status=status,
        author_ids=data.get("author_ids"),
        adviser_id=data_adviser_id,
        category_ids=data.get("category_ids"),
        keyword_terms=data.get("keyword_terms"),
        pdf_url=data.get("pdf_url") if role == "admin" else faculty_pdf_url,
    )

    # Auto-generate chunked embeddings if service is available (best-effort).
    # At creation time there is no PDF yet, so this covers title+abstract;
    # the upload route re-embeds with the full PDF body when it arrives.
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
        pass  # Never block thesis creation on embedding failure

    thesis = db.get_thesis_by_id(thesis_id)
    return jsonify(thesis), 201


@thesis_bp.route("/api/theses/<int:id>", methods=["PUT"])
@login_required
def update_thesis(id):
    """Update a thesis. Admins: anything. Faculty: own drafts only, and
    never status/pdf_url (status changes go through admin review)."""
    existing = db.get_thesis_by_id(id)
    if not existing:
        return jsonify({"error": "Thesis not found"}), 404

    data = request.get_json()
    if not data:
        return jsonify({"error": "Missing request body"}), 400

    role = request.current_user["role"]
    if role == "faculty":
        if existing.get("creator_id") != request.current_user["id"]:
            return jsonify({"error": "You can only edit theses you submitted"}), 403
        if existing.get("status") != "draft":
            return jsonify({"error": "Only drafts can be edited"}), 403
        data = {k: v for k, v in data.items() if k not in ("status", "pdf_url", "adviser_id", "co_adviser_id")}
        if not data:
            return jsonify({"error": "Nothing editable in request body"}), 400
    elif role != "admin":
        return jsonify({"error": "Admin or faculty access required"}), 403
    else:
        # Single adviser only: an explicit adviser_id replaces the link.
        data.pop("co_adviser_id", None)
        if "adviser_id" in data:
            primary = data.pop("adviser_id")
            if primary is None:
                data["adviser_id"] = None
            else:
                try:
                    primary = int(primary)
                except (TypeError, ValueError):
                    return jsonify({"error": "adviser_id must be an integer"}), 400
                if not db.get_adviser_by_id(primary):
                    return jsonify({"error": "Adviser not found"}), 404
                data["adviser_id"] = primary

    try:
        db.update_thesis(id, **data)
    except Exception as e:
        return jsonify({"error": f"Update failed: {str(e)}"}), 400
    thesis = db.get_thesis_by_id(id)

    # Keep embeddings fresh when title/abstract change — but only for theses
    # WITHOUT a local PDF, so we never wipe full-PDF chunks with a
    # title+abstract-only re-embed. Theses with PDFs refresh via upload or
    # the admin generate endpoint (which includes the PDF body).
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
    return jsonify(thesis), 200


@thesis_bp.route("/api/theses/<int:id>", methods=["DELETE"])
@login_required
def delete_thesis(id):
    """Delete a thesis. Admins: anything. Faculty: own drafts only."""
    existing = db.get_thesis_by_id(id)
    if not existing:
        return jsonify({"error": "Thesis not found"}), 404

    role = request.current_user["role"]
    if role == "faculty":
        if existing.get("creator_id") != request.current_user["id"]:
            return jsonify({"error": "You can only delete theses you submitted"}), 403
        if existing.get("status") != "draft":
            return jsonify({"error": "Only drafts can be deleted"}), 403
    elif role != "admin":
        return jsonify({"error": "Admin or faculty access required"}), 403

    db.delete_thesis(id)
    return jsonify({"message": "Thesis deleted"}), 200
