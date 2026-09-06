# CogniSolace - Adaptive Learning Engine Walkthrough

> **File Path**: `ai/adaptive/walkthrough.md`  
> **Author**: Member 3 (Adaptive Learning / ML)  
> **Target Audience**: CogniSolace Development Team (Members 1, 2, 4, 5)

---

## 1. Executive Summary

The CogniSolace Adaptive Learning Engine provides real-time, explainable, lightweight cognitive evaluation and difficulty adjustment. It runs entirely on the pure Python 3 standard library with **zero heavy dependencies** (no PyTorch, TensorFlow, or complex external toolkits).

### Core Components:
- **`adaptive_engine.py`**: Entry point `analyze_performance(game_result, history=None)`, validation, speed scoring, score normalization (with dynamic `max_score`), composite weighting, historical moving average smoothing, gradual state transitions, and explainable rationale generation.
- **`recommendation.py`**: Cognitive domain mapping (`memory`, `attention`, `recall`, `sequence_memory`), multi-session profile tracking, weaker domain identification, and cold-start deterministic rotation across untested areas.
- **`test_adaptive.py`**: Comprehensive test suite verifying all formulas, constraints, edge cases, input validation, and history buffering.
- **`README.md`**: Module documentation and integration contracts for Member 5.

---

## 2. Mathematical Formulations

### Composite Performance Formula
$$\text{Performance Score} = 0.60 \times \text{Accuracy} + 0.25 \times \text{Speed Score} + 0.15 \times \text{Normalized Score}$$

- **Accuracy (60%)**: Fundamental metric of cognitive correctness and task precision ($0 \le \text{Accuracy} \le 100$).
- **Speed Score (25%)**: Measure of processing speed relative to calibrated benchmark durations ($0 \le \text{Speed Score} \le 100$).
- **Normalized Score (15%)**: In-game achievements and multipliers scaled via:
  $$\text{Normalized Score} = \text{clamp}\left(\frac{\text{score}}{\text{max\_score}} \times 100.0, \; 0.0, \; 100.0\right)$$
  *(Defaults to $\text{max\_score} = 100.0$ if omitted, preserving backward compatibility).*
- **Composite Normalization**: The final score is strictly clamped between $0.0$ and $100.0$, rounded to 1 decimal place.

### Speed Score Formula & Benchmarks
$$\text{Speed Score} = \text{clamp}\left(\frac{T_{\text{expected}}}{T_{\text{actual}}} \times 75.0, \; 0.0, \; 100.0\right)$$

- **Target Match ($T_{\text{actual}} = T_{\text{expected}}$)**: Baseline score of **75.0**.
- **Faster Completion ($T_{\text{actual}} < T_{\text{expected}}$)**: Continuously scales up to **100.0**.
- **Slower Completion ($T_{\text{actual}} > T_{\text{expected}}$)**: Continuously scales down toward **0.0**.

#### Calibrated Benchmarks ($T_{\text{expected}}$ in seconds):
| Game / Domain | `easy` | `medium` | `hard` |
| :--- | :---: | :---: | :---: |
| `memory` | 25.0s | 35.0s | 50.0s |
| `attention` | 15.0s | 25.0s | 40.0s |
| `recall` | 20.0s | 30.0s | 45.0s |
| `sequence_memory` | 25.0s | 40.0s | 60.0s |
| *Fallback* | 25.0s | 35.0s | 50.0s |

---

## 3. Difficulty State Machine & Safety Invariants

### State Transitions
- **Promotion Threshold**: $\text{Effective Score} \ge 75.0$
- **Demotion Threshold**: $\text{Effective Score} < 50.0$
- **Maintenance Range**: $50.0 \le \text{Effective Score} < 75.0$

```
          [ Score >= 75.0 ]              [ Score >= 75.0 ]
   easy ────────────────────► medium ────────────────────► hard
     ▲                         │  ▲                         │
     │                         │  │                         │
     └─────────────────────────┘  └─────────────────────────┘
            [ Score < 50.0 ]               [ Score < 50.0 ]
```

### Safety Guarantees:
1. **No direct `easy` $\to$ `hard` jump**: Even with a 100% score, `easy` difficulty only promotes to `medium`.
2. **No direct `hard` $\to$ `easy` drop**: Even with a 0 score, `hard` difficulty only demotes to `medium`.
3. **Outlier Mitigation (Moving Average)**:
   $$\text{Effective Score} = 0.50 \times \text{Current Score} + 0.50 \times \text{Average}(\text{Recent Past Sessions})$$
   Buffers single-session anomalies (lucky guesses or accidental disruptions) from destabilizing user experience.

---

## 4. Recommendation Logic & Cold-Start Rotation

### Cognitive Domains:
1. `memory` (card match, pattern memory, spatial grids)
2. `attention` (reaction time, Stroop tasks, focus tests)
3. `recall` (delayed recall, word lists, object retrieval)
4. `sequence_memory` (number spans, Simon patterns)

### Decision Logic:
1. **Weaker Domain Remediation**: If history indicates a cognitive domain with an average score $< 70.0$ (lower than current performance), targeted remediation for that domain is prioritized.
2. **High-Performance Progression ($\ge 75.0$)**: Promotes to an advanced complementary domain (`memory` $\to$ `sequence_memory` $\to$ `recall` $\to$ `attention`).
3. **Low-Performance Foundation ($< 50.0$)**: Recommends foundational reinforcement (`sequence_memory` $\to$ `memory`, `memory` $\to$ `attention`).
4. **Cold-Start Rotation (Moderate Performance, No History)**: Deterministically rotates across unplayed domains (`get_rotated_untested_area`) so new users experience diverse cognitive challenges rather than repeatedly being routed to the same activity.

---

## 5. Input Validation & Exception Handling

- **`validate_history(history)`**: Raises `TypeError` if `history` is provided and is not a `list`.
- **`validate_game_result(game_result)`**:
  - Rejects non-dict inputs with `TypeError`.
  - Rejects missing required keys (`game`, `score`, `accuracy`, `duration`, `difficulty`).
  - Rejects boolean types passed as numeric fields.
  - Rejects out-of-bounds `accuracy` ($< 0$ or $> 100$).
  - Rejects negative `score` ($< 0$).
  - Rejects non-positive `duration` ($\le 0$).
  - Rejects non-positive `max_score` ($\le 0$) if provided.
  - Rejects invalid `difficulty` strings outside `{"easy", "medium", "hard"}`.

---

## 6. Integration Contract for Member 5 (FastAPI)

```python
from ai.adaptive.adaptive_engine import analyze_performance

# Call without history
result = analyze_performance({
    "game": "memory",
    "score": 85,
    "accuracy": 90,
    "duration": 42,
    "difficulty": "medium",
    "attempts": 8
})

# Call with custom max_score and history list
result_custom = analyze_performance(
    game_result={
        "game": "memory",
        "score": 450,
        "max_score": 500,
        "accuracy": 90,
        "duration": 42,
        "difficulty": "medium"
    },
    history=user_past_games_list
)
```

---

## 7. Verification & Testing

Unit tests in `ai/adaptive/test_adaptive.py` verify:
- Accurate score calculations for low, medium, and high performance.
- Monotonic speed scoring based on actual vs. benchmark duration.
- Score normalization across standard ($100.0$) and custom `max_score` values.
- Rejection of invalid inputs (`max_score <= 0`, negative duration, non-list history).
- Safety bounds preserving gradual difficulty transitions.
- Moving average dampening of lucky or distracted outlier games.
- Deterministic cold-start recommendation rotation.
- Complete JSON serializability of all output fields.
