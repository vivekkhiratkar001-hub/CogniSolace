import numpy as np

from ai.rag.config import TOP_K


def retrieve(query_embedding, index, chunks, top_k=TOP_K):
    if query_embedding is None or index is None or not chunks or top_k <= 0:
        return []

    if getattr(index, "ntotal", 0) == 0:
        return []

    query = np.asarray(query_embedding, dtype=np.float32)
    if query.size == 0:
        return []
    if query.ndim == 1:
        query = query.reshape(1, -1)
    if query.ndim != 2 or query.shape[0] == 0:
        return []

    result_count = min(top_k, index.ntotal, len(chunks))
    scores, indices = index.search(query[:1], result_count)

    results = []
    for score, chunk_index in zip(scores[0], indices[0]):
        if chunk_index < 0 or chunk_index >= len(chunks):
            continue

        chunk = chunks[chunk_index]
        results.append(
            {
                "text": chunk["text"],
                "source": chunk["source"],
                "score": float(score),
            }
        )

    return results