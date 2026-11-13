"""Embedding service — Sentence Transformers for semantic search."""

import logging
import threading
import time
from typing import List, Optional

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

    def __init__(self, model_name: str = "all-MiniLM-L6-v2", dim: int = 384):
        self.model_name = model_name
        self.dim = dim
        self._model = None
        self._available = False
        self._load_lock = threading.Lock()
        self._next_retry = 0.0

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
                from sentence_transformers import SentenceTransformer

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
                self._available = True
                logger.info("Loaded embedding model: %s", self.model_name)
            except ImportError:
                logger.warning(
                    "sentence-transformers not installed. "
                    "Run: pip install sentence-transformers"
                )
                self._available = False
                self._next_retry = time.monotonic() + self._RETRY_AFTER
            except Exception as e:
                logger.error("Failed to load embedding model: %s", e)
                self._available = False
                self._next_retry = time.monotonic() + self._RETRY_AFTER

    def warm_up(self):
        """Start loading the model in the background.

        Called from the app lifespan so the (expensive) import of
        sentence-transformers/torch and the weight load happen while the server
        is idle, not on the first thesis submission. Returns immediately.
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

    def embed(self, text: str) -> Optional[List[float]]:
        """Generate embedding for a single text."""
        self._load_model()
        if not self._available:
            return None
        try:
            embedding = self._model.encode(text, convert_to_numpy=True)
            return embedding.tolist()
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
            embeddings = self._model.encode(
                texts,
                batch_size=batch_size,
                convert_to_numpy=True,
                show_progress_bar=False,
            )
            return [row.tolist() for row in embeddings]
        except Exception as e:
            logger.error("Failed to embed batch of %d texts: %s", len(texts), e)
            return None


# Singleton instance
embedding_service = EmbeddingService()
