import '../../../core/controllers/base_game_controller.dart';
import '../../../core/models/game_difficulty.dart';
import '../../../core/models/game_item.dart';
import '../../../core/models/game_result.dart';
import '../../../core/models/game_scenario.dart';
import '../../../core/models/game_session_config.dart';
import '../../../core/models/round_data.dart';

class _PatternPathRound {
  final List<GameItem> sequence;
  final GameItem targetShape;
  final List<GameItem> options;
  final String patternType;

  const _PatternPathRound({
    required this.sequence,
    required this.targetShape,
    required this.options,
    required this.patternType,
  });
}

class PatternPathController extends BaseGameController {
  final GameScenario scenario;
  final GameSessionConfig sessionConfig;
  final Function(GameResult result)? onSessionComplete;

  late final List<_PatternPathRound> _rounds;
  int _currentRoundIndex = 0;

  GameItem? chosenShape;
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

  PatternPathController({
    required super.patientId,
    required this.scenario,
    super.difficulty = GameDifficulty.easy,
    GameSessionConfig? sessionConfig,
    this.onSessionComplete,
  })  : sessionConfig = sessionConfig ?? GameSessionConfig(difficulty: difficulty, questionCount: 6),
        super(
          gameId: 'pattern_path',
          gameMode: 'complete_missing_pattern',
          enableInactivityHint: false,
        ) {
    _generateRounds();
    _roundStartTime = DateTime.now();
  }

  void _generateRounds() {
    _rounds = [];

    const circle = GameItem(id: 'shape_circle', title: 'Circle', subtitle: 'Blue Circle', category: 'shape');
    const square = GameItem(id: 'shape_square', title: 'Square', subtitle: 'Green Square', category: 'shape');
    const triangle = GameItem(id: 'shape_triangle', title: 'Triangle', subtitle: 'Amber Triangle', category: 'shape');
    const star = GameItem(id: 'shape_star', title: 'Star', subtitle: 'Purple Star', category: 'shape');
    const allShapes = [circle, square, triangle, star];

    final int totalRounds = sessionConfig.questionCount;

    for (int i = 0; i < totalRounds; i++) {
      if (i == 0) {
        // Round 0: 100% backward compatible with scenario & existing tests
        final target = scenario.targets.first;
        final shapeMap = {for (final item in scenario.allItems) item.id: item};
        List<GameItem> seq;
        if (scenario.orderedTargetIds != null && scenario.orderedTargetIds!.isNotEmpty) {
          seq = scenario.orderedTargetIds!
              .map((id) => shapeMap[id] ?? target)
              .toList();
        } else {
          seq = [target, ...scenario.distractors];
        }

        _rounds.add(_PatternPathRound(
          sequence: seq,
          targetShape: target,
          options: scenario.allItems,
          patternType: difficulty == GameDifficulty.easy
              ? 'A B A B ?'
              : (difficulty == GameDifficulty.medium ? 'A B C A B ?' : 'A B A C A B ?'),
        ));
      } else {
        // Subsequent rounds: rotate shape assignments across the pattern structure
        final a = allShapes[i % allShapes.length];
        final b = allShapes[(i + 1) % allShapes.length];
        final c = allShapes[(i + 2) % allShapes.length];
        final d = allShapes[(i + 3) % allShapes.length];

        List<GameItem> seq;
        GameItem target;
        String patternType;

        switch (difficulty) {
          case GameDifficulty.easy:
            // A B A B -> [A]
            seq = [a, b, a, b];
            target = a;
            patternType = 'A B A B ?';
            break;
          case GameDifficulty.medium:
            // A B C A B -> [C]
            seq = [a, b, c, a, b];
            target = c;
            patternType = 'A B C A B ?';
            break;
          case GameDifficulty.hard:
            // A B A C A B -> [A]
            seq = [a, b, a, d, a, b];
            target = a;
            patternType = 'A B A C A B ?';
            break;
        }

        _rounds.add(_PatternPathRound(
          sequence: seq,
          targetShape: target,
          options: allShapes,
          patternType: patternType,
        ));
      }
    }
  }

  // Getters
  int get currentRoundIndex => _currentRoundIndex;
  int get currentRoundNumber => _currentRoundIndex + 1;
  int get totalRounds => sessionConfig.questionCount;

  _PatternPathRound get _currentRound => _rounds[_currentRoundIndex];
  List<GameItem> get sequence => _currentRound.sequence;
  GameItem get targetShape => _currentRound.targetShape;
  List<GameItem> get options => _currentRound.options;

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

  void selectOption(GameItem selected) {
    if (_isRoundSuccess || _isSessionComplete || _dimmedOptionIds.contains(selected.id)) {
      return;
    }

    _roundFirstInteractionTime ??= DateTime.now();
    _roundAttempts++;
    _totalAttempts++;
    recordInteraction();

    if (selected.id == targetShape.id) {
      _retryFeedbackMessage = null;
      chosenShape = selected;
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
        questionId: targetShape.id,
        questionTitle: targetShape.title,
        roundType: 'pattern_completion',
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
      chosenShape = null;
      _dimmedOptionIds.clear();
      _retryFeedbackMessage = null;
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
