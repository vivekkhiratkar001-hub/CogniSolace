import hashlib

from ai.llm.ollama_client import generate_response
from ai.rag.chunker import chunk_documents
from ai.rag.document_loader import load_documents
from ai.rag.embeddings import create_embeddings
from ai.rag.retriever import retrieve
from ai.rag.vector_store import (
    build_index,
    load_index,
    load_signature,
    save_index,
    save_signature,
)


# In-memory cache so repeated calls within the same running process (e.g. a
# backend server handling many questions) don't even need to touch disk.
_cache = {"signature": None, "index": None}


def _compute_signature(chunks):
    """Cheap fingerprint of the chunked corpus (no ML involved). Used to
    detect whether the knowledge base has changed since the index was built,
    without needing to re-embed everything just to check."""
    hasher = hashlib.sha256()
    for chunk in chunks:
        hasher.update(chunk["source"].encode("utf-8"))
        hasher.update(b"\x00")
        hasher.update(chunk["text"].encode("utf-8"))
        hasher.update(b"\x01")
    return hasher.hexdigest()


def _get_current_index(chunks):
    """Return a FAISS index for the given chunks, avoiding re-embedding the
    whole knowledge base whenever possible.

    Fast path 1: same process, corpus unchanged -> reuse in-memory index.
    Fast path 2: corpus unchanged since last run -> load saved index from
                 disk, verified via a signature file, no embedding needed.
    Slow path:   corpus changed (or no index yet) -> embed all chunks,
                 build a fresh index, and persist it + its signature.
    """
    signature = _compute_signature(chunks)

    if _cache["signature"] == signature and _cache["index"] is not None:
        return _cache["index"]

    saved_index = load_index()
    saved_signature = load_signature()
    if (
        saved_index is not None
        and saved_signature == signature
        and saved_index.ntotal == len(chunks)
    ):
        _cache["signature"] = signature
        _cache["index"] = saved_index
        return saved_index

    texts = [chunk["text"] for chunk in chunks]
    try:
        document_embeddings = create_embeddings(texts)
    except Exception as error:
        raise RuntimeError(f"Failed to create document embeddings: {error}") from error

    if document_embeddings.size == 0:
        raise RuntimeError("No document embeddings are available.")

    index = build_index(document_embeddings)
    if index is None:
        raise RuntimeError("Unable to build a FAISS index from the document embeddings.")

    save_index(index)
    save_signature(signature)
    _cache["signature"] = signature
    _cache["index"] = index
    return index


def _build_prompt(question, results):
    context = "\n\n".join(
        f"Source: {result['source']}\n{result['text']}" for result in results
    )
    if not context:
        context = "No relevant context was retrieved."

    return f"""You are the CogniSolace assistant.

Answer the user's question using the provided context.

Rules:
- Use the provided context as the primary source.
- Do not invent information.
- Do not make unsupported claims.
- If the answer cannot be found in the context, clearly say that the information is not available in the provided knowledge base.
- Keep the answer concise and useful.

CONTEXT:
{context}

USER QUESTION:
{question}
"""


def answer_question(question):
    if not isinstance(question, str) or not question.strip():
        return "Please provide a non-empty question."

    documents = load_documents()
    if not documents:
        return "No knowledge documents are available."

    chunks = chunk_documents(documents)
    if not chunks:
        return "No knowledge chunks are available."

    try:
        index = _get_current_index(chunks)
    except Exception as error:
        raise RuntimeError(f"Failed to prepare the FAISS index: {error}") from error

    try:
        question_embedding = create_embeddings([question.strip()])
    except Exception as error:
        raise RuntimeError(f"Failed to embed the question: {error}") from error

    try:
        results = retrieve(question_embedding, index, chunks)
    except Exception as error:
        raise RuntimeError(f"Failed to retrieve relevant context: {error}") from error

    prompt = _build_prompt(question.strip(), results)
    try:
        answer = generate_response(prompt).strip()
    except Exception as error:
        raise RuntimeError(f"Failed to generate an answer with Ollama: {error}") from error

    sources = list(dict.fromkeys(result["source"] for result in results))
    if sources:
        answer += "\n\nSources:\n" + "\n".join(f"- {source}" for source in sources)

    return answer
