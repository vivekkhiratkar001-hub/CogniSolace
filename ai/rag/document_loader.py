from pathlib import Path

from ai.rag.config import KNOWLEDGE_DIR


def load_documents():
    knowledge_path = Path(KNOWLEDGE_DIR)

    if not knowledge_path.is_dir():
        return []

    documents = []
    for file_path in sorted(knowledge_path.glob("*.txt")):
        try:
            text = file_path.read_text(encoding="utf-8")
        except (OSError, UnicodeError):
            continue

        documents.append({"text": text, "source": file_path.name})

    return documents