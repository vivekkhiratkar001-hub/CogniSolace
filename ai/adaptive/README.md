# CogniSolace - Explainable Adaptive Learning Engine

> **Module**: `ai/adaptive/`  
> **Author**: Member 3 (Adaptive Learning / ML)  
> **Target Audience**: CogniSolace Hackathon Team (specifically Member 5 for Backend Integration)

---

## 1. Overview & Files Created

This module provides a lightweight, explainable, and production-ready adaptive learning engine for CogniSolace. It evaluates cognitive game performance in real time, calculates normalized composite scores, manages gradual difficulty progression, and recommends targeted cognitive exercises to address weaker areas.

### Files Created:
1. [`adaptive_engine.py`](file:///c:/Users/vivek/OneDrive/Desktop/CogniSolace/ai/adaptive/adaptive_engine.py): Core adaptive algorithm, input validation, speed calculation, composite scoring, moving average smoothing, difficulty state transitions, and explainable rationale generator.
2. [`recommendation.py`](file:///c:/Users/vivek/OneDrive/Desktop/CogniSolace/ai/adaptive/recommendation.py): Cognitive profile tracking, game-to-domain mapping, weaker domain detection, and next-activity recommendation.
3. [`test_adaptive.py`](file:///c:/Users/vivek/OneDrive/Desktop/CogniSolace/ai/adaptive/test_adaptive.py): Comprehensive unit test suite (24 tests) validating scoring, state transitions, validation errors, history smoothing, and JSON serialization.
4. [`README.md`](file:///c:/Users/vivek/OneDrive/Desktop/CogniSolace/ai/adaptive/README.md): Architecture documentation, mathematical formulations, and Member 5 integration guide.

---

## 2. Algorithmic Architecture

The engine is built on explainable mathematical heuristics—strictly avoiding heavy dependencies like TensorFlow or PyTorch—making it lightweight, deterministic, and ideal for hackathon evaluation and deployment.

### System Pipeline:
```
[Game Result JSON + History]
           │
           ▼
   Input Validation (Bounds, Types, Required Fields)
           │
           ▼
   Speed Score Calculation (Benchmarked vs Expected Durations)
           │
           ▼
   Composite Performance Score (60% Accuracy + 25% Speed + 15% Score)
           │
           ▼
   Moving Average Smoothing (Prevents Outlier-Induced Difficulty Jumps)
           │
           ▼
   Gradual Difficulty State Machine (easy <-> medium <-> hard)
           │
           ▼
   Cognitive Domain Profiling & Activity Recommendation (Targeting Weak Areas)
           │
           ▼
[JSON-Serializable Response + Explainable Rationale]
```

---

## 3. Mathematical Formulations

### Composite Performance Formula:
$$\text{Performance Score} = 0.60 \times \text{Accuracy} + 0.25 \times \text{Speed Score} + 0.15 \times \text{Normalized Score}$$

- **Accuracy Weight (60%)**: Accuracy is the primary indicator of cognitive retention and precision ($0 \le \text{Accuracy} \le 100$).
- **Speed Weight (25%)**: Speed reflects cognitive processing efficiency and fluency ($0 \le \text{Speed Score} \le 100$).
- **Score Weight (15%)**: Normalized in-game score capturing achievements and bonus points, scaled via:
  $$\text{Normalized Score} = \text{clamp}\left(\frac{\text{score}}{\text{max\_score}} \times 100.0, \; 0.0, \; 100.0\right)$$
  *(Defaults to $\text{max\_score} = 100.0$ if omitted).*
- **Composite Normalization**: Clamped strictly between $0.0$ and $100.0$, rounded to 1 decimal place.

---

## 4. Speed Calculation & Benchmarking

Speed is calculated by comparing the player's actual duration against an expected completion duration benchmark ($T_{\text{expected}}$) calibrated for each game and difficulty:

$$\text{Speed Score} = \text{clamp}\left(\frac{T_{\text{expected}}}{T_{\text{actual}}} \times 75.0, \; 0.0, \; 100.0\right)$$

- **Meeting Expected Duration ($T_{\text{actual}} = T_{\text{expected}}$)**: Yields a solid benchmark score of **75.0**.
- **Faster Completion ($T_{\text{actual}} < T_{\text{expected}}$)**: Scales up smoothly to **100.0**.
- **Slower Completion ($T_{\text{actual}} > T_{\text{expected}}$)**: Scales down smoothly toward **0.0**.

### Expected Duration Table (Seconds):
| Game / Domain | Easy | Medium | Hard |
| :--- | :---: | :---: | :---: |
| `memory` | 25s | 35s | 50s |
| `attention` | 15s | 25s | 40s |
| `recall` | 20s | 30s | 45s |
| `sequence_memory` | 25s | 40s | 60s |
| *Default / Unrecognized* | 25s | 35s | 50s |

*Example*: For `memory` on `medium` ($T_{\text{expected}} = 35\text{s}$) completed in $42\text{s}$:
$$\text{Speed Score} = \frac{35}{42} \times 75.0 = 62.5$$

---

## 5. Difficulty Progression Rules & State Machine

Difficulty transitions follow strict safety and gradual progression criteria:

| Current Difficulty | Effective Score | Next Difficulty | Action Taken |
| :---: | :---: | :---: | :--- |
| **`easy`** | $\ge 75.0$ | **`medium`** | Promoted |
| **`easy`** | $< 75.0$ | **`easy`** | Maintained (*Cannot jump directly to hard*) |
| **`medium`** | $\ge 75.0$ | **`hard`** | Promoted |
| **`medium`** | $< 50.0$ | **`easy`** | Demoted |
| **`medium`** | $50.0 \le \text{Score} < 75.0$ | **`medium`** | Maintained |
| **`hard`** | $< 50.0$ | **`medium`** | Demoted (*Cannot jump directly to easy*) |
| **`hard`** | $\ge 50.0$ | **`hard`** | Maintained |

### Outlier Smoothing (Moving Average):
To ensure that a single unusually lucky or distracted game does not trigger a jarring difficulty jump:
$$\text{Effective Score} = 0.50 \times \text{Current Score} + 0.50 \times \text{Average}(\text{Past Sessions})$$
- If past history shows consistent scores of $\sim 40$ and one lucky game scores $90$, the smoothed effective score remains $\sim 65$, preventing premature promotion to `hard`.
- If past history shows consistent scores of $\sim 85$ and a single accidental drop scores $35$, the smoothed effective score remains $\sim 60$, preventing premature demotion to `easy`.

---

## 6. Cognitive Domain Recommendation Logic

The engine categorizes games into four primary cognitive domains:
1. **`memory`**: Visual matching, spatial recall, card pairs.
2. **`attention`**: Focus, reaction time, Stroop tasks.
3. **`recall`**: Delayed recall, verbal/word memory, object retrieval.
4. **`sequence_memory`**: Pattern sequence, digit spans, Simon-style tasks.

### Decision Hierarchy:
1. **Weak Domain Remediation**: If historical data shows an area with an average score lower than the others ($< 70.0$), that area is targeted for remediation.
2. **High-Performance Progression**: When a user masters the current domain ($\ge 75.0$), the engine recommends progressing to advanced complementary domains (e.g. `memory` $\to$ `sequence_memory`).
3. **Low-Performance Foundation**: When a user struggles ($< 50.0$), the engine recommends foundational reinforcement (e.g. `sequence_memory` $\to$ `memory`, or `memory` $\to$ `attention`).
4. **Balanced Routine**: If scores are moderate, untested cognitive domains are introduced to promote holistic cognitive stimulation.

---

## 7. Sample Input and Output

### Input Payload (`game_result`):
```json
{
    "game": "memory",
    "score": 85,
    "accuracy": 90,
    "attempts": 8,
    "duration": 42,
    "difficulty": "medium"
}
```

### Output Response:
```json
{
    "performance_score": 82.4,
    "next_difficulty": "hard",
    "recommended_activity": "sequence_memory",
    "confidence": 0.87,
    "reason": "High accuracy and good response speed indicate that the user can progress to a harder activity."
}
```

---

## 8. Integration Guide for Member 5 (FastAPI Backend)

Member 5 can integrate this module directly into the FastAPI backend with minimal boilerplate.

### Calling the Engine:
```python
from ai.adaptive.adaptive_engine import analyze_performance

# Direct call with single game result
result = analyze_performance(game_result)

# Call with optional user history
result_with_history = analyze_performance(game_result, history=user_history_list)
```

### Example FastAPI Route:
```python
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import List, Optional
from ai.adaptive.adaptive_engine import analyze_performance

router = APIRouter(prefix="/api/adaptive", tags=["Adaptive Learning"])

class GameResultSchema(BaseModel):
    game: str = Field(..., example="memory")
    score: float = Field(..., ge=0, example=85.0)
    accuracy: float = Field(..., ge=0, le=100, example=90.0)
    duration: float = Field(..., gt=0, example=42.0)
    difficulty: str = Field(..., example="medium")
    attempts: Optional[int] = Field(default=1, ge=1)

class AdaptiveAnalysisRequest(BaseModel):
    game_result: GameResultSchema
    history: Optional[List[dict]] = None

@router.post("/analyze")
def evaluate_game(payload: AdaptiveAnalysisRequest):
    try:
        recommendation = analyze_performance(
            game_result=payload.game_result.dict(),
            history=payload.history
        )
        return recommendation
    except (ValueError, TypeError) as exc:
        raise HTTPException(status_code=400, detail=str(exc))
```

---

## 9. Running Unit Tests

The test suite requires zero external dependencies and runs with Python's built-in `unittest`:

```powershell
# From the project root:
python -m unittest ai/adaptive/test_adaptive.py -v
```

### Test Coverage (24 Tests):
- **High / Medium / Low Performance**: Verifies accurate score calculations and threshold categorization.
- **Exact Weightings**: Confirms $60\%$ Accuracy, $25\%$ Speed, $15\%$ Score.
- **Difficulty State Machine**: Tests `easy` $\to$ `medium`, `medium` $\to$ `hard`, `hard` $\to$ `medium`, and guarantees no direct `easy` $\leftrightarrow$ `hard` jumps.
- **Input Validation**: Tests missing fields, negative duration/score, out-of-range accuracy, and invalid difficulty levels.
- **History Smoothing**: Confirms that outlier games are buffered by the historical moving average.
- **Domain Recommendation**: Confirms weaker domain targeting and high-score progression.
- **JSON Serialization**: Validates that all output fields are natively serializable.
