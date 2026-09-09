"""Embedding service — Sentence Transformers for semantic search."""

import os
import logging
from typing import List, Optional

import numpy as np

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
    
    def embed_batch(self, texts: List[str]) -> List[Optional[List[float]]]:
        """Generate embeddings for multiple texts."""
        self._load_model()
        if not self._available:
            return [None] * len(texts)
        try:
            embeddings = self._model.encode(texts, convert_to_numpy=True)
            return [emb.tolist() for emb in embeddings]
        except Exception as e:
            logger.error(f"Failed to embed batch: {e}")
            return [None] * len(texts)


# Singleton instance
embedding_service = EmbeddingService()
