from pathlib import Path

import faiss
import numpy as np

from ai.rag.config import FAISS_INDEX_DIR


INDEX_FILENAME = "index.faiss"
SIGNATURE_FILENAME = "signature.txt"


def build_index(embeddings):
    if embeddings is None or len(embeddings) == 0:
        return None

    embeddings = np.asarray(embeddings, dtype=np.float32)
    index = faiss.IndexFlatIP(embeddings.shape[1])
    index.add(embeddings)
    return index


def save_index(index):
    if index is None:
        return None

    index_directory = Path(FAISS_INDEX_DIR)
    index_directory.mkdir(parents=True, exist_ok=True)
    index_path = index_directory / INDEX_FILENAME
    faiss.write_index(index, str(index_path))
    return index_path


def load_index():
    index_path = Path(FAISS_INDEX_DIR) / INDEX_FILENAME
    if not index_path.is_file():
        return None

    return faiss.read_index(str(index_path))


def save_signature(signature):
    """Persist a fingerprint of the corpus that produced the saved index,
    so a later process can tell whether the on-disk index is still valid
    without having to re-embed every chunk just to check."""
    index_directory = Path(FAISS_INDEX_DIR)
    index_directory.mkdir(parents=True, exist_ok=True)
    signature_path = index_directory / SIGNATURE_FILENAME
    signature_path.write_text(signature, encoding="utf-8")
    return signature_path


def load_signature():
    signature_path = Path(FAISS_INDEX_DIR) / SIGNATURE_FILENAME
    if not signature_path.is_file():
        return None
    return signature_path.read_text(encoding="utf-8").strip()