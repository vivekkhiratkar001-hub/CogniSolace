import '../../../core/controllers/base_game_controller.dart';
import '../../../core/models/game_difficulty.dart';
import '../../../core/models/game_item.dart';
import '../../../core/models/game_result.dart';
import '../../../core/models/game_scenario.dart';
import '../../../core/models/game_session_config.dart';
import '../../../core/models/round_data.dart';

/// Multi-round game controller for Know My People.
/// Supports configurable question counts (default 10) for the Adaptive Learning Engine (M3),
/// user-requested hints (no auto-interruption), granular round telemetry, and dementia-friendly retry.
class KnowMyPeopleController extends BaseGameController {
  final GameScenario scenario;
  final GameSessionConfig sessionConfig;
  final Function(GameResult result)? onSessionComplete;

  late final List<GameItem> _candidatePool;
  late final List<GameItem> _roundTargets;
  late final List<List<GameItem>> _roundOptions;

  int _currentRoundIndex = 0;
  DateTime _roundStartTime = DateTime.now();
  DateTime? _roundFirstInteractionTime;
  int _roundAttempts = 0;
  bool _roundHintUsed = false;
  bool _isRoundSuccess = false;
  bool _isSessionComplete = false;

  final Set<String> _dimmedOptionIds = {};
  String? _retryFeedbackMessage;

  final List<RoundData> _roundsHistory = [];
  int _totalHintsUsed = 0;
  int _totalAttempts = 0;
  int _correctFirstAttempts = 0;

  KnowMyPeopleController({
    required super.patientId,
    required this.scenario,
    super.difficulty = GameDifficulty.easy,
    GameSessionConfig? sessionConfig,
    this.onSessionComplete,
  })  : sessionConfig = sessionConfig ?? GameSessionConfig(difficulty: difficulty),
        super(
          gameId: 'know_my_people',
          gameMode: 'face_recognition',
          enableInactivityHint: false, // Inactivity timer hints disabled; patient controls hints
        ) {
    _initCandidatePool();
    _generateRounds();
    _roundStartTime = DateTime.now();
  }

  void _initCandidatePool() {
    // Collect all available family & caregiver candidate profiles
    final pool = <String, GameItem>{};
    for (final item in scenario.targets) {
      pool[item.id] = item;
    }
    for (final item in scenario.distractors) {
      pool[item.id] = item;
    }

    if (pool.isEmpty) {
      // Robust offline fallback candidates
      const fallbackList = [
        GameItem(id: 'fam_1', title: 'Raju', subtitle: 'Son (Lara)', category: 'family'),
        GameItem(id: 'fam_2', title: 'Sujata', subtitle: 'Daughter (Suwali)', category: 'family'),
        GameItem(id: 'fam_3', title: 'Aarav', subtitle: 'Grandson (Nati)', category: 'family'),
        GameItem(id: 'fam_4', title: 'Dr. Sharma', subtitle: 'Family Doctor', category: 'caregiver'),
      ];
      for (final item in fallbackList) {
        pool[item.id] = item;
      }
    }

    _candidatePool = pool.values.toList();
  }

  void _generateRounds() {
    _roundTargets = [];
    _roundOptions = [];

    final int totalRounds = sessionConfig.questionCount;
    final int distractorCount = difficulty == GameDifficulty.easy
        ? 1
        : (difficulty == GameDifficulty.medium ? 2 : 3);

    for (int i = 0; i < totalRounds; i++) {
      // Select target person for this round
      final target = _candidatePool[i % _candidatePool.length];
      _roundTargets.add(target);

      // Select distractors for this round
      final otherCandidates = _candidatePool.where((c) => c.id != target.id).toList();
      final distractors = <GameItem>[];
      for (int d = 0; d < distractorCount; d++) {
        if (otherCandidates.isNotEmpty) {
          distractors.add(otherCandidates[(i + d) % otherCandidates.length]);
        }
      }

      // Round 0 preserves deterministic order for testing ([target, distractor])
      final options = [target, ...distractors];
      if (i > 0) {
        options.shuffle();
      }
      _roundOptions.add(options);
    }
  }

  // Getters
  int get currentRoundIndex => _currentRoundIndex;
  int get currentRoundNumber => _currentRoundIndex + 1;
  int get totalRounds => sessionConfig.questionCount;

  GameItem get targetPerson => _roundTargets[_currentRoundIndex];
  List<GameItem> get options => _roundOptions[_currentRoundIndex];

  Set<String> get dimmedOptionIds => _dimmedOptionIds;
  String? get retryFeedbackMessage => _retryFeedbackMessage;
  @override
  bool get showHint => _roundHintUsed;
  bool get roundHintUsed => _roundHintUsed;

  bool get isRoundSuccess => _isRoundSuccess;
  bool get isSuccess => _isRoundSuccess; // Backward compatibility with existing tests
  bool get isSessionComplete => _isSessionComplete;

  List<RoundData> get roundsHistory => List.unmodifiable(_roundsHistory);
  int get totalHintsUsed => _totalHintsUsed;
  int get totalAttemptsCount => _totalAttempts;
  int get correctFirstAttemptsCount => _correctFirstAttempts;

  double get sessionAccuracy =>
      totalRounds > 0 ? (_correctFirstAttempts / totalRounds) : 0.0;

  String get hintText {
    if (targetPerson.category == 'caregiver') {
      return 'This person is a caregiver who helps you.';
    }
    return 'This person is someone from your family.';
  }

  /// Patient taps the circular hint button to request gentle guidance
  void requestHint() {
    if (_isRoundSuccess || _isSessionComplete || _roundHintUsed) return;
    recordInteraction();
    _roundHintUsed = true;
    _totalHintsUsed++;
    triggerHint();
  }

  /// Handles user selection with dementia-friendly retry feedback
  void selectOption(GameItem selected) {
    if (_isRoundSuccess || _isSessionComplete || _dimmedOptionIds.contains(selected.id)) {
      return;
    }

    _roundFirstInteractionTime ??= DateTime.now();
    _roundAttempts++;
    _totalAttempts++;
    recordInteraction();

    if (selected.id == targetPerson.id) {
      _retryFeedbackMessage = null;
      final bool isFirstAttempt = (_roundAttempts == 1);

      if (isFirstAttempt) {
        _correctFirstAttempts++;
        recordFirstAttemptSuccess();
        addScore(100);
      } else {
        addScore(60); // Encouragement score
      }

      final now = DateTime.now();
      final durationMs = now.difference(_roundStartTime).inMilliseconds;
      final reactionTimeMs = _roundFirstInteractionTime != null
          ? _roundFirstInteractionTime!.difference(_roundStartTime).inMilliseconds
          : durationMs;

      // Record round data
      final roundData = RoundData(
        roundIndex: currentRoundNumber,
        questionPersonId: targetPerson.id,
        questionPersonName: targetPerson.title,
        difficulty: difficulty,
        isFirstAttemptCorrect: isFirstAttempt,
        isSolved: true,
        attempts: _roundAttempts,
        hintUsed: _roundHintUsed,
        reactionTimeMs: reactionTimeMs,
        durationMs: durationMs,
      );
      _roundsHistory.add(roundData);

      _isRoundSuccess = true;
      notifyListeners();
    } else {
      // Incorrect choice: clear retry feedback without revealing the correct answer
      _dimmedOptionIds.add(selected.id);
      _retryFeedbackMessage = "That's not quite right. Try again.";
      notifyListeners();
    }
  }

  /// Advances to the next round in the session, or transitions to the result screen
  void nextRound() {
    if (!_isRoundSuccess || _isSessionComplete) return;

    if (currentRoundNumber < totalRounds) {
      _currentRoundIndex++;
      _roundStartTime = DateTime.now();
      _roundFirstInteractionTime = null;
      _roundAttempts = 0;
      _roundHintUsed = false;
      _isRoundSuccess = false;
      _dimmedOptionIds.clear();
      _retryFeedbackMessage = null;
      notifyListeners();
    } else {
      // All rounds completed: finish session and transition to summary screen
      _isSessionComplete = true;
      final result = finishSession(extraMetadata: {
        'question_count': totalRounds,
        'total_hints_used': _totalHintsUsed,
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
