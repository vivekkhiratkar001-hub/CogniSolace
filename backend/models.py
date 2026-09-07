"""Pydantic v2 request/response contracts for the CogniSolace micro-backend."""

from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

GameType = Literal["memory", "sequence", "spatial"]
DifficultyLevel = Literal["easy", "medium", "hard"]
AssistantSource = Literal["rag_llm", "rule_fallback"]

_HH_MM_PATTERN = r"^(?:[01]\d|2[0-3]):[0-5]\d$"


class StrictModel(BaseModel):
    """Shared contract defaults: reject unknown fields, strip strings, re-validate on assign."""

    model_config = ConfigDict(
        extra="forbid",
        str_strip_whitespace=True,
        str_min_length=1,
        validate_assignment=True,
        populate_by_name=True,
    )


class GameSubmissionRequest(StrictModel):
    """Telemetry payload posted by the Flutter cognitive-training client."""

    user_id: int = Field(..., ge=1, description="Persisted patient identifier")
    game_type: GameType
    score: int = Field(..., ge=0, le=100)
    accuracy: float = Field(..., ge=0.0, le=100.0)
    duration_seconds: int = Field(..., ge=1)
    attempts: int = Field(..., ge=1)
    current_difficulty: DifficultyLevel

    def to_telemetry_payload(self) -> dict[str, Any]:
        """Map API field names onto the SQLite `game_telemetry` insert payload."""
        return {
            "user_id": self.user_id,
            "game_type": self.game_type,
            "score": self.score,
            "accuracy": self.accuracy,
            "duration_seconds": self.duration_seconds,
            "attempts": self.attempts,
            "difficulty_level": self.current_difficulty,
        }


class AdaptiveEvaluationResponse(StrictModel):
    """Difficulty and activity recommendation after a game session."""

    next_difficulty: DifficultyLevel
    recommended_activity: str = Field(..., min_length=1, max_length=500)
    cognitive_drift_detected: bool = False
    feedback_message: str = Field(..., min_length=1, max_length=2_000)


class RoutineItem(StrictModel):
    """A single scheduled daily-living task for a patient."""

    id: int = Field(..., ge=1)
    user_id: int = Field(..., ge=1)
    task_title: str = Field(..., min_length=1, max_length=200)
    scheduled_time: str = Field(
        ...,
        pattern=_HH_MM_PATTERN,
        description="24-hour clock time as HH:MM",
        examples=["08:00", "20:30"],
    )
    completed: bool = False

    @field_validator("completed", mode="before")
    @classmethod
    def _coerce_sqlite_bool(cls, value: Any) -> bool:
        if value in (0, 1, "0", "1"):
            return bool(int(value))
        return value


class CaregiverSummaryResponse(StrictModel):
    """Aggregated dashboard view for a caregiver reviewing one patient."""

    user_id: int = Field(..., ge=1)
    patient_name: str = Field(..., min_length=1, max_length=200)
    rolling_accuracy: float = Field(0.0, ge=0.0, le=100.0)
    completed_tasks_count: int = Field(0, ge=0)
    pending_tasks_count: int = Field(0, ge=0)
    active_alerts: list[dict[str, Any]] = Field(default_factory=list)
    recent_sessions: list[dict[str, Any]] = Field(default_factory=list)


class AssistantQueryRequest(StrictModel):
    """Natural-language question from the in-app cognitive assistant."""

    user_id: int = Field(..., ge=1)
    question: str = Field(..., min_length=3, max_length=2_000)


class AssistantQueryResponse(StrictModel):
    """Grounded assistant answer with provenance and timing."""

    answer: str = Field(..., min_length=1, max_length=8_000)
    source: AssistantSource
    latency_ms: float = Field(..., ge=0.0)


__all__ = [
    "AdaptiveEvaluationResponse",
    "AssistantQueryRequest",
    "AssistantQueryResponse",
    "AssistantSource",
    "CaregiverSummaryResponse",
    "DifficultyLevel",
    "GameSubmissionRequest",
    "GameType",
    "RoutineItem",
]
