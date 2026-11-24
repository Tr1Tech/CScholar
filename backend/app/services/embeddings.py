"""Embedding service — MiniLM vectors via ONNX or Sentence Transformers.

Two runtimes produce the same 384-dim ``all-MiniLM-L6-v2`` vectors:

* **fastembed** (ONNX) peaks around 170 MB RSS and is used on small free hosts.
* **sentence-transformers** (torch) peaks around 520 MB and remains the local
  default when fastembed is not installed.

``EMBEDDING_BACKEND`` selects one explicitly; ``auto`` prefers fastembed.
"""

import logging
import os
import threading
import time
from typing import List, Optional

import numpy as np

from ..config import BASE_DIR

logger = logging.getLogger(__name__)


class EmbeddingService:
    """Generate text embeddings using Sentence Transformers.

    Loading is lazy but MUST be thread-safe. FastAPI runs sync endpoints in a
    thread pool, and the Flutter client fires recommendations and search
    together, so several requests can ask for the model at the same instant.
    Two concurrent ``SentenceTransformer`` constructions share the same HF
    cache and file handles; the loser can observe a half-materialised model
    and fail with "Cannot copy out of meta tensor; no data!". One lock
    serialises the load, and the first successful build is kept.

    A failed load is remembered for [_RETRY_AFTER] seconds. Without that, the
    ``available`` check retried on *every* request, so one broken environment
    produced an endless stream of load attempts and 503s.
    """

    #: How long to wait before retrying a failed model load.
    _RETRY_AFTER = 60.0

    #: Same weights as ``all-MiniLM-L6-v2``, exported to ONNX. fastembed's
    #: vectors are L2-normalised (sentence-transformers' are not), but every
    #: stored vector is compared with cosine distance, which ignores magnitude.
    FASTEMBED_MODEL = "sentence-transformers/all-MiniLM-L6-v2"

    def __init__(self, model_name: str = "all-MiniLM-L6-v2", dim: int = 384):
        self.model_name = model_name
        self.dim = dim
        self._model = None
        self._backend = None
        self._available = False
        self._load_lock = threading.Lock()
        self._next_retry = 0.0

    @staticmethod
    def _preferred_backend() -> str:
        """``EMBEDDING_BACKEND`` as ``auto``, ``fastembed`` or ``sentence-transformers``.

        ``auto`` (the default) uses fastembed when it is installed and falls
        back to sentence-transformers otherwise. A free 512 MB host cannot
        import torch at all, so production installs the ONNX runtime only.
        """
        return (os.getenv("EMBEDDING_BACKEND") or "auto").strip().lower()

    @staticmethod
    def _fastembed_cache_dir() -> str:
        """Project-local ONNX cache so a build step can warm it for cold starts."""
        return os.getenv("FASTEMBED_CACHE_DIR") or os.path.join(
            BASE_DIR, ".fastembed_cache"
        )

    def _build_model(self):
        """Load the first backend that works; remember which one is in use."""
        preferred = self._preferred_backend()
        if preferred in ("auto", "fastembed"):
            if self._load_fastembed():
                return
            if preferred == "fastembed":
                logger.warning(
                    "EMBEDDING_BACKEND=fastembed but fastembed is unavailable; "
                    "falling back to sentence-transformers"
                )
        if self._load_sentence_transformers():
            return
        raise ImportError(
            "Neither fastembed nor sentence-transformers is installed"
        )

    def _load_fastembed(self) -> bool:
        """Load the ONNX MiniLM model (~160 MB RSS instead of torch's ~520 MB)."""
        try:
            from fastembed import TextEmbedding
        except ImportError:
            return False
        cache_dir = self._fastembed_cache_dir()
        threads = os.getenv("FASTEMBED_THREADS")
        kwargs = {"cache_dir": cache_dir}
        if threads and threads.isdigit():
            kwargs["threads"] = int(threads)
        try:
            # Cached installs (a build step warms the cache) skip the Hub.
            self._model = TextEmbedding(
                self.FASTEMBED_MODEL, local_files_only=True, **kwargs
            )
        except Exception:
            self._model = TextEmbedding(self.FASTEMBED_MODEL, **kwargs)
        self._backend = "fastembed"
        self._available = True
        logger.info("Loaded embedding model: %s (fastembed/ONNX)", self.FASTEMBED_MODEL)
        return True

    def _load_sentence_transformers(self) -> bool:
        """Load the original torch model. Used locally and as the fallback."""
        try:
            from sentence_transformers import SentenceTransformer
        except ImportError:
            return False
        kwargs = dict(
            device="cpu",
            # Never load onto the meta device. The default
            # ``low_cpu_mem_usage`` path materialises weights lazily,
            # and the first ``.to()`` then raises "Cannot copy out of
            # meta tensor; no data!" — the exact failure this service
            # was surfacing.
            model_kwargs={"low_cpu_mem_usage": False},
        )
        try:
            # Cached installs: skip the Hugging Face round-trip that
            # was adding ~10s to every cold start.
            self._model = SentenceTransformer(
                self.model_name, local_files_only=True, **kwargs
            )
        except Exception:
            # First run on a new machine: the weights are not cached
            # yet, so retry allowing the download.
            self._model = SentenceTransformer(self.model_name, **kwargs)
        self._backend = "sentence-transformers"
        self._available = True
        logger.info("Loaded embedding model: %s (sentence-transformers)", self.model_name)
        return True

    def _load_model(self):
        """Lazy-load the model once, from one thread at a time."""
        if self._model is not None:
            return
        if time.monotonic() < self._next_retry:
            return
        with self._load_lock:
            # Re-check inside the lock: another thread may have finished the
            # load (or started a cooldown) while this one was waiting.
            if self._model is not None:
                return
            if time.monotonic() < self._next_retry:
                return
            try:
                self._build_model()
            except Exception as e:
                logger.error("Failed to load embedding model: %s", e)
                self._available = False
                self._next_retry = time.monotonic() + self._RETRY_AFTER

    def warm_up(self):
        """Start loading the model in the background.

        Called from the app lifespan so the (expensive) import of the embedding
        runtime and the weight load happen while the server is idle, not on the
        first thesis submission. Returns immediately.
        """
        if self._model is not None:
            return
        threading.Thread(
            target=self._load_model, daemon=True, name="embedding-warmup"
        ).start()

    @property
    def is_ready(self) -> bool:
        """Non-blocking check: True only when the model is already loaded.

        Request handlers use this to decide whether to embed inline or hand the
        work to a background thread. Unlike ``available`` it never triggers the
        load, so it can never stall a response.
        """
        return self._model is not None and self._available

    @property
    def available(self) -> bool:
        """Check if embedding service is available (may load the model)."""
        self._load_model()
        return self._available

    def _encode(self, texts: List[str], batch_size: int = 32) -> np.ndarray:
        """Encode with whichever backend loaded. Returns one row per text."""
        if self._backend == "fastembed":
            vectors = list(self._model.embed(texts, batch_size=batch_size))
            return np.asarray(vectors, dtype="float32")
        return self._model.encode(
            texts,
            batch_size=batch_size,
            convert_to_numpy=True,
            show_progress_bar=False,
        )

    def embed(self, text: str) -> Optional[List[float]]:
        """Generate embedding for a single text."""
        self._load_model()
        if not self._available:
            return None
        try:
            embedding = self._encode([text])
            return embedding[0].tolist()
        except Exception as e:
            logger.error("Failed to embed text: %s", e)
            return None

    def embed_batch(
        self, texts: List[str], batch_size: int = 32
    ) -> Optional[List[List[float]]]:
        """Generate embeddings for many chunks in one batched call.

        5-10x faster than looping embed() for a full-PDF backfill.
        Returns None when the model is unavailable or encoding fails.
        """
        self._load_model()
        if not self._available:
            return None
        if not texts:
            return []
        try:
            embeddings = self._encode(texts, batch_size=batch_size)
            return [row.tolist() for row in embeddings]
        except Exception as e:
            logger.error("Failed to embed batch of %d texts: %s", len(texts), e)
            return None


# Singleton instance
embedding_service = EmbeddingService()
