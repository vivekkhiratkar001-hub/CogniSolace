from ai.rag.config import CHUNK_OVERLAP, CHUNK_SIZE


def _split_oversized_paragraph(paragraph, source):
    """Fall back to character-window splitting only for a single paragraph
    that is too large to fit in one chunk on its own."""
    chunks = []
    step = CHUNK_SIZE - CHUNK_OVERLAP
    for start in range(0, len(paragraph), step):
        piece = paragraph[start : start + CHUNK_SIZE]
        chunks.append({"text": piece, "source": source})
        if start + CHUNK_SIZE >= len(paragraph):
            break
    return chunks


def chunk_documents(documents):
    """Chunk documents on paragraph (blank-line) boundaries, greedily packing
    paragraphs together up to CHUNK_SIZE so that a single paragraph (e.g. one
    FAQ question/answer pair) is never split across two chunks unless the
    paragraph itself exceeds CHUNK_SIZE, in which case it falls back to a
    character-window split with CHUNK_OVERLAP.
    """
    chunks = []

    for document in documents:
        text = document.get("text", "")
        if not text:
            continue

        source = document["source"]
        paragraphs = [p.strip() for p in text.split("\n\n") if p.strip()]

        current = ""
        for paragraph in paragraphs:
            candidate = f"{current}\n\n{paragraph}" if current else paragraph

            if len(candidate) <= CHUNK_SIZE:
                current = candidate
                continue

            # Candidate would overflow CHUNK_SIZE: flush what we have first.
            if current:
                chunks.append({"text": current, "source": source})
                current = ""

            if len(paragraph) > CHUNK_SIZE:
                # This single paragraph is too big on its own; split it.
                chunks.extend(_split_oversized_paragraph(paragraph, source))
            else:
                current = paragraph

        if current:
            chunks.append({"text": current, "source": source})

    return chunks
