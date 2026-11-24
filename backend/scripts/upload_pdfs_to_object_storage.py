"""Copy the local thesis PDFs into S3-compatible object storage (one time).

A free host has no persistent disk, so the 125 MB of PDFs under
``app/uploads`` must live outside the service. Run this once from ``backend/``
after the storage settings are in ``.env``:

    venv\\Scripts\\python scripts\\upload_pdfs_to_object_storage.py --dry-run
    venv\\Scripts\\python scripts\\upload_pdfs_to_object_storage.py

Object keys are the stored filenames (``<uuid>_<original>.pdf``), which is
exactly what ``pdf_url`` already contains, so no database rows change. Re-runs
are safe: objects are overwritten with identical bytes.

Exit codes: 0 = all files present in the bucket, 1 = storage not configured or
at least one upload failed.
"""

import argparse
import sys
from pathlib import Path

BACKEND = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BACKEND))

from dotenv import load_dotenv  # noqa: E402

load_dotenv(BACKEND / ".env")

from app.config import UPLOAD_DIR  # noqa: E402
from app.services import object_store  # noqa: E402


def local_pdfs():
    """Yield every stored PDF, skipping the import staging folder."""
    root = Path(UPLOAD_DIR)
    if not root.is_dir():
        return
    for path in sorted(root.rglob("*")):
        if not path.is_file():
            continue
        if "_import_jobs" in path.parts:
            continue
        if path.suffix.lower() != ".pdf":
            continue
        yield path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--dry-run", action="store_true", help="list the files without uploading"
    )
    args = parser.parse_args()

    if not object_store.enabled():
        print(
            "Object storage is not configured. Set AWS_ENDPOINT_URL_S3, AWS_REGION,\n"
            "AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and S3_BUCKET in backend/.env."
        )
        return 1

    print(f"bucket: {object_store.bucket()}")
    print(f"source: {UPLOAD_DIR}")

    uploaded = 0
    failed = []
    total_bytes = 0
    for path in local_pdfs():
        total_bytes += path.stat().st_size
        if args.dry_run:
            print(f"would upload {path.name} ({path.stat().st_size:,} bytes)")
            continue
        try:
            object_store.put_file(path, path.name, "application/pdf")
            uploaded += 1
            print(f"uploaded {path.name} ({path.stat().st_size:,} bytes)")
        except Exception as exc:
            failed.append(path.name)
            print(f"FAILED   {path.name}: {exc}")

    print(f"\n{uploaded} uploaded, {len(failed)} failed, {total_bytes:,} bytes total")
    if failed:
        print("Failed files: " + ", ".join(failed))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
