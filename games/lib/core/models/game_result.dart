import 'game_difficulty.dart';

/// Standardized telemetry and assessment result for all CogniSolace cognitive games.
/// Designed for serialization to FastAPI + SQLite backend (Member 5)
/// and ingestion by the Adaptive Learning Engine (Member 3).
class GameResult {
  final String sessionId;
  final String patientId;
  final String gameId;
  final String gameMode;
  final GameDifficulty difficulty;
  final int score;
  final double accuracy;          // 0.0 to 1.0 (correct first choices / total choices)
  final int attempts;            // Total interactions made to complete the session
  final int hintsUsed;           // Count of audio/visual hints triggered
  final int durationMs;          // Total session duration in milliseconds
  final int reactionTimeMs;      // Time to first meaningful touch interaction
  final DateTime completedAt;
  final Map<String, dynamic> metadata;

  const GameResult({
    required this.sessionId,
    required this.patientId,
    required this.gameId,
    required this.gameMode,
    required this.difficulty,
    required this.score,
    required this.accuracy,
    required this.attempts,
    required this.hintsUsed,
    required this.durationMs,
    required this.reactionTimeMs,
    required this.completedAt,
    this.metadata = const {},
  });

  /// Serializes to JSON adhering to FastAPI schema
  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'patient_id': patientId,
      'game': gameId,
      'game_id': gameId,
      'game_mode': gameMode,
      'difficulty': difficulty.name,
      'score': score,
      'accuracy': accuracy,
      'attempts': attempts,
      'hints_used': hintsUsed,
      'duration': durationMs ~/ 1000, // seconds for basic reporting
      'duration_ms': durationMs,
      'reaction_time_ms': reactionTimeMs,
      'completed_at': completedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Deserializes from JSON
  factory GameResult.fromJson(Map<String, dynamic> json) {
    return GameResult(
      sessionId: json['session_id'] as String? ?? '',
      patientId: json['patient_id'] as String? ?? 'anonymous_patient',
      gameId: (json['game_id'] ?? json['game']) as String? ?? 'unknown_game',
      gameMode: json['game_mode'] as String? ?? 'standard',
      difficulty: GameDifficulty.fromString(json['difficulty'] as String?),
      score: (json['score'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      attempts: (json['attempts'] as num?)?.toInt() ?? 1,
      hintsUsed: (json['hints_used'] as num?)?.toInt() ?? 0,
      durationMs: (json['duration_ms'] as num?)?.toInt() ??
          (((json['duration'] as num?)?.toInt() ?? 0) * 1000),
      reactionTimeMs: (json['reaction_time_ms'] as num?)?.toInt() ?? 0,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : DateTime.now(),
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }

  @override
  String toString() {
    return 'GameResult($gameId, score: $score, acc: ${(accuracy * 100).toStringAsFixed(1)}%, diff: ${difficulty.name}, duration: ${durationMs}ms)';
  }
}
