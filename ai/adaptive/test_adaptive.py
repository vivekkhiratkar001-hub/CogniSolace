"""
Unit Tests for CogniSolace Adaptive Learning Engine
Module: ai/adaptive/test_adaptive.py

Verifies:
- High, medium, and low performance evaluations
- Formula accuracy (60% Accuracy, 25% Speed, 15% Score)
- Gradual difficulty transitions (no direct easy <-> hard jumps)
- Input validation (missing fields, out-of-range values, invalid types)
- Outlier mitigation via historical moving average
- Cognitive area activity recommendations
- JSON serializability
"""

import json
import os
import sys
import unittest

# Ensure the adaptive module directory is in sys.path
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
if CURRENT_DIR not in sys.path:
    sys.path.insert(0, CURRENT_DIR)

from adaptive_engine import (
    analyze_performance,
    calculate_performance_score,
    calculate_speed_score,
    compute_effective_score,
    determine_next_difficulty,
    validate_game_result,
    validate_history,
)
from recommendation import (
    COGNITIVE_AREAS,
    build_cognitive_profile,
    get_rotated_untested_area,
    map_game_to_cognitive_area,
    recommend_activity,
)


class TestAdaptivePerformance(unittest.TestCase):
    """Tests for performance and speed calculations."""

    def test_sample_game_result_matches_spec(self):
        """Validates that the hackathon sample input produces the expected output."""
        sample = {
            "game": "memory",
            "score": 85,
            "accuracy": 90,
            "attempts": 8,
            "duration": 42,
            "difficulty": "medium",
        }
        res = analyze_performance(sample)
        self.assertEqual(res["performance_score"], 82.4)
        self.assertEqual(res["next_difficulty"], "hard")
        self.assertEqual(res["recommended_activity"], "sequence_memory")
        self.assertEqual(res["confidence"], 0.87)
        self.assertIn("High accuracy and good response speed", res["reason"])

    def test_high_performance(self):
        """High accuracy and fast duration should promote difficulty."""
        result = {
            "game": "memory",
            "score": 95,
            "accuracy": 98,
            "attempts": 5,
            "duration": 20,
            "difficulty": "medium",
        }
        res = analyze_performance(result)
        self.assertGreaterEqual(res["performance_score"], 75.0)
        self.assertEqual(res["next_difficulty"], "hard")

    def test_medium_performance(self):
        """Moderate scores should maintain current difficulty."""
        result = {
            "game": "memory",
            "score": 60,
            "accuracy": 65,
            "attempts": 10,
            "duration": 40,
            "difficulty": "medium",
        }
        res = analyze_performance(result)
        self.assertTrue(50.0 <= res["performance_score"] < 75.0)
        self.assertEqual(res["next_difficulty"], "medium")

    def test_low_performance(self):
        """Low accuracy and slow completion should demote difficulty."""
        result = {
            "game": "memory",
            "score": 25,
            "accuracy": 35,
            "attempts": 15,
            "duration": 90,
            "difficulty": "medium",
        }
        res = analyze_performance(result)
        self.assertLess(res["performance_score"], 50.0)
        self.assertEqual(res["next_difficulty"], "easy")

    def test_exact_performance_formula_weights(self):
        """Verifies exact 60% accuracy, 25% speed, 15% score weighting."""
        acc = 80.0
        spd = 60.0
        sc = 70.0
        # Expected: 0.60*80 + 0.25*60 + 0.15*70 = 48 + 15 + 10.5 = 73.5
        score = calculate_performance_score(acc, spd, sc)
        self.assertEqual(score, 73.5)

    def test_speed_score_monotonicity(self):
        """Faster durations should strictly yield equal or higher speed scores."""
        spd_fast = calculate_speed_score("memory", "medium", 20.0)
        spd_norm = calculate_speed_score("memory", "medium", 35.0)
        spd_slow = calculate_speed_score("memory", "medium", 70.0)

        self.assertGreaterEqual(spd_fast, spd_norm)
        self.assertGreaterEqual(spd_norm, spd_slow)
        self.assertEqual(spd_norm, 75.0)  # Benchmark target is 75.0

    def test_score_below_max_score(self):
        """score=250, max_score=500 yields 50% normalized score."""
        # 0.60*80 + 0.25*60 + 0.15*(250/500*100 = 50) = 48 + 15 + 7.5 = 70.5
        score = calculate_performance_score(accuracy=80.0, speed_score=60.0, raw_score=250.0, max_score=500.0)
        self.assertEqual(score, 70.5)

    def test_score_equal_to_max_score(self):
        """score=500, max_score=500 yields 100% normalized score."""
        # 0.60*80 + 0.25*60 + 0.15*(500/500*100 = 100) = 48 + 15 + 15 = 78.0
        score = calculate_performance_score(accuracy=80.0, speed_score=60.0, raw_score=500.0, max_score=500.0)
        self.assertEqual(score, 78.0)

    def test_score_above_max_score(self):
        """score=600, max_score=500 clamps normalized score to 100%."""
        score = calculate_performance_score(accuracy=80.0, speed_score=60.0, raw_score=600.0, max_score=500.0)
        self.assertEqual(score, 78.0)

    def test_custom_max_score_in_analyze_performance(self):
        """analyze_performance properly passes and processes custom max_score."""
        payload = {
            "game": "memory",
            "score": 425,
            "max_score": 500,
            "accuracy": 90,
            "attempts": 8,
            "duration": 42,
            "difficulty": "medium",
        }
        # 425/500 = 85%, identical to score=85 with default max_score=100
        res = analyze_performance(payload)
        self.assertEqual(res["performance_score"], 82.4)
        self.assertEqual(res["next_difficulty"], "hard")


class TestDifficultyTransitions(unittest.TestCase):
    """Tests gradual difficulty state machine (no easy <-> hard jumps)."""

    def test_easy_transitions(self):
        # High score promotes to medium, never hard
        self.assertEqual(determine_next_difficulty("easy", 95.0), "medium")
        self.assertEqual(determine_next_difficulty("easy", 100.0), "medium")
        # Low/moderate score stays easy
        self.assertEqual(determine_next_difficulty("easy", 60.0), "easy")
        self.assertEqual(determine_next_difficulty("easy", 20.0), "easy")

    def test_medium_transitions(self):
        # High score promotes to hard
        self.assertEqual(determine_next_difficulty("medium", 85.0), "hard")
        # Low score demotes to easy
        self.assertEqual(determine_next_difficulty("medium", 40.0), "easy")
        # Stable score maintains medium
        self.assertEqual(determine_next_difficulty("medium", 65.0), "medium")

    def test_hard_transitions(self):
        # High/moderate score stays hard
        self.assertEqual(determine_next_difficulty("hard", 90.0), "hard")
        self.assertEqual(determine_next_difficulty("hard", 60.0), "hard")
        # Low score demotes to medium, never directly to easy
        self.assertEqual(determine_next_difficulty("hard", 35.0), "medium")
        self.assertEqual(determine_next_difficulty("hard", 0.0), "medium")


class TestInputValidation(unittest.TestCase):
    """Tests input structure and bounds validation."""

    def test_missing_fields(self):
        incomplete = {"game": "memory", "score": 80, "accuracy": 90}
        with self.assertRaises(ValueError):
            validate_game_result(incomplete)

    def test_invalid_type(self):
        with self.assertRaises(TypeError):
            validate_game_result(["game", "memory"])

    def test_invalid_game_name(self):
        with self.assertRaises(ValueError):
            validate_game_result({
                "game": "",
                "score": 80,
                "accuracy": 90,
                "duration": 30,
                "difficulty": "medium",
            })

    def test_invalid_accuracy_bounds(self):
        payload_low = {
            "game": "memory",
            "score": 80,
            "accuracy": -1,
            "duration": 30,
            "difficulty": "medium",
        }
        with self.assertRaises(ValueError):
            validate_game_result(payload_low)

        payload_high = {
            "game": "memory",
            "score": 80,
            "accuracy": 105,
            "duration": 30,
            "difficulty": "medium",
        }
        with self.assertRaises(ValueError):
            validate_game_result(payload_high)

    def test_invalid_score(self):
        payload = {
            "game": "memory",
            "score": -5,
            "accuracy": 80,
            "duration": 30,
            "difficulty": "medium",
        }
        with self.assertRaises(ValueError):
            validate_game_result(payload)

    def test_invalid_duration(self):
        payload_zero = {
            "game": "memory",
            "score": 80,
            "accuracy": 80,
            "duration": 0,
            "difficulty": "medium",
        }
        with self.assertRaises(ValueError):
            validate_game_result(payload_zero)

        payload_neg = {
            "game": "memory",
            "score": 80,
            "accuracy": 80,
            "duration": -10,
            "difficulty": "medium",
        }
        with self.assertRaises(ValueError):
            validate_game_result(payload_neg)

    def test_invalid_difficulty(self):
        payload = {
            "game": "memory",
            "score": 80,
            "accuracy": 80,
            "duration": 30,
            "difficulty": "nightmare",
        }
        with self.assertRaises(ValueError):
            validate_game_result(payload)

    def test_invalid_max_score_zero_or_negative(self):
        payload_zero = {
            "game": "memory",
            "score": 80,
            "max_score": 0,
            "accuracy": 80,
            "duration": 30,
            "difficulty": "medium",
        }
        with self.assertRaises(ValueError):
            validate_game_result(payload_zero)

        payload_neg = {
            "game": "memory",
            "score": 80,
            "max_score": -100,
            "accuracy": 80,
            "duration": 30,
            "difficulty": "medium",
        }
        with self.assertRaises(ValueError):
            validate_game_result(payload_neg)

        with self.assertRaises(ValueError):
            calculate_performance_score(80.0, 70.0, 50.0, max_score=0)

    def test_invalid_history_type(self):
        with self.assertRaises(TypeError):
            validate_history("not_a_list")

        with self.assertRaises(TypeError):
            validate_history(12345)

        with self.assertRaises(TypeError):
            validate_history({"session": 1})

        # Calling analyze_performance with invalid history type raises TypeError
        valid_result = {
            "game": "memory",
            "score": 80,
            "accuracy": 80,
            "duration": 30,
            "difficulty": "medium",
        }
        with self.assertRaises(TypeError):
            analyze_performance(valid_result, history="invalid_history_string")


class TestMovingAverageAndHistory(unittest.TestCase):
    """Tests historical moving average to prevent outlier-induced difficulty shifts."""

    def test_lucky_outlier_game_does_not_prematurely_promote(self):
        """User with consistent low scores has 1 lucky game; moving average stabilizes difficulty."""
        history = [
            {"game": "memory", "performance_score": 38.0},
            {"game": "memory", "performance_score": 42.0},
            {"game": "memory", "performance_score": 40.0},
        ]
        # Current lucky game with high performance
        current_result = {
            "game": "memory",
            "score": 90,
            "accuracy": 92,
            "duration": 25,
            "difficulty": "easy",
        }
        res = analyze_performance(current_result, history=history)
        # Current score ~87, but history avg ~40 => effective score ~63.5 (<75)
        # Therefore, easy difficulty does not prematurely promote!
        self.assertEqual(res["next_difficulty"], "easy")
        self.assertIn("Historical moving average", res["reason"])

    def test_unlucky_outlier_game_does_not_prematurely_demote(self):
        """User with high scores has 1 bad game; moving average prevents immediate demotion."""
        history = [
            {"game": "memory", "performance_score": 85.0},
            {"game": "memory", "performance_score": 88.0},
            {"game": "memory", "performance_score": 82.0},
        ]
        # Current anomalous bad game
        current_result = {
            "game": "memory",
            "score": 30,
            "accuracy": 35,
            "duration": 85,
            "difficulty": "hard",
        }
        res = analyze_performance(current_result, history=history)
        # Effective score stays above 50 due to strong history, preventing demotion
        self.assertEqual(res["next_difficulty"], "hard")
        self.assertIn("Historical moving average", res["reason"])

    def test_empty_or_none_history(self):
        """Engine behaves reliably when history is None or empty."""
        result = {
            "game": "attention",
            "score": 80,
            "accuracy": 85,
            "duration": 20,
            "difficulty": "medium",
        }
        res_none = analyze_performance(result, history=None)
        res_empty = analyze_performance(result, history=[])
        self.assertEqual(res_none["performance_score"], res_empty["performance_score"])
        self.assertEqual(res_none["next_difficulty"], res_empty["next_difficulty"])


class TestRecommendationLogic(unittest.TestCase):
    """Tests cognitive domain tracking and activity recommendations."""

    def test_recommends_weaker_cognitive_area_from_history(self):
        """When history shows lower performance in a specific cognitive domain, recommend it."""
        history = [
            {"game": "memory", "performance_score": 85.0},
            {"game": "attention", "performance_score": 82.0},
            {"game": "recall", "performance_score": 45.0},  # distinctly weaker
        ]
        current_game = {
            "game": "memory",
            "score": 88,
            "accuracy": 90,
            "duration": 30,
            "difficulty": "medium",
        }
        res = analyze_performance(current_game, history=history)
        # Should detect recall as the weaker area needing targeted training
        self.assertEqual(res["recommended_activity"], "recall")
        self.assertIn("lower performance in recall", res["reason"])

    def test_progression_recommendation_on_high_score(self):
        """When user excels in memory, recommend sequence_memory for progression."""
        activity, reason = recommend_activity("memory", 85.0)
        self.assertEqual(activity, "sequence_memory")
        self.assertIn("progress to a harder activity", reason)

    def test_remediation_recommendation_on_low_score(self):
        """When user struggles in sequence_memory, recommend foundational memory."""
        activity, reason = recommend_activity("sequence_memory", 40.0)
        self.assertEqual(activity, "memory")

    def test_cognitive_profile_aggregation(self):
        """Verifies that past history properly aggregates domain scores."""
        history = [
            {"game": "card_match", "performance_score": 80.0},
            {"game": "stroop", "performance_score": 60.0},
        ]
        profile = build_cognitive_profile(history, "word_recall", 75.0)
        self.assertEqual(profile["memory"]["avg_score"], 80.0)
        self.assertEqual(profile["attention"]["avg_score"], 60.0)
        self.assertEqual(profile["recall"]["avg_score"], 75.0)
        self.assertEqual(profile["sequence_memory"]["avg_score"], -1.0)  # Untested

    def test_cold_start_recommendation_rotation(self):
        """Validates that cold-start untested area selection deterministically rotates across domains."""
        # For moderate score (65.0), no history
        rec_mem, _ = recommend_activity("memory", 65.0)
        rec_att, _ = recommend_activity("attention", 65.0)
        rec_rec, _ = recommend_activity("recall", 65.0)
        rec_seq, _ = recommend_activity("sequence_memory", 65.0)

        # Ensure recommendation is not identical for every game
        recommended_set = {rec_mem, rec_att, rec_rec, rec_seq}
        self.assertGreater(len(recommended_set), 1)

        # Test rotation helper directly with offsets
        untested = ["attention", "recall", "sequence_memory"]
        first = get_rotated_untested_area("memory", untested, rotation_offset=0)
        second = get_rotated_untested_area("memory", untested, rotation_offset=1)
        third = get_rotated_untested_area("memory", untested, rotation_offset=2)

        # Offsets rotate through all available untested domains
        self.assertEqual({first, second, third}, set(untested))


class TestJSONSerialization(unittest.TestCase):
    """Ensures output is 100% JSON-serializable for FastAPI/Member 5."""

    def test_json_dumps(self):
        sample = {
            "game": "sequence_memory",
            "score": 75,
            "accuracy": 80,
            "attempts": 6,
            "duration": 38,
            "difficulty": "medium",
        }
        res = analyze_performance(sample)
        # Must serialize cleanly without errors
        serialized = json.dumps(res)
        deserialized = json.loads(serialized)
        self.assertIsInstance(deserialized["performance_score"], float)
        self.assertIsInstance(deserialized["next_difficulty"], str)
        self.assertIsInstance(deserialized["recommended_activity"], str)
        self.assertIsInstance(deserialized["confidence"], float)
        self.assertIsInstance(deserialized["reason"], str)


if __name__ == "__main__":
    unittest.main()
