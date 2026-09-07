import '../../../core/controllers/base_game_controller.dart';
import '../../../core/models/game_difficulty.dart';
import '../../../core/models/game_item.dart';
import '../../../core/models/game_result.dart';
import '../../../core/models/game_scenario.dart';
import '../../../core/models/game_session_config.dart';
import '../../../core/models/round_data.dart';

class _MyDayRound {
  final List<GameItem> expectedOrder;
  final String promptText;

  const _MyDayRound({
    required this.expectedOrder,
    required this.promptText,
  });
}

class MyDayController extends BaseGameController {
  final GameScenario scenario;
  final GameSessionConfig sessionConfig;
  final Function(GameResult result)? onSessionComplete;

  late final List<_MyDayRound> _rounds;
  int _currentRoundIndex = 0;

  final List<GameItem> orderedSlots = [];
  late List<GameItem> availableCards;
  String? _retryFeedbackMessage;
  bool _isRoundSuccess = false;
  bool _isSessionComplete = false;

  late DateTime _roundStartTime;
  DateTime? _roundFirstInteractionTime;
  int _roundAttempts = 0;
  int _totalAttempts = 0;
  int _correctFirstAttempts = 0;
  final List<RoundData> _roundsHistory = [];

  MyDayController({
    required super.patientId,
    required this.scenario,
    super.difficulty = GameDifficulty.easy,
    GameSessionConfig? sessionConfig,
    this.onSessionComplete,
  })  : sessionConfig = sessionConfig ?? GameSessionConfig(difficulty: difficulty, questionCount: 5),
        super(
          gameId: 'my_day',
          gameMode: 'routine_sequencing',
          enableInactivityHint: false,
        ) {
    _generateRounds();
    _initCurrentRound();
    _roundStartTime = DateTime.now();
  }

  void _generateRounds() {
    _rounds = [];
    final pool = <GameItem>[...scenario.targets, ...scenario.distractors];
    if (pool.length < 4) {
      const fallbackSteps = [
        GameItem(id: 'as_1', title: 'Morning Red Tea', subtitle: 'Step 1: Fresh morning tea', category: 'routine'),
        GameItem(id: 'as_2', title: 'Wash Face & Hands', subtitle: 'Step 2: Freshen up', category: 'routine'),
        GameItem(id: 'as_3', title: 'Morning Prayer', subtitle: 'Step 3: Diya & peaceful prayer', category: 'routine'),
        GameItem(id: 'as_4', title: 'Midday Meal', subtitle: 'Step 4: Nourishing lunch', category: 'routine'),
        GameItem(id: 'as_5', title: 'Garden Walk', subtitle: 'Step 5: Gentle walk outdoors', category: 'routine'),
        GameItem(id: 'as_6', title: 'Night Rest', subtitle: 'Step 6: Good sleep', category: 'routine'),
      ];
      for (final fb in fallbackSteps) {
        if (!pool.any((item) => item.id == fb.id || item.title == fb.title)) {
          pool.add(fb);
        }
      }
    }

    final int stepCount = difficulty == GameDifficulty.easy
        ? 2
        : (difficulty == GameDifficulty.medium ? 3 : 4);
    final int totalRounds = sessionConfig.questionCount;

    for (int i = 0; i < totalRounds; i++) {
      if (i == 0) {
        // Round 0: 100% backward compatible with scenario targets & tests
        _rounds.add(_MyDayRound(
          expectedOrder: List<GameItem>.from(scenario.targets),
          promptText: scenario.promptText,
        ));
      } else {
        // Subsequent rounds: slices of chronological routine steps
        final slice = <GameItem>[];
        for (int s = 0; s < stepCount; s++) {
          slice.add(pool[(i + s) % pool.length]);
        }
        _rounds.add(_MyDayRound(
          expectedOrder: slice,
          promptText: 'Arrange these ${slice.length} routine activities in order',
        ));
      }
    }
  }

  void _initCurrentRound() {
    orderedSlots.clear();
    availableCards = List<GameItem>.from(_currentRound.expectedOrder)..shuffle();
    _isRoundSuccess = false;
    _retryFeedbackMessage = null;
    _roundAttempts = 0;
    _roundStartTime = DateTime.now();
    _roundFirstInteractionTime = null;
  }

  // Getters
  int get currentRoundIndex => _currentRoundIndex;
  int get currentRoundNumber => _currentRoundIndex + 1;
  int get totalRounds => sessionConfig.questionCount;

  _MyDayRound get _currentRound => _rounds[_currentRoundIndex];
  List<GameItem> get expectedOrder => _currentRound.expectedOrder;
  String get promptText => _currentRound.promptText;

  bool get isRoundSuccess => _isRoundSuccess;
  bool get isSuccess => _isRoundSuccess; // Backward compatibility with existing tests
  bool get isSessionComplete => _isSessionComplete;
  String? get retryFeedbackMessage => _retryFeedbackMessage;

  int get currentTargetStepIndex => orderedSlots.length;
  GameItem? get nextExpectedStep =>
      currentTargetStepIndex < expectedOrder.length
          ? expectedOrder[currentTargetStepIndex]
          : null;

  int get totalAttemptsCount => _totalAttempts;
  int get correctFirstAttemptsCount => _correctFirstAttempts;
  double get sessionAccuracy =>
      totalRounds > 0 ? (_correctFirstAttempts / totalRounds) : 0.0;
  List<RoundData> get roundsHistory => List.unmodifiable(_roundsHistory);

  void selectCard(GameItem card) {
    if (_isRoundSuccess || _isSessionComplete || orderedSlots.contains(card)) return;

    _roundFirstInteractionTime ??= DateTime.now();
    _roundAttempts++;
    _totalAttempts++;
    recordInteraction();

    final expected = nextExpectedStep;
    if (expected != null && card.id == expected.id) {
      // Correct step in sequence
      _retryFeedbackMessage = null;
      orderedSlots.add(card);
      availableCards.remove(card);

      if (_roundAttempts <= expectedOrder.length) {
        addScore(40);
      } else {
        addScore(25);
      }

      // Check if all steps in this round are completed
      if (orderedSlots.length == expectedOrder.length) {
        final bool isFirstAttempt = (_roundAttempts == expectedOrder.length);
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
          questionId: expectedOrder.map((s) => s.id).join(','),
          questionTitle: expectedOrder.map((s) => s.title).join(' -> '),
          roundType: 'routine_sequencing',
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
      // Incorrect card tapped: gentle prompt and non-punitive retry feedback
      _retryFeedbackMessage = "That's not quite right. Try again.";
      triggerHint();
      notifyListeners();
    }
  }

  void undoLast() {
    if (orderedSlots.isEmpty || _isRoundSuccess || _isSessionComplete) return;
    final last = orderedSlots.removeLast();
    availableCards.add(last);
    _retryFeedbackMessage = null;
    notifyListeners();
  }

  /// Advances to the next round in the session, or triggers the final summary screen
  void nextRound() {
    if (!_isRoundSuccess || _isSessionComplete) return;

    if (currentRoundNumber < totalRounds) {
      _currentRoundIndex++;
      _initCurrentRound();
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
