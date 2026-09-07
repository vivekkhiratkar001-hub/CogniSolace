import numpy as np
from sentence_transformers import SentenceTransformer

from ai.rag.config import EMBEDDING_MODEL


_model = None


def create_embeddings(texts):
    if not texts:
        return np.empty((0, 0), dtype=np.float32)

    global _model
    if _model is None:
        _model = SentenceTransformer(EMBEDDING_MODEL)

    return _model.encode(
        list(texts),
        convert_to_numpy=True,
        normalize_embeddings=True,
    )