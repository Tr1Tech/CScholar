"""Admin bulk import routes.

The librarian uploads a CSV + PDFs, sees a validation preview, then confirms.
The batch itself runs in a background thread; this router only stores the
upload, returns the preview, and reports progress from ``import_jobs``.
"""

import csv
import io
import threading

from fastapi import APIRouter, Depends, File, HTTPException, Request, Response, UploadFile

from .. import models as db
from ..auth import admin_required
from ..services import import_jobs, importing
from ..services.uploads import secure_filename

router = APIRouter(tags=["Bulk Import"])

MAX_PDF_FILES = import_jobs.MAX_PDFS


def _job_or_404(job_id):
    job = db.get_import_job(job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Import job not found")
    return job


@router.get(
    "/api/import/template",
    dependencies=[Depends(admin_required)],
    openapi_extra={"x-required-roles": ["admin"]},
)
def download_template():
    content = "\ufeff" + importing.template_csv()
    return Response(
        content=content.encode("utf-8"),
        media_type="text/csv; charset=utf-8",
        headers={
            "Content-Disposition": 'attachment; filename="cscholar_import_template.csv"'
        },
    )


@router.post(
    "/api/import/preview",
    dependencies=[Depends(admin_required)],
    openapi_extra={"x-required-roles": ["admin"]},
)
async def preview_import(
    request: Request,
    csv_file: UploadFile = File(...),
    pdf_files: list[UploadFile] | None = File(default=None),
):
    """Store the upload, validate every row, and return the preview.

    Nothing is written to ``theses``, authors, or keywords here. The staging
    folder is kept so [run_import] does not need a second upload.
    """
    if not csv_file.filename or not csv_file.filename.lower().endswith(".csv"):
        raise HTTPException(status_code=400, detail="Choose a .csv file")
    if pdf_files and len(pdf_files) > MAX_PDF_FILES:
        raise HTTPException(
            status_code=400, detail=f"Too many PDFs (maximum {MAX_PDF_FILES})"
        )
    if csv_file.size is not None and csv_file.size > import_jobs.MAX_CSV_BYTES:
        raise HTTPException(status_code=413, detail="CSV is larger than 5 MB")

    csv_bytes = await csv_file.read()
    job_id = db.create_import_job(
        created_by=request.state.current_user["id"],
        csv_filename=secure_filename(csv_file.filename),
    )
    try:
        import_jobs.prepare_job_dir(job_id)
        import_jobs.save_csv(job_id, csv_bytes)
        import_jobs.save_pdfs(
            job_id,
            [
                (upload.filename or "", upload.file)
                for upload in (pdf_files or [])
            ],
        )

        raw_rows = importing.read_csv(import_jobs.csv_path(job_id))
        rows = importing.validate_rows(
            raw_rows, import_jobs.pdf_dir(job_id), importing.load_lookup()
        )
        if not rows:
            raise ValueError("The CSV has no data rows")

        db.update_import_job(
            job_id,
            total_rows=len(rows),
            error_count=sum(1 for row in rows if row.errors),
            rows=[importing.row_json(row) for row in rows],
        )
        return db.get_import_job(job_id)
    except Exception as exc:
        import_jobs.cleanup_job_dir(job_id)
        db.delete_import_job(job_id)
        if isinstance(exc, HTTPException):
            raise
        raise HTTPException(status_code=400, detail=str(exc))


@router.post(
    "/api/import/{job_id}/run",
    dependencies=[Depends(admin_required)],
    openapi_extra={"x-required-roles": ["admin"]},
)
def run_import(job_id: int, request: Request):
    job = _job_or_404(job_id)
    if job["status"] in ("queued", "running"):
        raise HTTPException(status_code=409, detail="This import is already running")
    if job["status"] == "completed":
        raise HTTPException(
            status_code=409, detail="This import already completed; start a new upload"
        )
    if not import_jobs.csv_path(job_id).is_file():
        raise HTTPException(
            status_code=410,
            detail="The staged files are gone; upload the batch again",
        )
    if db.active_import_job_count(exclude_id=job_id) > 0:
        raise HTTPException(
            status_code=409,
            detail="Another import is running. Wait for it to finish.",
        )

    db.update_import_job(job_id, status="queued", message=None)
    threading.Thread(
        target=import_jobs.run_import_job,
        args=(job_id,),
        daemon=True,
        name=f"import-job-{job_id}",
    ).start()
    return db.get_import_job(job_id)


@router.get(
    "/api/import/{job_id}",
    dependencies=[Depends(admin_required)],
    openapi_extra={"x-required-roles": ["admin"]},
)
def get_import(job_id: int):
    return _job_or_404(job_id)


@router.delete(
    "/api/import/{job_id}",
    dependencies=[Depends(admin_required)],
    openapi_extra={"x-required-roles": ["admin"]},
)
def delete_import(job_id: int):
    job = _job_or_404(job_id)
    if job["status"] in ("queued", "running"):
        raise HTTPException(status_code=409, detail="Cannot delete a running import")
    import_jobs.cleanup_job_dir(job_id)
    db.delete_import_job(job_id)
    return {"message": "Import preview discarded"}


@router.get(
    "/api/import/{job_id}/report",
    dependencies=[Depends(admin_required)],
    openapi_extra={"x-required-roles": ["admin"]},
)
def download_report(job_id: int):
    job = _job_or_404(job_id)
    buffer = io.StringIO()
    writer = csv.DictWriter(buffer, fieldnames=importing.REPORT_COLUMNS)
    writer.writeheader()
    for row in job.get("rows") or []:
        writer.writerow(
            {
                "row": row.get("row", ""),
                "action": row.get("action", ""),
                "thesis_id": row.get("thesis_id") or "",
                "pdf_filename": row.get("pdf_filename", ""),
                "title": row.get("title", ""),
                "pages": row.get("pages") if row.get("pages") is not None else "",
                "chunks": row.get("chunks") if row.get("chunks") is not None else "",
                "warnings": " | ".join(row.get("warnings") or []),
                "errors": " | ".join(row.get("errors") or []),
                "source_notes": row.get("source_notes", ""),
            }
        )
    content = "\ufeff" + buffer.getvalue()
    return Response(
        content=content.encode("utf-8"),
        media_type="text/csv; charset=utf-8",
        headers={
            "Content-Disposition": f'attachment; filename="import_report_{job_id}.csv"'
        },
    )
