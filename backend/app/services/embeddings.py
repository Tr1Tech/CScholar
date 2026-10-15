"""Embedding service — Sentence Transformers for semantic search."""

import logging
from typing import List, Optional

logger = logging.getLogger(__name__)

class EmbeddingService:
    """Generate text embeddings using Sentence Transformers."""
    
    def __init__(self, model_name: str = "all-MiniLM-L6-v2", dim: int = 384):
        self.model_name = model_name
        self.dim = dim
        self._model = None
        self._available = False
    
    def _load_model(self):
        """Lazy-load the model."""
        if self._model is not None:
            return
        try:
            from sentence_transformers import SentenceTransformer
            self._model = SentenceTransformer(self.model_name)
            self._available = True
            logger.info(f"Loaded embedding model: {self.model_name}")
        except ImportError:
            logger.warning("sentence-transformers not installed. Run: pip install sentence-transformers")
            self._available = False
        except Exception as e:
            logger.error(f"Failed to load embedding model: {e}")
            self._available = False
    
    @property
    def available(self) -> bool:
        """Check if embedding service is available."""
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
            logger.error(f"Failed to embed text: {e}")
            return None

    def embed_batch(self, texts: List[str], batch_size: int = 32) -> Optional[List[List[float]]]:
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
                texts, batch_size=batch_size, convert_to_numpy=True,
                show_progress_bar=False,
            )
            return [row.tolist() for row in embeddings]
        except Exception as e:
            logger.error(f"Failed to embed batch of {len(texts)} texts: {e}")
            return None


# Singleton instance
embedding_service = EmbeddingService()
