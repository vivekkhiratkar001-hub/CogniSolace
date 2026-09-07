"""Optional Member 4 RAG adapter.

Wire this function to the retrieval-augmented assistant. Until it is
implemented, `main.py` treats failures and 2s timeouts as `rule_fallback`.
"""

from __future__ import annotations

from typing import Any


async def query_assistant(user_id: int, question: str) -> str | dict[str, Any]:
    """Return a grounded natural-language answer for the in-app assistant.

    Implementations may return a string or a mapping with an ``answer`` key.
    """
    raise RuntimeError("RAG pipeline is not wired yet")
