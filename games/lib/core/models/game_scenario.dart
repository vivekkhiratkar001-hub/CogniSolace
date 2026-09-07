import 'game_difficulty.dart';
import 'game_item.dart';

/// Defines a single round or trial of a cognitive activity.
class GameScenario {
  final String id;
  final String gameId;
  final GameDifficulty difficulty;
  final String promptText;
  final String? promptAudio;
  final List<GameItem> targets;          // Items the user should identify, remember, or place
  final List<GameItem> distractors;      // Non-target items to test selective attention
  final List<String>? orderedTargetIds;  // Target sequence for ordering games (e.g. My Day)
  final String? hintText;
  final String? hintAudio;

  const GameScenario({
    required this.id,
    required this.gameId,
    required this.difficulty,
    required this.promptText,
    this.promptAudio,
    required this.targets,
    this.distractors = const [],
    this.orderedTargetIds,
    this.hintText,
    this.hintAudio,
  });

  /// All options presented together, typically shuffled for display
  List<GameItem> get allItems {
    final combined = List<GameItem>.from(targets)..addAll(distractors);
    combined.shuffle();
    return combined;
  }
}
