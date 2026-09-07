import 'game_difficulty.dart';

/// Configuration for a cognitive game session.
/// Designed for single-line plug-and-play configuration by Member 3 (Adaptive Learning Engine)
/// or testing harnesses.
class GameSessionConfig {
  final int questionCount;
  final GameDifficulty difficulty;
  final String? gameMode;
  final String? category;
  final Map<String, dynamic> customSettings;

  const GameSessionConfig({
    this.questionCount = 10,
    this.difficulty = GameDifficulty.easy,
    this.gameMode,
    this.category,
    this.customSettings = const {},
  });

  GameSessionConfig copyWith({
    int? questionCount,
    GameDifficulty? difficulty,
    String? gameMode,
    String? category,
    Map<String, dynamic>? customSettings,
  }) {
    return GameSessionConfig(
      questionCount: questionCount ?? this.questionCount,
      difficulty: difficulty ?? this.difficulty,
      gameMode: gameMode ?? this.gameMode,
      category: category ?? this.category,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  Map<String, dynamic> toJson() => {
        'question_count': questionCount,
        'difficulty': difficulty.name,
        if (gameMode != null) 'game_mode': gameMode,
        if (category != null) 'category': category,
        'custom_settings': customSettings,
      };
}
