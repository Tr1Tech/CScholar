"""Optional S3-compatible storage for thesis PDFs.

A free hosting instance has no persistent disk: anything written under
``app/uploads`` is lost on the next restart or spin-down. When the S3 settings
below point at a bucket (Neon Object Storage, or any S3-compatible service),
uploads are mirrored to that bucket and the authenticated PDF route redirects
to a short-lived presigned URL instead of streaming a local file.

Nothing here is required locally. With the settings unset, every helper is
inert and the app behaves exactly as before.
"""

import logging
import os
import tempfile
import threading

logger = logging.getLogger(__name__)

_lock = threading.Lock()
_client = None


def _endpoint():
    return os.getenv("AWS_ENDPOINT_URL_S3") or os.getenv("S3_ENDPOINT")


def _region():
    return os.getenv("AWS_REGION") or os.getenv("S3_REGION") or "us-east-1"


def bucket():
    return os.getenv("S3_BUCKET") or os.getenv("AWS_S3_BUCKET")


def enabled():
    """True only when a bucket, endpoint and both keys are configured."""
    return bool(
        bucket()
        and _endpoint()
        and os.getenv("AWS_ACCESS_KEY_ID")
        and os.getenv("AWS_SECRET_ACCESS_KEY")
    )


def get_client():
    """Build the S3 client once. Returns None when storage is not configured."""
    global _client
    if not enabled():
        return None
    if _client is None:
        with _lock:
            if _client is None:
                import boto3
                from botocore.config import Config

                _client = boto3.client(
                    "s3",
                    region_name=_region(),
                    endpoint_url=_endpoint(),
                    aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
                    aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
                    config=Config(
                        signature_version="s3v4",
                        # Neon Object Storage (and MinIO-style endpoints) need
                        # path-style URLs: <endpoint>/<bucket>/<key>.
                        s3={"addressing_style": "path"},
                        retries={"max_attempts": 3, "mode": "standard"},
                    ),
                )
    return _client


def put_bytes(data, key, content_type="application/pdf"):
    """Store bytes under [key]. Raises when the write fails."""
    client = get_client()
    if client is None:
        return False
    client.put_object(
        Bucket=bucket(),
        Key=key,
        Body=data,
        ContentType=content_type,
    )
    return True


def put_file(path, key, content_type="application/pdf"):
    """Store a file under [key], using boto3's multipart transfer."""
    client = get_client()
    if client is None:
        return False
    client.upload_file(
        str(path),
        bucket(),
        key,
        ExtraArgs={"ContentType": content_type},
    )
    return True


def presigned_get(key, expires=600, filename=None):
    """Return a time-limited download URL, or None when storage is unavailable."""
    client = get_client()
    if client is None:
        return None
    params = {"Bucket": bucket(), "Key": key}
    if filename:
        # The filename is part of the signature, so it cannot be tampered with.
        safe = str(filename).replace('"', "")
        params["ResponseContentDisposition"] = f'inline; filename="{safe}"'
    try:
        return client.generate_presigned_url(
            "get_object", Params=params, ExpiresIn=expires
        )
    except Exception as exc:  # pragma: no cover - network/credential failure
        logger.warning("Could not presign %s: %s", key, exc)
        return None


def size(key):
    """Stored object size in bytes, or None when it cannot be read."""
    client = get_client()
    if client is None:
        return None
    try:
        return int(client.head_object(Bucket=bucket(), Key=key)["ContentLength"])
    except Exception:
        return None


def exists(key):
    """True when [key] is present in the bucket."""
    return size(key) is not None


def materialize(key):
    """Download [key] to a temp file and return its path (caller deletes it).

    Used by the indexing worker when a PDF exists only in the bucket, e.g. a
    thesis edited after a free host restarted and the local copy was lost.
    """
    client = get_client()
    if client is None:
        return None
    handle = tempfile.NamedTemporaryFile(delete=False, suffix=".pdf")
    handle.close()
    try:
        client.download_file(bucket(), key, handle.name)
        return handle.name
    except Exception as exc:  # pragma: no cover - network/credential failure
        logger.warning("Could not download %s: %s", key, exc)
        try:
            os.unlink(handle.name)
        except OSError:
            pass
        return None
