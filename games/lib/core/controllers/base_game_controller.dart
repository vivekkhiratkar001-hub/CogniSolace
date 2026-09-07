import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/game_difficulty.dart';
import '../models/game_result.dart';
import '../constants/game_constants.dart';

/// Base state machine for all CogniSolace cognitive activities.
/// Handles timing, non-punitive scoring, telemetry capture, and inactivity hints.
abstract class BaseGameController extends ChangeNotifier {
  final String patientId;
  final String gameId;
  final String gameMode;
  final GameDifficulty difficulty;
  final bool enableInactivityHint;

  late final String sessionId;
  late final DateTime _startTime;
  DateTime? _firstInteractionTime;
  Timer? _inactivityTimer;

  int _attempts = 0;
  int _hintsUsed = 0;
  int _score = 0;
  int _correctFirstAttempts = 0;
  bool _isCompleted = false;
  bool _showHint = false;

  BaseGameController({
    required this.patientId,
    required this.gameId,
    required this.gameMode,
    this.difficulty = GameDifficulty.easy,
    this.enableInactivityHint = true,
  }) {
    sessionId = '${gameId}_${DateTime.now().millisecondsSinceEpoch}';
    _startTime = DateTime.now();
    _resetInactivityTimer();
  }

  // Getters
  int get attempts => _attempts;
  int get hintsUsed => _hintsUsed;
  int get score => _score;
  bool get isCompleted => _isCompleted;
  bool get showHint => _showHint;
  DateTime get startTime => _startTime;
  Duration get sessionDuration => DateTime.now().difference(_startTime);

  /// Call whenever the patient interacts with the screen
  void recordInteraction() {
    _firstInteractionTime ??= DateTime.now();
    _attempts++;
    _showHint = false;
    _resetInactivityTimer();
    notifyListeners();
  }

  /// Triggered if an item was successfully identified on first try
  void recordFirstAttemptSuccess() {
    _correctFirstAttempts++;
  }

  /// Gentle hint trigger
  void triggerHint() {
    _hintsUsed++;
    _showHint = true;
    notifyListeners();
  }

  /// Add positive reinforcement score
  void addScore(int points) {
    _score += points;
    notifyListeners();
  }

  /// Completes the session and packages the clinical telemetry
  GameResult finishSession({Map<String, dynamic> extraMetadata = const {}}) {
    _isCompleted = true;
    _inactivityTimer?.cancel();

    final now = DateTime.now();
    final durationMs = now.difference(_startTime).inMilliseconds;
    final reactionTimeMs = _firstInteractionTime != null
        ? _firstInteractionTime!.difference(_startTime).inMilliseconds
        : durationMs;

    // Calculate accuracy (capped between 0.0 and 1.0)
    final double accuracy = _attempts > 0
        ? (_correctFirstAttempts / _attempts).clamp(0.0, 1.0)
        : 1.0;

    notifyListeners();

    return GameResult(
      sessionId: sessionId,
      patientId: patientId,
      gameId: gameId,
      gameMode: gameMode,
      difficulty: difficulty,
      score: _score,
      accuracy: double.parse(accuracy.toStringAsFixed(2)),
      attempts: _attempts,
      hintsUsed: _hintsUsed,
      durationMs: durationMs,
      reactionTimeMs: reactionTimeMs,
      completedAt: now,
      metadata: {
        'correct_first_attempts': _correctFirstAttempts,
        ...extraMetadata,
      },
    );
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    if (!enableInactivityHint) return;
    _inactivityTimer = Timer(DementiaUX.hintInactivityTimeout, () {
      if (!_isCompleted) {
        triggerHint();
      }
    });
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }
}
