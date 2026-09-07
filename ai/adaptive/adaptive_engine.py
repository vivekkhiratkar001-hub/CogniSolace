"""
CogniSolace - Adaptive Learning Engine
Module: ai/adaptive/adaptive_engine.py

Provides explainable, lightweight adaptive difficulty adjustment and
performance analysis for cognitive games in CogniSolace.

Key Design Principles:
1. Pure Python standard library (zero heavy ML/DL dependencies).
2. Fully explainable mathematical formulation.
3. Gradual difficulty transitions (no direct easy <-> hard jumps).
4. Outlier mitigation using moving average of historical sessions.
5. Actionable recommendations based on cognitive domains.
"""

from typing import Any, Dict, List, Optional, Tuple
try:
    from recommendation import map_game_to_cognitive_area, recommend_activity
except ImportError:
    from ai.adaptive.recommendation import map_game_to_cognitive_area, recommend_activity

# Expected completion durations in seconds by game and difficulty level
EXPECTED_DURATIONS: Dict[str, Dict[str, float]] = {
    "memory": {"easy": 25.0, "medium": 35.0, "hard": 50.0},
    "attention": {"easy": 15.0, "medium": 25.0, "hard": 40.0},
    "recall": {"easy": 20.0, "medium": 30.0, "hard": 45.0},
    "sequence_memory": {"easy": 25.0, "medium": 40.0, "hard": 60.0},
}

# Fallback durations for unknown games
DEFAULT_EXPECTED_DURATIONS: Dict[str, float] = {
    "easy": 25.0,
    "medium": 35.0,
    "hard": 50.0,
}

# Difficulty thresholds
PROMOTION_THRESHOLD: float = 75.0
DEMOTION_THRESHOLD: float = 50.0

VALID_DIFFICULTIES: set = {"easy", "medium", "hard"}
REQUIRED_FIELDS: set = {"game", "score", "accuracy", "duration", "difficulty"}


def validate_history(history: Any) -> None:
    """
    Validates that history, if provided, is a list.

    Raises:
        TypeError: If history is not None and not a list.
    """
    if history is not None and not isinstance(history, list):
        raise TypeError(f"'history' must be a list or None, got {type(history).__name__}")


def validate_game_result(game_result: Dict[str, Any]) -> None:
    """
    Validates the structure and values of the input game_result dictionary.

    Raises:
        TypeError: If game_result is not a dictionary.
        ValueError: If required fields are missing or values are out of bounds.
    """
    if not isinstance(game_result, dict):
        raise TypeError(f"game_result must be a dict, got {type(game_result).__name__}")

    # Check for missing fields
    missing = REQUIRED_FIELDS - set(game_result.keys())
    if missing:
        raise ValueError(f"Missing required field(s) in game_result: {', '.join(sorted(missing))}")

    # Validate game name
    game = game_result.get("game")
    if not isinstance(game, str) or not game.strip():
        raise ValueError("Field 'game' must be a non-empty string.")

    # Validate accuracy (0 - 100)
    accuracy = game_result.get("accuracy")
    if isinstance(accuracy, bool) or not isinstance(accuracy, (int, float)):
        raise ValueError(f"Field 'accuracy' must be a numeric value, got {type(accuracy).__name__}")
    if accuracy < 0 or accuracy > 100:
        raise ValueError(f"Invalid accuracy: {accuracy}. Must be between 0 and 100.")

    # Validate score (>= 0)
    score = game_result.get("score")
    if isinstance(score, bool) or not isinstance(score, (int, float)):
        raise ValueError(f"Field 'score' must be a numeric value, got {type(score).__name__}")
    if score < 0:
        raise ValueError(f"Invalid score: {score}. Must be a non-negative number.")

    # Validate optional max_score (> 0)
    if "max_score" in game_result:
        max_score = game_result.get("max_score")
        if isinstance(max_score, bool) or not isinstance(max_score, (int, float)):
            raise ValueError(f"Field 'max_score' must be a numeric value, got {type(max_score).__name__}")
        if max_score <= 0:
            raise ValueError(f"Invalid max_score: {max_score}. Must be greater than 0.")

    # Validate duration (> 0)
    duration = game_result.get("duration")
    if isinstance(duration, bool) or not isinstance(duration, (int, float)):
        raise ValueError(f"Field 'duration' must be a numeric value, got {type(duration).__name__}")
    if duration <= 0:
        raise ValueError(f"Invalid duration: {duration}. Must be greater than 0.")

    # Validate difficulty
    difficulty = game_result.get("difficulty")
    if not isinstance(difficulty, str) or difficulty.strip().lower() not in VALID_DIFFICULTIES:
        raise ValueError(
            f"Invalid difficulty: '{difficulty}'. Must be one of 'easy', 'medium', or 'hard'."
        )


def calculate_speed_score(game: str, difficulty: str, duration: float) -> float:
    """
    Calculates a normalized speed score (0 - 100) comparing actual duration
    against the benchmark expected duration for the given game and difficulty.

    Formula:
      ratio = expected_duration / actual_duration
      speed_score = clamp(ratio * 75.0, 0.0, 100.0)

    - Meeting the target duration produces a solid benchmark score of 75.0.
    - Faster completion scales smoothly up to 100.0.
    - Slower completion scales down smoothly toward 0.0.
    """
    clean_game = game.strip().lower().replace("-", "_").replace(" ", "_")
    clean_diff = difficulty.strip().lower()

    expected_table = EXPECTED_DURATIONS.get(clean_game, DEFAULT_EXPECTED_DURATIONS)
    expected_duration = expected_table.get(clean_diff, DEFAULT_EXPECTED_DURATIONS.get(clean_diff, 35.0))

    if duration <= 0:
        return 0.0

    ratio = expected_duration / float(duration)
    raw_speed = ratio * 75.0
    return round(max(0.0, min(100.0, raw_speed)), 2)


def calculate_performance_score(
    accuracy: float,
    speed_score: float,
    raw_score: float,
    max_score: float = 100.0,
) -> float:
    """
    Calculates composite performance score normalized to 0 - 100:
      Accuracy  = 60%
      Speed     = 25%
      Score     = 15% (normalized to 0 - 100 via (score / max_score) * 100)
    """
    if max_score <= 0:
        raise ValueError(f"max_score must be greater than 0, got {max_score}")

    normalized_score = max(0.0, min(100.0, (float(raw_score) / float(max_score)) * 100.0))
    composite = (0.60 * float(accuracy)) + (0.25 * float(speed_score)) + (0.15 * normalized_score)
    return round(max(0.0, min(100.0, composite)), 1)


def compute_effective_score(
    current_score: float,
    history: Optional[List[Dict[str, Any]]] = None,
) -> Tuple[float, bool]:
    """
    Applies a moving average over recent history to mitigate single-session outliers.

    Returns:
        (effective_score, was_smoothed)
    """
    if not history or not isinstance(history, list):
        return current_score, False

    past_scores: List[float] = []
    # Take up to last 4 historical sessions
    for entry in history[-4:]:
        if not isinstance(entry, dict):
            continue
        val = entry.get("performance_score")
        if val is None:
            # Fallback estimation if raw metrics exist
            acc = entry.get("accuracy")
            sc = entry.get("score")
            dur = entry.get("duration")
            diff = entry.get("difficulty", "medium")
            gm = entry.get("game", "memory")
            if acc is not None and sc is not None and dur is not None:
                try:
                    spd = calculate_speed_score(gm, diff, float(dur))
                    max_sc = float(entry.get("max_score", 100.0))
                    val = calculate_performance_score(float(acc), spd, float(sc), max_score=max_sc)
                except Exception:
                    val = None
        if isinstance(val, (int, float)):
            past_scores.append(float(val))

    if not past_scores:
        return current_score, False

    # Weighted moving average: 50% current game, 50% historical average
    history_avg = sum(past_scores) / len(past_scores)
    effective = (0.50 * current_score) + (0.50 * history_avg)
    was_smoothed = abs(effective - current_score) >= 5.0
    return round(effective, 1), was_smoothed


def determine_next_difficulty(current_difficulty: str, effective_score: float) -> str:
    """
    Determines next difficulty level ensuring gradual transitions:
      - 'easy' -> 'medium' (if high) or stays 'easy'.
      - 'medium' -> 'hard' (if high) or 'easy' (if low) or stays 'medium'.
      - 'hard' -> 'medium' (if low) or stays 'hard'.
      - Strictly avoids direct 'easy' <-> 'hard' jumps.
    """
    diff = current_difficulty.strip().lower()

    if diff == "easy":
        if effective_score >= PROMOTION_THRESHOLD:
            return "medium"
        return "easy"

    if diff == "medium":
        if effective_score >= PROMOTION_THRESHOLD:
            return "hard"
        if effective_score < DEMOTION_THRESHOLD:
            return "easy"
        return "medium"

    if diff == "hard":
        if effective_score < DEMOTION_THRESHOLD:
            return "medium"
        return "hard"

    return "medium"


def calculate_confidence(
    current_score: float,
    effective_score: float,
    history: Optional[List[Dict[str, Any]]] = None,
) -> float:
    """
    Calculates confidence score (0.0 - 1.0) in the adaptive recommendation.
    Higher history count and clear separation from decision boundaries increase confidence.
    """
    # Strong base confidence for clear performance signals
    base_confidence = 0.84

    # History bonus: +0.03 per prior session, capped at +0.10
    history_count = len(history) if (history and isinstance(history, list)) else 0
    history_bonus = min(0.10, history_count * 0.03)

    # Margin bonus: higher confidence when score is clearly beyond thresholds rather than borderline
    margin = min(abs(effective_score - PROMOTION_THRESHOLD), abs(effective_score - DEMOTION_THRESHOLD))
    margin_bonus = min(0.10, (margin / 25.0) * 0.10)

    # Outlier penalty if current differs dramatically from moving average
    outlier_penalty = 0.08 if abs(current_score - effective_score) > 15.0 else 0.0

    confidence = base_confidence + history_bonus + margin_bonus - outlier_penalty
    return round(max(0.50, min(0.98, confidence)), 2)


def generate_reason(
    accuracy: float,
    speed_score: float,
    current_difficulty: str,
    next_difficulty: str,
    was_smoothed: bool,
    activity_reason: str,
) -> str:
    """
    Constructs an explainable rationale combining performance insights and recommendation.
    """
    # If a specific weaker domain was targeted from history, highlight it in the rationale
    if activity_reason and ("lower performance" in activity_reason or "Targeted practice" in activity_reason):
        base_reason = activity_reason
    elif accuracy >= 85.0 and speed_score >= 60.0:
        base_reason = "High accuracy and good response speed indicate that the user can progress to a harder activity."
    elif accuracy >= 75.0:
        base_reason = "Strong accuracy demonstrates solid grasp of current cognitive tasks."
    elif accuracy < 60.0:
        base_reason = "Lower accuracy indicates that pacing down or practicing fundamentals will benefit retention."
    else:
        base_reason = "Steady accuracy and balanced response times reflect consistent cognitive control."

    if was_smoothed:
        return f"{base_reason} (Historical moving average stabilized performance evaluation.)"

    return base_reason


def analyze_performance(
    game_result: Dict[str, Any],
    history: Optional[List[Dict[str, Any]]] = None,
) -> Dict[str, Any]:
    """
    Main entry point for CogniSolace Adaptive Learning Engine.

    Evaluates game performance, computes speed and normalized scores,
    smooths assessment via historical moving average, adjusts difficulty gradually,
    and recommends the next targeted cognitive activity.

    Parameters:
        game_result (dict):
            {
                "game": str,
                "score": float/int,
                "accuracy": float/int,
                "duration": float/int,
                "difficulty": "easy" | "medium" | "hard",
                "attempts": int (optional)
            }
        history (list of dict, optional): List of previous game results / scores.

    Returns:
        dict:
            {
                "performance_score": float (0 - 100),
                "next_difficulty": "easy" | "medium" | "hard",
                "recommended_activity": str,
                "confidence": float (0.0 - 1.0),
                "reason": str
            }
    """
    # 1. Validation
    validate_history(history)
    validate_game_result(game_result)

    game = game_result["game"].strip().lower()
    difficulty = game_result["difficulty"].strip().lower()
    accuracy = float(game_result["accuracy"])
    raw_score = float(game_result["score"])
    duration = float(game_result["duration"])
    max_score = float(game_result.get("max_score", 100.0))

    # 2. Compute Speed Score (0 - 100)
    speed_score = calculate_speed_score(game, difficulty, duration)

    # 3. Compute Composite Performance Score (60% Acc, 25% Speed, 15% Score)
    performance_score = calculate_performance_score(
        accuracy=accuracy,
        speed_score=speed_score,
        raw_score=raw_score,
        max_score=max_score,
    )

    # 4. Outlier Smoothing via Historical Moving Average
    effective_score, was_smoothed = compute_effective_score(performance_score, history)

    # 5. Determine Next Difficulty (Gradual State Machine)
    next_diff = determine_next_difficulty(difficulty, effective_score)

    # 6. Recommend Next Activity based on Weak Area / Progression
    rec_activity, act_reason = recommend_activity(game, performance_score, history)

    # 7. Compute Confidence Score
    confidence = calculate_confidence(performance_score, effective_score, history)

    # 8. Generate Human-Readable Explainable Reason
    reason = generate_reason(
        accuracy=accuracy,
        speed_score=speed_score,
        current_difficulty=difficulty,
        next_difficulty=next_diff,
        was_smoothed=was_smoothed,
        activity_reason=act_reason,
    )

    return {
        "performance_score": float(performance_score),
        "next_difficulty": str(next_diff),
        "recommended_activity": str(rec_activity),
        "confidence": float(confidence),
        "reason": str(reason),
    }
