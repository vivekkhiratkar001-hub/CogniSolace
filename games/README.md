# CogniSolace — Cognitive Games Module

**Developer**: Member 2 (Cognitive Games Lead)  
**Target Group**: Elderly Dementia & Alzheimer's Patients in the North Eastern Region (NER)  
**Core Framework**: Flutter (Pure Dart / Material 3, Dementia Accessibility First, No Heavy Game Engine Dependencies)

---

## Overview

The Cognitive Games module is a clinically guided, culturally familiar, and dementia-accessible activity suite designed for elderly patients in the North Eastern Region (Assam, Meghalaya, Manipur, etc.).

It is strictly decoupled into 5 architectural layers:
1. **Game Logic & State Machines**: Pure Flutter/Dart controllers with zero countdown timers, errorless guidance, and automatic inactivity hints.
2. **Game Content Abstraction**: Abstract `GameItem` and `GameScenario` structures.
3. **Personalized & Regional Content**: 3-tier fallback (`Caregiver Family Photos` -> `NER Regional Packs` -> `Generic Familiar Home Pack`).
4. **Adaptive Engine Bridge**: Contract for Member 3's Adaptive Learning Engine, with an offline rule-based heuristic fallback.
5. **Backend Sync Bridge**: Contract for Member 5's FastAPI + SQLite backend, featuring an offline-first buffering queue.

---

## MVP Game Suite

| Game | Cognitive Target | Dementia-Friendly Mechanic | Personalization / Cultural Hook |
| :--- | :--- | :--- | :--- |
| **1. Know My People** | Facial Recognition & Associative Memory | 1 large portrait with 2–3 large relation buttons. Wrong choices softly dim; correct choice pulses warm amber. | Caregiver-uploaded family photos, names, and greetings. |
| **2. Daily Market** | Working Memory & Selective Attention | Remember 1–2 items, then tap them in the local market stall with distractors. | Regional NER items (Assam tea, Gamosa, Khasi oranges, cane baskets). |
| **3. My Day** | Temporal Sequencing & Executive Function | Tap-to-order daily routine steps into chronological numbered slots. | Familiar daily routines (morning red tea, prayer diya, market stroll). |

---

## Integration for Teammates

### For Member 1 (Main Flutter App):
Add the games module to your `pubspec.yaml`:
```yaml
dependencies:
  cognisolace_games:
    path: ../games
```

Launch the entire game suite anywhere in your app:
```dart
import 'package:cognisolace_games/games.dart';

// In your navigation or screen:
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => const CognitiveGamesCatalog(
      patientId: 'patient_123',
      initialRegion: 'assam',
    ),
  ),
);
```

### For Member 3 (Adaptive Learning Engine):
Implement the `AdaptiveEngineBridge`:
```dart
class MyAdaptiveAI implements AdaptiveEngineBridge {
  @override
  Future<GameDifficulty> getRecommendedDifficulty({required String patientId, required String gameId}) async {
    // Return GameDifficulty.easy, medium, or hard
  }

  @override
  Future<void> submitTelemetry(GameResult result) async {
    // Process clinical metrics
  }
}
```

### For Member 5 (FastAPI + SQLite Backend):
The module produces standardized `GameResult` JSON payloads:
```json
{
  "session_id": "daily_market_1693892019",
  "patient_id": "patient_123",
  "game": "daily_market",
  "difficulty": "easy",
  "score": 100,
  "accuracy": 1.0,
  "attempts": 2,
  "hints_used": 0,
  "duration_ms": 14200,
  "reaction_time_ms": 2800,
  "completed_at": "2026-09-06T14:10:00.000Z",
  "metadata": {}
}
```
Post endpoint: `POST /api/v1/games/results`
Caregiver content endpoint: `GET /api/v1/patients/{id}/profile`

---

## Dementia Accessibility (WCAG & Clinical Principles)
- **Minimum Touch Target**: 60dp $\times$ 60dp to accommodate tremors and motor decline.
- **Errorless Learning**: No red "X" icons, buzzer sound effects, or "Game Over" states.
- **Zero Countdown Timers**: Pressure-free interaction; duration is monitored silently in the background for clinical telemetry.
- **Inactivity Guidance**: Automatic soft visual glow and audio cue after 12 seconds of inactivity.
