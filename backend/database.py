"""Thread-safe SQLite persistence for CogniSolace telemetry and caregiving workflows.

Each public operation opens its own connection. SQLite connections are not
shared across threads; WAL + busy timeout allow concurrent dashboard reads
while the Flutter client streams game telemetry.
"""

from __future__ import annotations

import logging
import sqlite3
import threading
from contextlib import contextmanager
from pathlib import Path
from typing import Any, Iterator, Mapping

logger = logging.getLogger(__name__)

DB_PATH = Path(__file__).resolve().parent.parent / "database" / "cognisolace.db"

_CONNECT_TIMEOUT_SECONDS = 30.0
_BUSY_TIMEOUT_MS = 5_000
_INIT_LOCK = threading.Lock()
_initialized = False

_TELEMETRY_REQUIRED = ("user_id", "game_type")
_TELEMETRY_OPTIONAL: dict[str, Any] = {
    "score": None,
    "accuracy": None,
    "duration_seconds": None,
    "attempts": None,
    "difficulty_level": None,
    "anomaly_flag": 0,
}
_ALLOWED_SEVERITIES = frozenset({"low", "medium", "high", "critical"})

_SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    age INTEGER,
    baseline_score REAL DEFAULT 70.0,
    language TEXT DEFAULT 'English',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS game_telemetry (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    game_type TEXT NOT NULL,
    score INTEGER,
    accuracy REAL,
    duration_seconds INTEGER,
    attempts INTEGER,
    difficulty_level TEXT,
    anomaly_flag BOOLEAN DEFAULT 0,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS cognitive_alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    severity TEXT,
    alert_type TEXT,
    message TEXT,
    is_resolved BOOLEAN DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS daily_routines (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    task_title TEXT NOT NULL,
    scheduled_time TEXT NOT NULL,
    completed BOOLEAN DEFAULT 0,
    FOREIGN KEY(user_id) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_telemetry_user_ts
    ON game_telemetry (user_id, timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_alerts_user_active
    ON cognitive_alerts (user_id, is_resolved, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_routines_user
    ON daily_routines (user_id);
"""

_SEED_ROUTINES: tuple[tuple[str, str], ...] = (
    ("Morning medication", "08:00"),
    ("Memory puzzle session", "10:30"),
    ("Afternoon walk", "15:00"),
    ("Evening medication", "20:00"),
)


class DatabaseError(Exception):
    """Raised when a persistence operation cannot be completed safely."""


class DatabaseValidationError(DatabaseError, ValueError):
    """Raised when caller input fails domain validation before SQL execution."""


def _rows_to_dicts(rows: list[sqlite3.Row]) -> list[dict[str, Any]]:
    return [{key: row[key] for key in row.keys()} for row in rows]


def _coerce_bool_int(value: Any, field: str) -> int:
    if value in (0, 1):
        return int(value)
    if isinstance(value, bool):
        return int(value)
    if isinstance(value, str) and value.lower() in {"0", "1", "true", "false"}:
        return int(value.lower() in {"1", "true"})
    raise DatabaseValidationError(f"{field} must be a boolean or 0/1")


def _coerce_optional_int(value: Any, field: str) -> int | None:
    if value is None:
        return None
    try:
        return int(value)
    except (TypeError, ValueError) as exc:
        raise DatabaseValidationError(f"{field} must be an integer") from exc


def _coerce_optional_float(value: Any, field: str) -> float | None:
    if value is None:
        return None
    try:
        return float(value)
    except (TypeError, ValueError) as exc:
        raise DatabaseValidationError(f"{field} must be a number") from exc


def _require_positive_id(value: Any, field: str) -> int:
    parsed = _coerce_optional_int(value, field)
    if parsed is None or parsed < 1:
        raise DatabaseValidationError(f"{field} must be a positive integer")
    return parsed


def _require_nonempty_str(value: Any, field: str, *, max_len: int = 2_000) -> str:
    if not isinstance(value, str):
        raise DatabaseValidationError(f"{field} must be a string")
    cleaned = value.strip()
    if not cleaned:
        raise DatabaseValidationError(f"{field} must not be empty")
    if len(cleaned) > max_len:
        raise DatabaseValidationError(f"{field} exceeds maximum length of {max_len}")
    return cleaned


def _configure_connection(conn: sqlite3.Connection) -> None:
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL;")
    conn.execute("PRAGMA synchronous=NORMAL;")
    conn.execute("PRAGMA foreign_keys=ON;")
    conn.execute(f"PRAGMA busy_timeout={_BUSY_TIMEOUT_MS};")
    conn.execute("PRAGMA temp_store=MEMORY;")


def _open_connection() -> sqlite3.Connection:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    try:
        conn = sqlite3.connect(
            str(DB_PATH),
            timeout=_CONNECT_TIMEOUT_SECONDS,
            isolation_level="DEFERRED",
            check_same_thread=True,
            detect_types=sqlite3.PARSE_DECLTYPES,
        )
    except sqlite3.Error as exc:
        raise DatabaseError(f"Unable to open database at {DB_PATH}") from exc
    try:
        _configure_connection(conn)
    except sqlite3.Error:
        conn.close()
        raise
    return conn


@contextmanager
def get_db() -> Iterator[sqlite3.Connection]:
    """Yield a WAL-enabled connection; commit on success, rollback on error."""
    conn: sqlite3.Connection | None = None
    try:
        conn = _open_connection()
        yield conn
        conn.commit()
    except DatabaseError:
        if conn is not None:
            try:
                conn.rollback()
            except sqlite3.Error:
                logger.exception("Rollback failed after database error")
        raise
    except sqlite3.Error as exc:
        if conn is not None:
            try:
                conn.rollback()
            except sqlite3.Error:
                logger.exception("Rollback failed after SQLite error")
        logger.exception("SQLite operation failed")
        raise DatabaseError("Database operation failed") from exc
    except Exception:
        if conn is not None:
            try:
                conn.rollback()
            except sqlite3.Error:
                logger.exception("Rollback failed after unexpected error")
        raise
    finally:
        if conn is not None:
            try:
                conn.close()
            except sqlite3.Error:
                logger.exception("Failed to close database connection")


def _seed_if_empty(conn: sqlite3.Connection) -> None:
    row = conn.execute("SELECT COUNT(*) AS n FROM users").fetchone()
    if row is None or int(row["n"]) > 0:
        return

    conn.execute(
        """
        INSERT INTO users (id, name, age, baseline_score, language)
        VALUES (1, ?, ?, 70.0, 'English')
        """,
        ("Demo User", 76),
    )
    conn.executemany(
        """
        INSERT INTO daily_routines (user_id, task_title, scheduled_time, completed)
        VALUES (1, ?, ?, 0)
        """,
        _SEED_ROUTINES,
    )
    logger.info("Seeded default Demo User (id=1) and %s daily routines", len(_SEED_ROUTINES))


def init_db() -> None:
    """Create schema, indexes, and seed data. Safe to call concurrently."""
    global _initialized
    with _INIT_LOCK:
        if _initialized and DB_PATH.exists():
            return
        with get_db() as conn:
            conn.executescript(_SCHEMA_SQL)
            _seed_if_empty(conn)
        _initialized = True
        logger.info("Database initialized at %s", DB_PATH)


def insert_game_telemetry(payload: dict[str, Any]) -> int:
    """Persist a game session row. Returns the new telemetry id."""
    if not isinstance(payload, Mapping):
        raise DatabaseValidationError("payload must be a mapping")

    missing = [key for key in _TELEMETRY_REQUIRED if payload.get(key) in (None, "")]
    if missing:
        raise DatabaseValidationError(f"Missing required telemetry fields: {', '.join(missing)}")

    user_id = _require_positive_id(payload.get("user_id"), "user_id")
    game_type = _require_nonempty_str(payload.get("game_type"), "game_type", max_len=128)
    score = _coerce_optional_int(payload.get("score", _TELEMETRY_OPTIONAL["score"]), "score")
    accuracy = _coerce_optional_float(payload.get("accuracy", _TELEMETRY_OPTIONAL["accuracy"]), "accuracy")
    duration_seconds = _coerce_optional_int(
        payload.get("duration_seconds", _TELEMETRY_OPTIONAL["duration_seconds"]),
        "duration_seconds",
    )
    attempts = _coerce_optional_int(payload.get("attempts", _TELEMETRY_OPTIONAL["attempts"]), "attempts")
    difficulty_raw = payload.get("difficulty_level", _TELEMETRY_OPTIONAL["difficulty_level"])
    difficulty_level = (
        _require_nonempty_str(difficulty_raw, "difficulty_level", max_len=64)
        if difficulty_raw not in (None, "")
        else None
    )
    anomaly_flag = _coerce_bool_int(
        payload.get("anomaly_flag", _TELEMETRY_OPTIONAL["anomaly_flag"]),
        "anomaly_flag",
    )

    if accuracy is not None and not 0.0 <= accuracy <= 100.0:
        raise DatabaseValidationError("accuracy must be between 0 and 100")
    if score is not None and score < 0:
        raise DatabaseValidationError("score must be >= 0")
    if duration_seconds is not None and duration_seconds < 0:
        raise DatabaseValidationError("duration_seconds must be >= 0")
    if attempts is not None and attempts < 0:
        raise DatabaseValidationError("attempts must be >= 0")

    init_db()
    with get_db() as conn:
        exists = conn.execute("SELECT 1 FROM users WHERE id = ?", (user_id,)).fetchone()
        if exists is None:
            raise DatabaseError(f"Cannot insert telemetry: user_id={user_id} does not exist")
        cursor = conn.execute(
            """
            INSERT INTO game_telemetry (
                user_id, game_type, score, accuracy, duration_seconds,
                attempts, difficulty_level, anomaly_flag
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                user_id,
                game_type,
                score,
                accuracy,
                duration_seconds,
                attempts,
                difficulty_level,
                anomaly_flag,
            ),
        )
        new_id = cursor.lastrowid
        if new_id is None:
            raise DatabaseError("Telemetry insert succeeded without a row id")
        return int(new_id)


def get_recent_telemetry(user_id: int, limit: int = 10) -> list[dict[str, Any]]:
    """Return the most recent telemetry rows for a user, newest first."""
    uid = _require_positive_id(user_id, "user_id")
    cap = _coerce_optional_int(limit, "limit")
    if cap is None or cap < 1:
        raise DatabaseValidationError("limit must be a positive integer")
    cap = min(cap, 500)

    init_db()
    with get_db() as conn:
        rows = conn.execute(
            """
            SELECT id, user_id, game_type, score, accuracy, duration_seconds,
                   attempts, difficulty_level, anomaly_flag, timestamp
            FROM game_telemetry
            WHERE user_id = ?
            ORDER BY timestamp DESC, id DESC
            LIMIT ?
            """,
            (uid, cap),
        ).fetchall()
    return _rows_to_dicts(rows)


def insert_cognitive_alert(
    user_id: int,
    severity: str,
    alert_type: str,
    message: str,
) -> None:
    """Record an unresolved cognitive alert for caregiver review."""
    uid = _require_positive_id(user_id, "user_id")
    sev = _require_nonempty_str(severity, "severity", max_len=32).lower()
    if sev not in _ALLOWED_SEVERITIES:
        raise DatabaseValidationError(
            f"severity must be one of: {', '.join(sorted(_ALLOWED_SEVERITIES))}"
        )
    kind = _require_nonempty_str(alert_type, "alert_type", max_len=128)
    body = _require_nonempty_str(message, "message", max_len=4_000)

    init_db()
    with get_db() as conn:
        exists = conn.execute("SELECT 1 FROM users WHERE id = ?", (uid,)).fetchone()
        if exists is None:
            raise DatabaseError(f"Cannot insert alert: user_id={uid} does not exist")
        conn.execute(
            """
            INSERT INTO cognitive_alerts (user_id, severity, alert_type, message, is_resolved)
            VALUES (?, ?, ?, ?, 0)
            """,
            (uid, sev, kind, body),
        )


def get_active_alerts(user_id: int) -> list[dict[str, Any]]:
    """Return unresolved alerts for a user, newest first."""
    uid = _require_positive_id(user_id, "user_id")
    init_db()
    with get_db() as conn:
        rows = conn.execute(
            """
            SELECT id, user_id, severity, alert_type, message, is_resolved, created_at
            FROM cognitive_alerts
            WHERE user_id = ? AND is_resolved = 0
            ORDER BY created_at DESC, id DESC
            """,
            (uid,),
        ).fetchall()
    return _rows_to_dicts(rows)


def get_user_routines(user_id: int) -> list[dict[str, Any]]:
    """Return daily routine tasks for a user, ordered by scheduled time."""
    uid = _require_positive_id(user_id, "user_id")
    init_db()
    with get_db() as conn:
        rows = conn.execute(
            """
            SELECT id, user_id, task_title, scheduled_time, completed
            FROM daily_routines
            WHERE user_id = ?
            ORDER BY scheduled_time ASC, id ASC
            """,
            (uid,),
        ).fetchall()
    return _rows_to_dicts(rows)


def toggle_routine_status(routine_id: int) -> bool:
    """Flip a routine's completed flag. Returns the new completed state."""
    rid = _require_positive_id(routine_id, "routine_id")
    init_db()
    with get_db() as conn:
        row = conn.execute(
            "SELECT completed FROM daily_routines WHERE id = ?",
            (rid,),
        ).fetchone()
        if row is None:
            raise DatabaseError(f"Routine {rid} was not found")
        next_state = 0 if int(row["completed"] or 0) else 1
        conn.execute(
            "UPDATE daily_routines SET completed = ? WHERE id = ?",
            (next_state, rid),
        )
    return bool(next_state)


__all__ = [
    "DB_PATH",
    "DatabaseError",
    "DatabaseValidationError",
    "get_active_alerts",
    "get_db",
    "get_recent_telemetry",
    "get_user_routines",
    "init_db",
    "insert_cognitive_alert",
    "insert_game_telemetry",
    "toggle_routine_status",
]
