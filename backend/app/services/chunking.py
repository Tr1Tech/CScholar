"""Text chunking for full-PDF thesis embeddings.

MiniLM models silently truncate at 256 tokens, so a whole thesis (or even a
long abstract) must be split into overlapping word-window chunks before
encoding. One chunk -> one row in thesis_embeddings.
"""

import re

DEFAULT_CHUNK_WORDS = 200
DEFAULT_OVERLAP_WORDS = 50
DEFAULT_MAX_CHUNKS = 120


def _clean(text: str) -> str:
    """Collapse whitespace so chunks have predictable word counts."""
    return re.sub(r"\s+", " ", (text or "")).strip()


def chunk_text(
    text: str,
    chunk_words: int = DEFAULT_CHUNK_WORDS,
    overlap_words: int = DEFAULT_OVERLAP_WORDS,
    max_chunks: int = DEFAULT_MAX_CHUNKS,
):
    """Split text into overlapping word-window chunks.

    Returns [] for empty input. A short text yields a single chunk.
    """
    cleaned = _clean(text)
    if not cleaned:
        return []
    words = cleaned.split(" ")
    if len(words) <= chunk_words:
        return [cleaned]
    if overlap_words >= chunk_words:
        overlap_words = chunk_words // 4

    chunks = []
    start = 0
    while start < len(words) and len(chunks) < max_chunks:
        end = min(start + chunk_words, len(words))
        chunks.append(" ".join(words[start:end]))
        if end == len(words):
            break
        start = end - overlap_words
    return chunks


def build_thesis_chunks(title, abstract, pdf_text=None,
                        chunk_words=DEFAULT_CHUNK_WORDS,
                        overlap_words=DEFAULT_OVERLAP_WORDS,
                        max_chunks=DEFAULT_MAX_CHUNKS):
    """Build the chunk list for a thesis: title+abstract, plus PDF body.

    The title/abstract always come first so the lead chunk carries the
    summary even when the PDF contributes dozens of chunks.
    """
    parts = []
    title = (title or "").strip()
    abstract = (abstract or "").strip()
    if title or abstract:
        parts.append(f"{title}. {abstract}".strip(". ") + ".")
    if pdf_text and pdf_text.strip():
        parts.append(pdf_text.strip())
    return chunk_text(
        "\n\n".join(p for p in parts if p),
        chunk_words=chunk_words,
        overlap_words=overlap_words,
        max_chunks=max_chunks,
    )
