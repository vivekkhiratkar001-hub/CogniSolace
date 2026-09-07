"""
CogniSolace - Recommendation Engine
Module: ai/adaptive/recommendation.py

Responsible for analyzing user performance across cognitive domains
and recommending targeted activities to address weaker cognitive areas
or promote progression.
"""

from typing import Any, Dict, List, Optional, Tuple

COGNITIVE_AREAS: List[str] = [
    "memory",
    "attention",
    "recall",
    "sequence_memory",
]

# Mapping of known game identifiers to cognitive domains
GAME_TO_AREA_MAP: Dict[str, str] = {
    # Memory
    "memory": "memory",
    "card_match": "memory",
    "pattern_memory": "memory",
    "spatial_memory": "memory",
    "visual_memory": "memory",
    # Attention
    "attention": "attention",
    "focus": "attention",
    "stroop": "attention",
    "reaction": "attention",
    "visual_search": "attention",
    # Recall
    "recall": "recall",
    "word_recall": "recall",
    "object_recall": "recall",
    "delayed_recall": "recall",
    "verbal_recall": "recall",
    # Sequence Memory
    "sequence_memory": "sequence_memory",
    "sequence": "sequence_memory",
    "simon": "sequence_memory",
    "number_span": "sequence_memory",
    "digit_span": "sequence_memory",
}

# Progression order for high performance
PROGRESSION_MAP: Dict[str, str] = {
    "attention": "memory",
    "memory": "sequence_memory",
    "sequence_memory": "recall",
    "recall": "attention",
}

# Remediation / foundational support map for low performance
REMEDIATION_MAP: Dict[str, str] = {
    "sequence_memory": "memory",
    "recall": "memory",
    "memory": "attention",
    "attention": "attention",
}


def map_game_to_cognitive_area(game_name: str) -> str:
    """
    Resolves a game name to its corresponding cognitive domain.
    Defaults to 'memory' if unrecognized.
    """
    if not game_name or not isinstance(game_name, str):
        return "memory"

    clean_name = game_name.strip().lower().replace("-", "_").replace(" ", "_")
    if clean_name in GAME_TO_AREA_MAP:
        return GAME_TO_AREA_MAP[clean_name]

    for area in COGNITIVE_AREAS:
        if area in clean_name:
            return area

    return "memory"


def build_cognitive_profile(
    history: Optional[List[Dict[str, Any]]],
    current_game: Optional[str] = None,
    current_performance: Optional[float] = None,
) -> Dict[str, Dict[str, float]]:
    """
    Aggregates performance scores per cognitive domain from historical sessions
    and the current game result.

    Returns a dict mapping each cognitive area to:
      {
        "avg_score": float,
        "count": int,
      }
    """
    profile: Dict[str, List[float]] = {area: [] for area in COGNITIVE_AREAS}

    # Ingest past history
    if history and isinstance(history, list):
        for entry in history:
            if not isinstance(entry, dict):
                continue
            game = entry.get("game", "")
            area = entry.get("cognitive_area") or map_game_to_cognitive_area(game)
            if area not in profile:
                profile[area] = []

            # Check if performance_score is present, or fallback to score/accuracy
            score = entry.get("performance_score")
            if score is None:
                score = entry.get("score")
            if score is None:
                score = entry.get("accuracy")

            if isinstance(score, (int, float)):
                profile[area].append(float(score))

    # Ingest current game
    if current_game is not None and current_performance is not None:
        curr_area = map_game_to_cognitive_area(current_game)
        if curr_area in profile:
            profile[curr_area].append(float(current_performance))

    summary: Dict[str, Dict[str, float]] = {}
    for area, scores in profile.items():
        if scores:
            summary[area] = {
                "avg_score": round(sum(scores) / len(scores), 2),
                "count": len(scores),
            }
        else:
            summary[area] = {
                "avg_score": -1.0,  # Untested area
                "count": 0,
            }

    return summary


def get_rotated_untested_area(
    curr_area: str,
    untested_areas: List[str],
    rotation_offset: Optional[int] = None,
) -> str:
    """
    Deterministically selects an untested cognitive domain using rotation
    to ensure recommendation diversity during cold-start (no history).
    Avoids always selecting the first untested area.
    """
    if not untested_areas:
        return "memory"
    curr_idx = COGNITIVE_AREAS.index(curr_area) if curr_area in COGNITIVE_AREAS else 0
    offset = (curr_idx + 1) if rotation_offset is None else (curr_idx + int(rotation_offset))
    rot_idx = offset % len(untested_areas)
    return untested_areas[rot_idx]


def recommend_activity(
    current_game: str,
    performance_score: float,
    history: Optional[List[Dict[str, Any]]] = None,
    rotation_offset: Optional[int] = None,
) -> Tuple[str, str]:
    """
    Determines the next recommended cognitive activity and provides an explainable reason.

    Strategy:
    1. If multi-session history exists, identify the user's weaker cognitive area
       (lowest non-negative average score) or untested foundational areas.
    2. If current performance is very high (>= 75) and history is balanced or empty,
       recommend progressing to an advanced / complementary domain (e.g. memory -> sequence_memory).
    3. If current performance is low (< 50), recommend reinforcing foundational skills
       or reviewing the current domain.
    4. Otherwise (moderate/steady performance), deterministically rotate across untested areas
       to ensure cold-start diversity without randomness.

    Returns:
        (recommended_activity, reason_explanation)
    """
    curr_area = map_game_to_cognitive_area(current_game)
    profile = build_cognitive_profile(history, current_game, performance_score)

    tested_areas = {
        area: data["avg_score"]
        for area, data in profile.items()
        if data["count"] > 0 and data["avg_score"] >= 0
    }
    untested_areas = [area for area, data in profile.items() if data["count"] == 0]

    # Scenario A: Historical data reveals a clearly weaker area (< 70 average and lower than current area)
    if len(tested_areas) >= 2:
        # Find area with lowest average score
        weaker_area = min(tested_areas, key=tested_areas.get)
        weaker_score = tested_areas[weaker_area]

        # If the weaker area has a lower score than current performance and is below 70
        if weaker_score < performance_score and weaker_score < 70.0:
            reason = (
                f"Historical analysis indicates lower performance in {weaker_area} "
                f"(average score: {weaker_score:.1f}). Targeted practice is recommended "
                f"to strengthen this cognitive domain."
            )
            return weaker_area, reason

    # Scenario B: High performance in current game -> Progression
    if performance_score >= 75.0:
        # Progress to next difficulty domain
        recommended = PROGRESSION_MAP.get(curr_area, "sequence_memory")
        reason = (
            f"High accuracy and good response speed indicate that the "
            f"user can progress to a harder activity."
        )
        return recommended, reason

    # Scenario C: Low performance in current game (< 50) -> Remediation / Focus
    if performance_score < 50.0:
        recommended = REMEDIATION_MAP.get(curr_area, curr_area)
        if recommended == curr_area:
            reason = (
                f"Current score in {curr_area} ({performance_score:.1f}) suggests that additional "
                f"practice at a comfortable pace will reinforce core skill retention."
            )
        else:
            reason = (
                f"Reinforcing foundational {recommended} skills will help improve performance "
                f"in {curr_area}."
            )
        return recommended, reason

    # Scenario D: Moderate / balanced performance (50 <= score < 75)
    # Check for untested areas to encourage rounded practice via deterministic rotation
    if untested_areas:
        recommended = get_rotated_untested_area(curr_area, untested_areas, rotation_offset)
        reason = (
            f"Steady performance in {curr_area}. Introducing {recommended} to maintain "
            f"a well-rounded cognitive routine."
        )
        return recommended, reason

    # Rotate to a complementary domain
    recommended = PROGRESSION_MAP.get(curr_area, "memory")
    reason = (
        f"Consistent cognitive engagement in {curr_area}. Continuing with {recommended} "
        f"for balanced cognitive development."
    )
    return recommended, reason
