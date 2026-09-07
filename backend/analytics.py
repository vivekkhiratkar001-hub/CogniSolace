"""On-device cognitive drift detection for CogniSolace.

Uses only the Python standard library (`math`, `statistics`) so a single
session evaluation stays well under a millisecond on edge hardware. Historical
windows are typically 3–20 rows; work is O(n) with no heap allocations beyond
two small float lists.
"""

from __future__ import annotations

import math
import statistics
from typing import Any, Final, Mapping

SessionRecord = Mapping[str, Any]
DriftVerdict = tuple[bool, str, str]


class CognitiveDriftEngine:
    """Rule-based biometric comparator against a short personal baseline.

    Processing speed is defined as ``duration_seconds / attempts`` (seconds per
    attempt). Larger values mean slower responses and therefore *degraded*
    performance. Accuracy drops and latency increases are measured as relative
    fractions of the historical mean, not absolute percentage-point deltas.

    Severity labels
    ---------------
    NORMAL
        Insufficient history; baseline is still being established.
    HIGH
        Concurrent severe accuracy collapse and slowing (acute concern).
    WARNING
        Isolated accuracy drop or latency increase.
    STABLE
        Current session is within the configured relative bands.
    """

    MIN_BASELINE_SESSIONS: Final[int] = 3
    SEVERE_ACCURACY_DROP: Final[float] = 0.35
    SEVERE_SPEED_DEGRADE: Final[float] = 0.40
    MILD_ACCURACY_DROP: Final[float] = 0.20
    MILD_LATENCY_INCREASE: Final[float] = 0.30

    _MSG_BASELINE: Final[str] = "Establishing user baseline"
    _MSG_HIGH: Final[str] = "Acute cognitive fatigue or rapid disorientation detected."
    _MSG_WARNING: Final[str] = "Mild performance drop observed."
    _MSG_STABLE: Final[str] = "Performance within normal variation."

    def analyze_performance(
        self,
        recent_sessions: list[dict[str, Any]],
        current_game: dict[str, Any],
    ) -> DriftVerdict:
        """Compare the latest game against the user's short-horizon baseline.

        Parameters
        ----------
        recent_sessions
            Historical telemetry rows (typically from ``get_recent_telemetry``).
            Must not include the session represented by ``current_game``.
        current_game
            The just-completed session. Requires ``accuracy``,
            ``duration_seconds``, and ``attempts``.

        Returns
        -------
        tuple[bool, str, str]
            ``(anomaly_detected, severity, message)``.

        Raises
        ------
        ValueError
            If ``current_game`` is missing required numeric fields, attempts
            are non-positive, or values are non-finite.
        """
        current_accuracy, current_speed = self._extract_metrics(current_game, source="current_game")

        baseline_accuracies, baseline_speeds = self._collect_baseline_series(recent_sessions)
        if len(baseline_accuracies) < self.MIN_BASELINE_SESSIONS:
            return (False, "NORMAL", self._MSG_BASELINE)

        baseline_accuracy = statistics.fmean(baseline_accuracies)
        baseline_speed = statistics.fmean(baseline_speeds)

        accuracy_drop = self._relative_decline(baseline_accuracy, current_accuracy)
        speed_degrade = self._relative_increase(baseline_speed, current_speed)

        if (
            accuracy_drop >= self.SEVERE_ACCURACY_DROP
            and speed_degrade >= self.SEVERE_SPEED_DEGRADE
        ):
            return (True, "HIGH", self._MSG_HIGH)

        if accuracy_drop >= self.MILD_ACCURACY_DROP or speed_degrade >= self.MILD_LATENCY_INCREASE:
            return (True, "WARNING", self._MSG_WARNING)

        return (False, "STABLE", self._MSG_STABLE)

    def _collect_baseline_series(
        self,
        recent_sessions: list[dict[str, Any]] | None,
    ) -> tuple[list[float], list[float]]:
        """Return parallel accuracy and speed series, skipping corrupt rows."""
        accuracies: list[float] = []
        speeds: list[float] = []
        if not recent_sessions:
            return accuracies, speeds

        for index, session in enumerate(recent_sessions):
            if not isinstance(session, Mapping):
                continue
            try:
                accuracy, speed = self._extract_metrics(session, source=f"recent_sessions[{index}]")
            except (TypeError, ValueError, KeyError):
                continue
            accuracies.append(accuracy)
            speeds.append(speed)
        return accuracies, speeds

    def _extract_metrics(self, record: Mapping[str, Any], *, source: str) -> tuple[float, float]:
        """Return ``(accuracy, seconds_per_attempt)`` from a telemetry mapping."""
        accuracy = self._require_finite_float(record.get("accuracy"), field="accuracy", source=source)
        duration = self._require_finite_float(
            record.get("duration_seconds"),
            field="duration_seconds",
            source=source,
        )
        attempts = self._require_finite_float(record.get("attempts"), field="attempts", source=source)
        if attempts <= 0.0:
            raise ValueError(f"{source}: attempts must be > 0")
        if duration < 0.0:
            raise ValueError(f"{source}: duration_seconds must be >= 0")
        return accuracy, duration / attempts

    @staticmethod
    def _require_finite_float(value: Any, *, field: str, source: str) -> float:
        if value is None:
            raise ValueError(f"{source}: missing required field '{field}'")
        try:
            numeric = float(value)
        except (TypeError, ValueError) as exc:
            raise ValueError(f"{source}: '{field}' must be numeric") from exc
        if not math.isfinite(numeric):
            raise ValueError(f"{source}: '{field}' must be a finite number")
        return numeric

    @staticmethod
    def _relative_decline(baseline: float, current: float) -> float:
        """Fraction the current value fell relative to baseline (0 if baseline <= 0)."""
        if baseline <= 0.0:
            return 0.0 if current >= baseline else 1.0
        drop = (baseline - current) / baseline
        return drop if drop > 0.0 else 0.0

    @staticmethod
    def _relative_increase(baseline: float, current: float) -> float:
        """Fraction the current value rose relative to baseline (0 if baseline <= 0)."""
        if baseline <= 0.0:
            return 0.0 if current <= baseline else 1.0
        rise = (current - baseline) / baseline
        return rise if rise > 0.0 else 0.0


__all__ = ["CognitiveDriftEngine", "DriftVerdict", "SessionRecord"]
