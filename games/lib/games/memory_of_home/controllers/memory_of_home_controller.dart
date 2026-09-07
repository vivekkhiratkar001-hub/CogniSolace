import '../../../core/controllers/base_game_controller.dart';
import '../../../core/models/game_difficulty.dart';
import '../../../core/models/game_item.dart';
import '../../../core/models/game_result.dart';
import '../../../core/models/game_scenario.dart';
import '../../../core/models/game_session_config.dart';
import '../../../core/models/round_data.dart';

enum MemoryOfHomePhase {
  memorize,
  recall,
}

class _MemoryOfHomeRound {
  final List<GameItem> initialObjects;
  final GameItem missingItem;
  final List<GameItem> remainingObjects;
  final List<GameItem> choiceOptions;

  const _MemoryOfHomeRound({
    required this.initialObjects,
    required this.missingItem,
    required this.remainingObjects,
    required this.choiceOptions,
  });
}

class MemoryOfHomeController extends BaseGameController {
  final GameScenario scenario;
  final GameSessionConfig sessionConfig;
  final Function(GameResult result)? onSessionComplete;

  late final List<_MemoryOfHomeRound> _rounds;
  int _currentRoundIndex = 0;
  MemoryOfHomePhase _phase = MemoryOfHomePhase.memorize;
  final Set<String> _dimmedOptionIds = {};
  String? _retryFeedbackMessage;
  bool _isRoundSuccess = false;
  bool _isSessionComplete = false;

  late DateTime _roundStartTime;
  DateTime? _roundFirstInteractionTime;
  int _roundAttempts = 0;
  int _totalAttempts = 0;
  int _correctFirstAttempts = 0;
  final List<RoundData> _roundsHistory = [];

  MemoryOfHomeController({
    required super.patientId,
    required this.scenario,
    super.difficulty = GameDifficulty.easy,
    GameSessionConfig? sessionConfig,
    this.onSessionComplete,
  })  : sessionConfig = sessionConfig ?? GameSessionConfig(difficulty: difficulty, questionCount: 5),
        super(
          gameId: 'memory_of_home',
          gameMode: 'identify_missing_object',
          enableInactivityHint: false,
        ) {
    _generateRounds();
    _roundStartTime = DateTime.now();
  }

  void _generateRounds() {
    _rounds = [];
    final allPool = List<GameItem>.from(scenario.allItems);
    if (allPool.length < 5) {
      const fallbackItems = [
        GameItem(id: 'home_tea', title: 'Chah (Assam Tea)', subtitle: 'Tea cup', category: 'home'),
        GameItem(id: 'home_gamosa', title: 'Gamosa', subtitle: 'Woven towel', category: 'home'),
        GameItem(id: 'home_umbrella', title: 'Umbrella', subtitle: 'Rain umbrella', category: 'home'),
        GameItem(id: 'home_basket', title: 'Basket', subtitle: 'Cane basket', category: 'home'),
        GameItem(id: 'home_radio', title: 'Radio', subtitle: 'Classic radio', category: 'home'),
        GameItem(id: 'home_glasses', title: 'Glasses', subtitle: 'Reading glasses', category: 'home'),
      ];
      for (final fb in fallbackItems) {
        if (!allPool.any((item) => item.id == fb.id || item.title == fb.title)) {
          allPool.add(fb);
        }
      }
    }

    final int objectCount = difficulty == GameDifficulty.easy
        ? 3
        : (difficulty == GameDifficulty.medium ? 4 : 5);
    final int totalRounds = sessionConfig.questionCount;

    for (int i = 0; i < totalRounds; i++) {
      if (i == 0) {
        // Round 0: 100% backward compatible with initial scenario & tests
        final missingItem = scenario.targets.first;
        final allAvailable = {for (final item in scenario.allItems) item.id: item};
        List<GameItem> initialObjects;
        if (scenario.orderedTargetIds != null && scenario.orderedTargetIds!.isNotEmpty) {
          initialObjects = scenario.orderedTargetIds!
              .map((id) => allAvailable[id] ?? missingItem)
              .toList();
        } else {
          initialObjects = [missingItem, ...scenario.distractors.take(2)];
        }

        final remainingObjects = initialObjects.where((item) => item.id != missingItem.id).toList();
        final optionsSet = <String>{missingItem.id};
        final choices = <GameItem>[missingItem];
        if (remainingObjects.isNotEmpty && optionsSet.add(remainingObjects.first.id)) {
          choices.add(remainingObjects.first);
        }
        for (final item in scenario.distractors) {
          if (optionsSet.add(item.id)) {
            choices.add(item);
            if (choices.length >= (difficulty == GameDifficulty.easy ? 3 : 4)) break;
          }
        }
        choices.shuffle();
        _rounds.add(_MemoryOfHomeRound(
          initialObjects: initialObjects,
          missingItem: missingItem,
          remainingObjects: remainingObjects,
          choiceOptions: choices,
        ));
      } else {
        // Subsequent rounds: varied item selections
        final shifted = <GameItem>[];
        for (int j = 0; j < objectCount; j++) {
          shifted.add(allPool[(i * 2 + j) % allPool.length]);
        }
        final missingItem = shifted[i % shifted.length];
        final remainingObjects = shifted.where((item) => item.id != missingItem.id).toList();

        final optionsSet = <String>{missingItem.id};
        final choices = <GameItem>[missingItem];
        if (remainingObjects.isNotEmpty && optionsSet.add(remainingObjects.first.id)) {
          choices.add(remainingObjects.first);
        }
        for (final item in allPool) {
          if (!shifted.any((s) => s.id == item.id) && optionsSet.add(item.id)) {
            choices.add(item);
            if (choices.length >= (difficulty == GameDifficulty.easy ? 3 : 4)) break;
          }
        }
        while (choices.length < (difficulty == GameDifficulty.easy ? 3 : 4)) {
          final nextItem = allPool.firstWhere((it) => optionsSet.add(it.id), orElse: () => allPool.first);
          choices.add(nextItem);
        }
        choices.shuffle();
        _rounds.add(_MemoryOfHomeRound(
          initialObjects: shifted,
          missingItem: missingItem,
          remainingObjects: remainingObjects,
          choiceOptions: choices,
        ));
      }
    }
  }

  // Getters
  int get currentRoundIndex => _currentRoundIndex;
  int get currentRoundNumber => _currentRoundIndex + 1;
  int get totalRounds => sessionConfig.questionCount;

  _MemoryOfHomeRound get _currentRound => _rounds[_currentRoundIndex];
  List<GameItem> get initialObjects => _currentRound.initialObjects;
  GameItem get missingItem => _currentRound.missingItem;
  List<GameItem> get remainingObjects => _currentRound.remainingObjects;
  List<GameItem> get choiceOptions => _currentRound.choiceOptions;

  MemoryOfHomePhase get phase => _phase;
  Set<String> get dimmedOptionIds => _dimmedOptionIds;
  String? get retryFeedbackMessage => _retryFeedbackMessage;
  bool get isRoundSuccess => _isRoundSuccess;
  bool get isSuccess => _isRoundSuccess; // Backward compatibility with existing tests
  bool get isSessionComplete => _isSessionComplete;

  int get totalAttemptsCount => _totalAttempts;
  int get correctFirstAttemptsCount => _correctFirstAttempts;
  double get sessionAccuracy =>
      totalRounds > 0 ? (_correctFirstAttempts / totalRounds) : 0.0;
  List<RoundData> get roundsHistory => List.unmodifiable(_roundsHistory);

  /// User signals they are ready to identify what is missing
  void proceedToRecall() {
    if (_phase == MemoryOfHomePhase.recall || _isRoundSuccess || _isSessionComplete) return;
    _roundFirstInteractionTime ??= DateTime.now();
    recordInteraction();
    _phase = MemoryOfHomePhase.recall;
    notifyListeners();
  }

  /// Handles user answer selection in recall phase
  void selectOption(GameItem selected) {
    if (_isRoundSuccess ||
        _isSessionComplete ||
        _phase != MemoryOfHomePhase.recall ||
        _dimmedOptionIds.contains(selected.id)) {
      return;
    }

    _roundFirstInteractionTime ??= DateTime.now();
    _roundAttempts++;
    _totalAttempts++;
    recordInteraction();

    if (selected.id == missingItem.id) {
      _retryFeedbackMessage = null;
      final bool isFirstAttempt = (_roundAttempts == 1);

      if (isFirstAttempt) {
        _correctFirstAttempts++;
        recordFirstAttemptSuccess();
        addScore(100);
      } else {
        addScore(60);
      }

      final now = DateTime.now();
      final durationMs = now.difference(_roundStartTime).inMilliseconds;
      final reactionTimeMs = _roundFirstInteractionTime != null
          ? _roundFirstInteractionTime!.difference(_roundStartTime).inMilliseconds
          : durationMs;

      _roundsHistory.add(RoundData(
        roundIndex: currentRoundNumber,
        questionId: missingItem.id,
        questionTitle: missingItem.title,
        roundType: 'identify_missing_object',
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
    } else {
      _dimmedOptionIds.add(selected.id);
      _retryFeedbackMessage = "That's not quite right. Try again.";
      notifyListeners();
    }
  }

  /// Advances to the next round in the session, or triggers the final summary screen
  void nextRound() {
    if (!_isRoundSuccess || _isSessionComplete) return;

    if (currentRoundNumber < totalRounds) {
      _currentRoundIndex++;
      _phase = MemoryOfHomePhase.memorize;
      _roundStartTime = DateTime.now();
      _roundFirstInteractionTime = null;
      _roundAttempts = 0;
      _isRoundSuccess = false;
      _dimmedOptionIds.clear();
      _retryFeedbackMessage = null;
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
