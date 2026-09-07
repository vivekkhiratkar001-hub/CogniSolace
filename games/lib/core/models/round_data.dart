import 'game_difficulty.dart';

/// Clinical interaction data captured for a single round within a multi-round game session.
/// Feeds into the Adaptive Learning Engine (Member 3) and Offline Buffer Sync (Member 5).
class RoundData {
  final int roundIndex;
  final String questionPersonId;
  final String questionPersonName;
  final String questionId;
  final String questionTitle;
  final String? roundType;
  final GameDifficulty difficulty;
  final bool isFirstAttemptCorrect;
  final bool isSolved;
  final int attempts;
  final bool hintUsed;
  final int reactionTimeMs;
  final int durationMs;
  final DateTime timestamp;

  RoundData({
    required this.roundIndex,
    this.questionPersonId = '',
    this.questionPersonName = '',
    String? questionId,
    String? questionTitle,
    this.roundType,
    required this.difficulty,
    required this.isFirstAttemptCorrect,
    required this.isSolved,
    required this.attempts,
    this.hintUsed = false,
    required this.reactionTimeMs,
    required this.durationMs,
    DateTime? timestamp,
  })  : questionId = questionId ?? questionPersonId,
        questionTitle = questionTitle ?? questionPersonName,
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'round_index': roundIndex,
        'question_id': questionId.isNotEmpty ? questionId : questionPersonId,
        'question_person_id': questionPersonId.isNotEmpty ? questionPersonId : questionId,
        'question_title': questionTitle.isNotEmpty ? questionTitle : questionPersonName,
        'question_person_name': questionPersonName.isNotEmpty ? questionPersonName : questionTitle,
        if (roundType != null) 'round_type': roundType,
        'difficulty': difficulty.name,
        'is_first_attempt_correct': isFirstAttemptCorrect,
        'is_solved': isSolved,
        'attempts': attempts,
        'hint_used': hintUsed,
        'reaction_time_ms': reactionTimeMs,
        'duration_ms': durationMs,
        'timestamp': timestamp.toIso8601String(),
      };

  factory RoundData.fromJson(Map<String, dynamic> json) {
    final qId = json['question_id'] as String? ?? json['question_person_id'] as String? ?? '';
    final qTitle = json['question_title'] as String? ?? json['question_person_name'] as String? ?? '';

    return RoundData(
      roundIndex: json['round_index'] as int? ?? 1,
      questionPersonId: qId,
      questionPersonName: qTitle,
      questionId: qId,
      questionTitle: qTitle,
      roundType: json['round_type'] as String?,
      difficulty: GameDifficulty.fromString(json['difficulty'] as String?),
      isFirstAttemptCorrect: json['is_first_attempt_correct'] as bool? ?? false,
      isSolved: json['is_solved'] as bool? ?? true,
      attempts: json['attempts'] as int? ?? 1,
      hintUsed: json['hint_used'] as bool? ?? false,
      reactionTimeMs: json['reaction_time_ms'] as int? ?? 0,
      durationMs: json['duration_ms'] as int? ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
