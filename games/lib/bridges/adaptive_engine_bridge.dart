import '../core/models/game_difficulty.dart';
import '../core/models/game_result.dart';

/// Integration bridge contract for Member 3 (Adaptive Learning Engine).
/// The Cognitive Games module emits telemetry and requests the next recommended difficulty.
abstract class AdaptiveEngineBridge {
  /// Queries the engine for the next recommended difficulty for a patient.
  Future<GameDifficulty> getRecommendedDifficulty({
    required String patientId,
    required String gameId,
  });

  /// Submits completed game telemetry for AI model updates.
  Future<void> submitTelemetry(GameResult result);
}

/// Standalone, offline-first rule-based adaptive controller.
/// Provides immediate smart difficulty scaling even before the neural model is connected.
class LocalRuleBasedAdaptiveEngine implements AdaptiveEngineBridge {
  final Map<String, List<GameResult>> _sessionHistory = {};

  @override
  Future<GameDifficulty> getRecommendedDifficulty({
    required String patientId,
    required String gameId,
  }) async {
    final key = '${patientId}_$gameId';
    final history = _sessionHistory[key];

    if (history == null || history.isEmpty) {
      return GameDifficulty.easy;
    }

    final recent = history.last;

    // Step down if struggling to prevent frustration
    if (recent.accuracy < 0.60 || recent.hintsUsed >= 2) {
      if (recent.difficulty == GameDifficulty.hard) return GameDifficulty.medium;
      return GameDifficulty.easy;
    }

    // Step up if performing with high mastery and confidence
    if (history.length >= 2) {
      final prev = history[history.length - 2];
      if (recent.accuracy >= 0.85 && prev.accuracy >= 0.85 && recent.hintsUsed == 0) {
        if (recent.difficulty == GameDifficulty.easy) return GameDifficulty.medium;
        return GameDifficulty.hard;
      }
    }

    return recent.difficulty;
  }

  @override
  Future<void> submitTelemetry(GameResult result) async {
    final key = '${result.patientId}_${result.gameId}';
    _sessionHistory.putIfAbsent(key, () => []).add(result);
  }

  /// Exposes session history for diagnostic export
  List<GameResult> getHistory(String patientId, String gameId) {
    return List.unmodifiable(_sessionHistory['${patientId}_$gameId'] ?? []);
  }
}
