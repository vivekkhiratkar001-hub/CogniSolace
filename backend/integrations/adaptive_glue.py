"""Optional Member 3 adaptive-difficulty adapter.

Replace `recommend_next_difficulty` with the production glue. Until then this
module implements the same accuracy-band fallback used by `main.py`.
"""

from __future__ import annotations

from typing import Any, Literal

DifficultyLevel = Literal["easy", "medium", "hard"]


def recommend_next_difficulty(
    *,
    accuracy: float,
    current_difficulty: str,
    game_type: str,
    recent_sessions: list[dict[str, Any]],
    anomaly_detected: bool,
    severity: str,
) -> DifficultyLevel:
    """Return the next recommended difficulty band."""
    del current_difficulty, game_type, recent_sessions, anomaly_detected, severity
    if accuracy >= 85.0:
        return "hard"
    if accuracy >= 55.0:
        return "medium"
    return "easy"
