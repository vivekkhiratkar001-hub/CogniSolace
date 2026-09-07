import '../../../core/controllers/base_game_controller.dart';
import '../../../core/models/game_difficulty.dart';
import '../../../core/models/game_item.dart';
import '../../../core/models/game_result.dart';
import '../../../core/models/game_scenario.dart';
import '../../../core/models/game_session_config.dart';
import '../../../core/models/round_data.dart';

class _DailyMarketRound {
  final List<GameItem> targetItems;
  final List<GameItem> marketStall;
  final String promptText;

  const _DailyMarketRound({
    required this.targetItems,
    required this.marketStall,
    required this.promptText,
  });
}

class DailyMarketController extends BaseGameController {
  final GameScenario scenario;
  final GameSessionConfig sessionConfig;
  final Function(GameResult result)? onSessionComplete;

  late final List<_DailyMarketRound> _rounds;
  int _currentRoundIndex = 0;

  final Set<String> _collectedItemIds = {};
  final Set<String> _dimmedDistractorIds = {};
  bool _isRoundSuccess = false;
  bool _isSessionComplete = false;

  late DateTime _roundStartTime;
  DateTime? _roundFirstInteractionTime;
  int _roundAttempts = 0;
  int _totalAttempts = 0;
  int _correctFirstAttempts = 0;
  final List<RoundData> _roundsHistory = [];

  DailyMarketController({
    required super.patientId,
    required this.scenario,
    super.difficulty = GameDifficulty.easy,
    GameSessionConfig? sessionConfig,
    this.onSessionComplete,
  })  : sessionConfig = sessionConfig ?? GameSessionConfig(difficulty: difficulty, questionCount: 5),
        super(
          gameId: 'daily_market',
          gameMode: 'working_memory_shopping',
          enableInactivityHint: false,
        ) {
    _generateRounds();
    _roundStartTime = DateTime.now();
  }

  void _generateRounds() {
    _rounds = [];
    final pool = List<GameItem>.from(scenario.allItems);
    if (pool.length < 5) {
      const fallbackItems = [
        GameItem(id: 'as_tea', title: 'Chah (Assam Tea)', subtitle: 'Fresh tea leaves', category: 'beverage'),
        GameItem(id: 'as_gamosa', title: 'Gamosa', subtitle: 'Woven towel', category: 'craft'),
        GameItem(id: 'as_pitha', title: 'Til Pitha', subtitle: 'Crisp rice rolls', category: 'snack'),
        GameItem(id: 'as_nemu', title: 'Kaji Nemu (Lemon)', subtitle: 'Aromatic lemon', category: 'fruit'),
        GameItem(id: 'as_dhekia', title: 'Dhekia Xak', subtitle: 'Fiddlehead ferns', category: 'vegetable'),
      ];
      for (final fb in fallbackItems) {
        if (!pool.any((item) => item.id == fb.id || item.title == fb.title)) {
          pool.add(fb);
        }
      }
    }

    final int targetCount = difficulty == GameDifficulty.easy
        ? 1
        : (difficulty == GameDifficulty.medium ? 2 : 3);
    final int distractorCount = difficulty == GameDifficulty.easy
        ? 2
        : (difficulty == GameDifficulty.medium ? 2 : 3);
    final int totalRounds = sessionConfig.questionCount;

    for (int i = 0; i < totalRounds; i++) {
      if (i == 0) {
        // Round 0: 100% backward compatible with scenario & existing tests
        _rounds.add(_DailyMarketRound(
          targetItems: scenario.targets,
          marketStall: scenario.allItems,
          promptText: scenario.promptText,
        ));
      } else {
        // Subsequent rounds: rotate target items and distractors
        final targets = <GameItem>[];
        for (int t = 0; t < targetCount; t++) {
          targets.add(pool[(i * 2 + t) % pool.length]);
        }

        final otherItems = pool.where((p) => !targets.any((t) => t.id == p.id)).toList();
        final distractors = <GameItem>[];
        for (int d = 0; d < distractorCount && d < otherItems.length; d++) {
          distractors.add(otherItems[(i + d) % otherItems.length]);
        }

        final stall = [...targets, ...distractors]..shuffle();
        final prompt = 'Please find ${targets.map((t) => t.title).join(' and ')} in the market stall.';

        _rounds.add(_DailyMarketRound(
          targetItems: targets,
          marketStall: stall,
          promptText: prompt,
        ));
      }
    }
  }

  // Getters
  int get currentRoundIndex => _currentRoundIndex;
  int get currentRoundNumber => _currentRoundIndex + 1;
  int get totalRounds => sessionConfig.questionCount;

  _DailyMarketRound get _currentRound => _rounds[_currentRoundIndex];
  List<GameItem> get targetItems => _currentRound.targetItems;
  List<GameItem> get marketStall => _currentRound.marketStall;
  String get promptText => _currentRound.promptText;

  Set<String> get collectedItemIds => _collectedItemIds;
  Set<String> get dimmedDistractorIds => _dimmedDistractorIds;
  bool get isRoundSuccess => _isRoundSuccess;
  bool get isSuccess => _isRoundSuccess; // Backward compatibility with existing tests
  bool get isSessionComplete => _isSessionComplete;

  int get remainingTargetsCount => targetItems.length - _collectedItemIds.length;
  int get totalAttemptsCount => _totalAttempts;
  int get correctFirstAttemptsCount => _correctFirstAttempts;
  double get sessionAccuracy =>
      totalRounds > 0 ? (_correctFirstAttempts / totalRounds) : 0.0;
  List<RoundData> get roundsHistory => List.unmodifiable(_roundsHistory);

  bool isTarget(String itemId) => targetItems.any((t) => t.id == itemId);

  void tapMarketItem(GameItem item) {
    if (_isRoundSuccess ||
        _isSessionComplete ||
        _collectedItemIds.contains(item.id) ||
        _dimmedDistractorIds.contains(item.id)) {
      return;
    }

    _roundFirstInteractionTime ??= DateTime.now();
    _roundAttempts++;
    _totalAttempts++;
    recordInteraction();

    if (isTarget(item.id)) {
      _collectedItemIds.add(item.id);

      if (_roundAttempts <= targetItems.length) {
        addScore(50);
      } else {
        addScore(30);
      }

      // Check if all targets collected for this round
      if (_collectedItemIds.length == targetItems.length) {
        final bool isFirstAttempt = (_roundAttempts == targetItems.length);
        if (isFirstAttempt) {
          _correctFirstAttempts++;
          recordFirstAttemptSuccess();
        }

        final now = DateTime.now();
        final durationMs = now.difference(_roundStartTime).inMilliseconds;
        final reactionTimeMs = _roundFirstInteractionTime != null
            ? _roundFirstInteractionTime!.difference(_roundStartTime).inMilliseconds
            : durationMs;

        _roundsHistory.add(RoundData(
          roundIndex: currentRoundNumber,
          questionId: targetItems.map((t) => t.id).join(','),
          questionTitle: targetItems.map((t) => t.title).join(', '),
          roundType: 'working_memory_shopping',
          difficulty: difficulty,
          isFirstAttemptCorrect: isFirstAttempt,
          isSolved: true,
          attempts: _roundAttempts,
          hintUsed: false,
          reactionTimeMs: reactionTimeMs,
          durationMs: durationMs,
        ));

        _isRoundSuccess = true;
        notifyListeners();
        return;
      }

      notifyListeners();
    } else {
      // Distractor tapped: gentle errorless learning
      _dimmedDistractorIds.add(item.id);
      triggerHint();
      notifyListeners();
    }
  }

  /// Advances to the next round in the session, or triggers the final summary screen
  void nextRound() {
    if (!_isRoundSuccess || _isSessionComplete) return;

    if (currentRoundNumber < totalRounds) {
      _currentRoundIndex++;
      _collectedItemIds.clear();
      _dimmedDistractorIds.clear();
      _isRoundSuccess = false;
      _roundAttempts = 0;
      _roundStartTime = DateTime.now();
      _roundFirstInteractionTime = null;
      notifyListeners();
    } else {
      _isSessionComplete = true;
      final result = finishSession(extraMetadata: {
        'question_count': totalRounds,
        'correct_first_attempts': _correctFirstAttempts,
        'rounds': _roundsHistory.map((r) => r.toJson()).toList(),
      });

      if (onSessionComplete != null) {
        onSessionComplete!(result);
      }
      notifyListeners();
    }
  }
}
