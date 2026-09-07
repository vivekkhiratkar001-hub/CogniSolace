/// Difficulty levels configured by the external Adaptive Engine or selected manually.
enum GameDifficulty {
  easy,
  medium,
  hard;

  String get displayName {
    switch (this) {
      case GameDifficulty.easy:
        return 'Easy';
      case GameDifficulty.medium:
        return 'Medium';
      case GameDifficulty.hard:
        return 'Hard';
    }
  }

  String get description {
    switch (this) {
      case GameDifficulty.easy:
        return 'Simple choices with helpful automatic hints';
      case GameDifficulty.medium:
        return 'Balanced items with subtle guidance';
      case GameDifficulty.hard:
        return 'More items to remember and distinguish';
    }
  }

  static GameDifficulty fromString(String? value) {
    if (value == null) return GameDifficulty.easy;
    return GameDifficulty.values.firstWhere(
      (d) => d.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GameDifficulty.easy,
    );
  }
}
