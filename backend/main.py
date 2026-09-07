"""CogniSolace FastAPI surface for Flutter clients and the caregiver dashboard."""

from __future__ import annotations

import asyncio
import importlib
import logging
import statistics
import time
from collections.abc import Callable, Mapping
from contextlib import asynccontextmanager
from datetime import datetime
from typing import Any

from fastapi import FastAPI, HTTPException, Path, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from analytics import CognitiveDriftEngine
from database import (
    DatabaseError,
    DatabaseValidationError,
    get_active_alerts,
    get_db,
    get_recent_telemetry,
    get_user_routines,
    init_db,
    insert_cognitive_alert,
    insert_game_telemetry,
    toggle_routine_status,
)
from models import (
    AdaptiveEvaluationResponse,
    AssistantQueryRequest,
    AssistantQueryResponse,
    CaregiverSummaryResponse,
    DifficultyLevel,
    GameSubmissionRequest,
    GameType,
    RoutineItem,
)

logger = logging.getLogger("cognisolace.api")

RAG_TIMEOUT_SECONDS = 2.0
TELEMETRY_WINDOW = 10

_ALERT_SEVERITY_MAP = {"HIGH": "high", "WARNING": "medium"}

_SUPPORTIVE_FALLBACK = (
    "You're safe, and it's okay to go slowly. Take a sip of water, follow a "
    "familiar routine, and try an easy memory game when you feel ready. "
    "Ask a caregiver if anything feels confusing."
)

_RECOMMENDED_ACTIVITIES: dict[tuple[str, DifficultyLevel], str] = {
    ("memory", "easy"): "Replay a short memory match with fewer cards.",
    ("memory", "medium"): "Try a standard memory match at a comfortable pace.",
    ("memory", "hard"): "Challenge a larger memory grid when you feel focused.",
    ("sequence", "easy"): "Repeat a short sequence game with slower cues.",
    ("sequence", "medium"): "Continue sequence practice at the current length.",
    ("sequence", "hard"): "Extend the sequence length while staying relaxed.",
    ("spatial", "easy"): "Practice a simple spatial puzzle with extra time.",
    ("spatial", "medium"): "Continue spatial rotation at a steady pace.",
    ("spatial", "hard"): "Try a denser spatial layout if energy is good.",
}

_drift_engine = CognitiveDriftEngine()


class ToggleRoutineResponse(BaseModel):
    routine_id: int = Field(..., ge=1)
    completed: bool


def _load_optional_callable(module_name: str, attr: str) -> Callable[..., Any] | None:
    try:
        module = importlib.import_module(module_name)
    except ImportError:
        logger.info("Optional integration %s is not installed", module_name)
        return None
    func = getattr(module, attr, None)
    if not callable(func):
        logger.warning("%s.%s is missing or not callable", module_name, attr)
        return None
    return func


_recommend_next_difficulty = _load_optional_callable(
    "integrations.adaptive_glue",
    "recommend_next_difficulty",
)
_query_assistant_rag = _load_optional_callable(
    "integrations.rag_glue",
    "query_assistant",
)


@asynccontextmanager
async def lifespan(_app: FastAPI):
    logging.basicConfig(level=logging.INFO)
    init_db()
    logger.info("CogniSolace API ready")
    yield


app = FastAPI(
    title="CogniSolace API",
    description="Cognitive training telemetry, caregiver dashboard, and assistant gateway.",
    version="1.0.0",
    lifespan=lifespan,
    openapi_tags=[
        {"name": "telemetry", "description": "Game session ingest and adaptive evaluation"},
        {"name": "dashboard", "description": "Caregiver summary for Member 6"},
        {"name": "routines", "description": "Daily living tasks for Member 1"},
        {"name": "assistant", "description": "In-app cognitive assistant"},
    ],
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


def _http_from_persistence(exc: Exception) -> HTTPException:
    if isinstance(exc, DatabaseValidationError):
        return HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc))
    message = str(exc)
    lowered = message.lower()
    if "was not found" in lowered or "does not exist" in lowered:
        return HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=message)
    return HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=message)


def _json_safe_value(value: Any) -> Any:
    if isinstance(value, datetime):
        return value.isoformat()
    if isinstance(value, bytes):
        return value.decode("utf-8", errors="replace")
    return value


def _json_safe_records(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    safe: list[dict[str, Any]] = []
    for row in rows:
        item: dict[str, Any] = {}
        for key, value in row.items():
            if key in {"completed", "anomaly_flag", "is_resolved"}:
                item[key] = bool(value)
            else:
                item[key] = _json_safe_value(value)
        safe.append(item)
    return safe


def _fetch_user(user_id: int) -> dict[str, Any] | None:
    with get_db() as conn:
        row = conn.execute(
            "SELECT id, name, age, baseline_score, language, created_at FROM users WHERE id = ?",
            (user_id,),
        ).fetchone()
    if row is None:
        return None
    return {key: row[key] for key in row.keys()}


def _require_user(user_id: int) -> dict[str, Any]:
    user = _fetch_user(user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User {user_id} was not found",
        )
    return user


def _rule_next_difficulty(accuracy: float) -> DifficultyLevel:
    if accuracy >= 85.0:
        return "hard"
    if accuracy >= 55.0:
        return "medium"
    return "easy"


def _resolve_next_difficulty(
    payload: GameSubmissionRequest,
    recent_sessions: list[dict[str, Any]],
    anomaly_detected: bool,
    severity: str,
) -> DifficultyLevel:
    fallback = _rule_next_difficulty(payload.accuracy)
    if _recommend_next_difficulty is None:
        return fallback
    try:
        recommended = _recommend_next_difficulty(
            accuracy=payload.accuracy,
            current_difficulty=payload.current_difficulty,
            game_type=payload.game_type,
            recent_sessions=recent_sessions,
            anomaly_detected=anomaly_detected,
            severity=severity,
        )
    except Exception:
        logger.exception("adaptive_glue failed; using accuracy-band fallback")
        return fallback
    if recommended in {"easy", "medium", "hard"}:
        return recommended  # type: ignore[return-value]
    logger.warning("adaptive_glue returned invalid difficulty %r", recommended)
    return fallback


def _recommended_activity(game_type: GameType, next_difficulty: DifficultyLevel) -> str:
    return _RECOMMENDED_ACTIVITIES.get(
        (game_type, next_difficulty),
        "Continue a familiar cognitive game at a comfortable pace.",
    )


def _rolling_accuracy(sessions: list[dict[str, Any]]) -> float:
    values = [float(row["accuracy"]) for row in sessions if row.get("accuracy") is not None]
    if not values:
        return 0.0
    return round(min(max(statistics.fmean(values), 0.0), 100.0), 2)


def _normalize_rag_answer(result: Any) -> str:
    if isinstance(result, str):
        answer = result.strip()
    elif isinstance(result, Mapping):
        raw = result.get("answer") or result.get("response") or result.get("text") or ""
        answer = str(raw).strip()
    else:
        raise ValueError("RAG result must be a string or mapping")
    if not answer:
        raise ValueError("RAG result was empty")
    return answer


async def _invoke_rag(user_id: int, question: str) -> str:
    if _query_assistant_rag is None:
        raise RuntimeError("RAG glue is not available")
    if asyncio.iscoroutinefunction(_query_assistant_rag):
        result = await _query_assistant_rag(user_id, question)
    else:
        result = await asyncio.to_thread(_query_assistant_rag, user_id, question)
    return _normalize_rag_answer(result)


@app.post(
    "/api/v1/telemetry/submit",
    response_model=AdaptiveEvaluationResponse,
    status_code=status.HTTP_201_CREATED,
    tags=["telemetry"],
    summary="Submit game telemetry and receive the next difficulty",
)
def submit_telemetry(payload: GameSubmissionRequest) -> AdaptiveEvaluationResponse:
    _require_user(payload.user_id)
    try:
        recent_sessions = get_recent_telemetry(payload.user_id, TELEMETRY_WINDOW)
        current_game = payload.to_telemetry_payload()
        anomaly_detected, severity, message = _drift_engine.analyze_performance(
            recent_sessions,
            current_game,
        )
        if anomaly_detected:
            mapped = _ALERT_SEVERITY_MAP.get(severity)
            if mapped is not None:
                insert_cognitive_alert(
                    user_id=payload.user_id,
                    severity=mapped,
                    alert_type="cognitive_drift",
                    message=message,
                )
        next_difficulty = _resolve_next_difficulty(
            payload,
            recent_sessions,
            anomaly_detected,
            severity,
        )
        insert_payload = dict(current_game)
        insert_payload["anomaly_flag"] = anomaly_detected
        insert_game_telemetry(insert_payload)
    except (DatabaseError, DatabaseValidationError) as exc:
        raise _http_from_persistence(exc) from exc
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc

    return AdaptiveEvaluationResponse(
        next_difficulty=next_difficulty,
        recommended_activity=_recommended_activity(payload.game_type, next_difficulty),
        cognitive_drift_detected=anomaly_detected,
        feedback_message=message,
    )


@app.get(
    "/api/v1/dashboard/{user_id}",
    response_model=CaregiverSummaryResponse,
    status_code=status.HTTP_200_OK,
    tags=["dashboard"],
    summary="Caregiver summary for a patient",
)
def get_dashboard(
    user_id: int = Path(..., ge=1, description="Patient user id"),
) -> CaregiverSummaryResponse:
    user = _require_user(user_id)
    try:
        sessions = get_recent_telemetry(user_id, TELEMETRY_WINDOW)
        alerts = get_active_alerts(user_id)
        routines = get_user_routines(user_id)
    except (DatabaseError, DatabaseValidationError) as exc:
        raise _http_from_persistence(exc) from exc

    completed = sum(1 for row in routines if row.get("completed"))
    pending = len(routines) - completed
    return CaregiverSummaryResponse(
        user_id=int(user["id"]),
        patient_name=str(user["name"]),
        rolling_accuracy=_rolling_accuracy(sessions),
        completed_tasks_count=completed,
        pending_tasks_count=pending,
        active_alerts=_json_safe_records(alerts),
        recent_sessions=_json_safe_records(sessions),
    )


@app.get(
    "/api/v1/routines/{user_id}",
    response_model=list[RoutineItem],
    status_code=status.HTTP_200_OK,
    tags=["routines"],
    summary="Daily routines for a patient",
)
def list_routines(
    user_id: int = Path(..., ge=1, description="Patient user id"),
) -> list[RoutineItem]:
    _require_user(user_id)
    try:
        rows = get_user_routines(user_id)
    except (DatabaseError, DatabaseValidationError) as exc:
        raise _http_from_persistence(exc) from exc
    return [RoutineItem.model_validate(row) for row in rows]


@app.post(
    "/api/v1/routines/{routine_id}/toggle",
    response_model=ToggleRoutineResponse,
    status_code=status.HTTP_200_OK,
    tags=["routines"],
    summary="Toggle a routine completed flag",
)
def toggle_routine(
    routine_id: int = Path(..., ge=1, description="Routine row id"),
) -> ToggleRoutineResponse:
    try:
        completed = toggle_routine_status(routine_id)
    except (DatabaseError, DatabaseValidationError) as exc:
        raise _http_from_persistence(exc) from exc
    return ToggleRoutineResponse(routine_id=routine_id, completed=completed)


@app.post(
    "/api/v1/assistant/chat",
    response_model=AssistantQueryResponse,
    status_code=status.HTTP_200_OK,
    tags=["assistant"],
    summary="Ask the cognitive assistant with a 2s RAG timeout",
)
async def assistant_chat(payload: AssistantQueryRequest) -> AssistantQueryResponse:
    _require_user(payload.user_id)
    started = time.perf_counter()
    source: str = "rule_fallback"
    answer = _SUPPORTIVE_FALLBACK
    try:
        answer = await asyncio.wait_for(
            _invoke_rag(payload.user_id, payload.question),
            timeout=RAG_TIMEOUT_SECONDS,
        )
        source = "rag_llm"
    except Exception:
        logger.info("Assistant using rule_fallback after RAG timeout or error")
        answer = _SUPPORTIVE_FALLBACK
        source = "rule_fallback"
    latency_ms = (time.perf_counter() - started) * 1000.0
    return AssistantQueryResponse(answer=answer, source=source, latency_ms=round(latency_ms, 3))
