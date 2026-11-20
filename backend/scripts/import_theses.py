"""Batch-import theses from ``metadata.csv`` + a folder of PDFs.

This is the command-line wrapper around ``app/services/importing.py``. The
admin Bulk Import screen calls the same service, so the terminal path and the
UI path validate and import identically.

Usage (from ``backend/``):

    venv\\Scripts\\python scripts\\import_theses.py ..\\..\\metadata.csv \\
        --pdf-dir ..\\..\\pdf --dry-run

    venv\\Scripts\\python scripts\\import_theses.py ..\\..\\metadata.csv \\
        --pdf-dir ..\\..\\pdf

    venv\\Scripts\\python scripts\\import_theses.py ..\\..\\metadata.csv \\
        --pdf-dir ..\\..\\pdf --report import_report.csv

``--dry-run`` validates and writes the report without writing to the database,
copying a PDF, OCR'ing, or embedding. Exit code: 0 clean, 1 row/embedding
failure, 2 refused before importing because validation found errors.
"""

import argparse
import sys
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parents[1]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from app.services import importing  # noqa: E402


def main():
    parser = argparse.ArgumentParser(
        description="Import a metadata CSV + PDF folder into CScholar as drafts."
    )
    parser.add_argument("csv", help="Path to metadata.csv / batch.csv")
    parser.add_argument("--pdf-dir", required=True, help="Folder containing the PDFs")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate and report only; no DB writes, copies, OCR, or embeddings.",
    )
    parser.add_argument(
        "--report",
        help="Report path (default: import_report.csv, or "
        "import_report_dry_run.csv with --dry-run).",
    )
    parser.add_argument(
        "--skip-invalid",
        action="store_true",
        help="Import valid rows even when some rows have validation errors.",
    )
    parser.add_argument(
        "--update-metadata",
        action="store_true",
        help="Refresh metadata/links on already-imported rows instead of skipping them.",
    )
    parser.add_argument(
        "--reindex",
        action="store_true",
        help="Rebuild embeddings even when chunks already exist.",
    )
    parser.add_argument(
        "--no-ocr",
        action="store_true",
        help="Do not OCR scans; index title + abstract (and any text layer) only.",
    )
    parser.add_argument(
        "--embed-batch",
        type=int,
        default=32,
        help="Chunks per embedding batch (default 32).",
    )
    args = parser.parse_args()

    csv_path = Path(args.csv).expanduser().resolve()
    pdf_dir = Path(args.pdf_dir).expanduser().resolve()
    if not csv_path.is_file():
        raise SystemExit(f"CSV not found: {csv_path}")
    if not pdf_dir.is_dir():
        raise SystemExit(f"PDF folder not found: {pdf_dir}")

    report_path = args.report or (
        "import_report_dry_run.csv" if args.dry_run else "import_report.csv"
    )
    if not Path(report_path).is_absolute():
        report_path = Path.cwd() / report_path

    try:
        raw_rows = importing.read_csv(csv_path)
    except ValueError as exc:
        raise SystemExit(str(exc))

    rows = importing.validate_rows(raw_rows, pdf_dir, importing.load_lookup())
    errors = sum(1 for row in rows if row.errors)

    if args.dry_run:
        warnings = sum(1 for row in rows if row.warnings)
        print(
            f"Dry run: {len(rows)} rows, {errors} with errors, "
            f"{warnings} with warnings"
        )
        for row in rows:
            if row.errors:
                print(f"  row {row.number}: {row.action} — {'; '.join(row.errors)}")
        path = importing.write_report(report_path, rows)
        print(f"Report: {path}")
        return 1 if errors else 0

    if errors and not args.skip_invalid:
        path = importing.write_report(report_path, rows)
        print(
            f"Refusing to import: {errors} row(s) have validation errors. "
            f"Fix them or re-run with --skip-invalid. Report: {path}"
        )
        return 2

    valid = sum(1 for row in rows if not row.errors)
    progress = {"n": 0}

    def on_event(event, row):
        if event == "imported":
            progress["n"] += 1
            print(
                f"[{progress['n']}/{valid}] row {row.number}: "
                f"{row.action} {row.pdf_filename}"
            )
        elif event == "indexed":
            print(f"  indexed thesis {row.thesis_id}: {row.chunks} chunks")
        elif event == "error":
            print(f"[row {row.number}] FAILED {row.pdf_filename}: {'; '.join(row.errors)}")
        elif event == "embedding_error":
            print(f"  WARNING thesis {row.thesis_id}: embedding failed")

    summary = importing.run_batch(
        rows,
        update_metadata=args.update_metadata,
        reindex=args.reindex,
        no_ocr=args.no_ocr,
        embed_batch=args.embed_batch,
        on_event=on_event,
    )
    path = importing.write_report(report_path, rows)
    print(
        f"\nImport complete: {summary['created']} created, "
        f"{summary['updated']} updated, {summary['skipped']} skipped, "
        f"{summary['failed']} failed; {summary['indexed']} indexed "
        f"({summary['embedding_failures']} embedding failures)"
    )
    print(f"Report: {path}")
    return (
        1
        if (
            summary["failed"]
            or summary["embedding_failures"]
            or (errors and args.skip_invalid)
        )
        else 0
    )


if __name__ == "__main__":
    sys.exit(main())
