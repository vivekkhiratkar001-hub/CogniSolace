import 'package:flutter/material.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/models/game_item.dart';
import '../../../core/models/game_result.dart';
import '../../../core/models/game_scenario.dart';
import '../../../core/models/game_session_config.dart';
import '../../../core/services/game_tts_service.dart';
import '../../../core/widgets/dementia_button.dart';
import '../../../core/widgets/feedback_overlay.dart';
import '../../../core/widgets/game_scaffold.dart';
import '../../../core/widgets/session_result_screen.dart';
import '../controllers/pattern_path_controller.dart';

/// Dementia-friendly pattern recognition activity: Pattern Path.
/// Patients identify the missing shape in a repeating sequence.
class PatternPathView extends StatefulWidget {
  final String patientId;
  final GameScenario scenario;
  final GameSessionConfig? sessionConfig;
  final VoidCallback onFinish;
  final Function(GameResult result)? onResult;

  const PatternPathView({
    super.key,
    required this.patientId,
    required this.scenario,
    this.sessionConfig,
    required this.onFinish,
    this.onResult,
  });

  @override
  State<PatternPathView> createState() => _PatternPathViewState();
}

class _PatternPathViewState extends State<PatternPathView> {
  late final PatternPathController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PatternPathController(
      patientId: widget.patientId,
      scenario: widget.scenario,
      difficulty: widget.scenario.difficulty,
      sessionConfig: widget.sessionConfig,
      onSessionComplete: widget.onResult,
    );
    _controller.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    GameTtsService().stop();
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  IconData _getShapeIcon(String id) {
    if (id.contains('circle')) return Icons.circle;
    if (id.contains('square')) return Icons.square_rounded;
    if (id.contains('triangle')) return Icons.change_history_rounded;
    if (id.contains('star')) return Icons.star_rounded;
    return Icons.category_rounded;
  }

  Color _getShapeColor(String id) {
    if (id.contains('circle')) return const Color(0xFF1E88E5);
    if (id.contains('square')) return DementiaUX.primarySage;
    if (id.contains('triangle')) return DementiaUX.accentAmber;
    if (id.contains('star')) return const Color(0xFF8E24AA);
    return DementiaUX.primaryNavy;
  }

  Widget _buildShapeCard(GameItem shape, {bool isSlot = false}) {
    final icon = _getShapeIcon(shape.id);
    final color = _getShapeColor(shape.id);

    return Container(
      width: 104,
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DementiaUX.cardBorderRadius),
        border: Border.all(
          color: isSlot
              ? DementiaUX.accentAmber
              : color.withValues(alpha: 0.4),
          width: isSlot ? 2.5 : 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 42, color: color),
          const SizedBox(height: 4),
          Text(
            shape.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: DementiaUX.fontBody - 4,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionSlot() {
    if (_controller.chosenShape != null) {
      return _buildShapeCard(_controller.chosenShape!, isSlot: true);
    }

    return Container(
      width: 104,
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: DementiaUX.accentAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DementiaUX.cardBorderRadius),
        border: Border.all(
          color: DementiaUX.accentAmber,
          width: 2.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.help_outline_rounded,
              size: 42, color: DementiaUX.accentAmber),
          SizedBox(height: 4),
          Text(
            'What Next?',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: DementiaUX.fontBody - 4,
              fontWeight: FontWeight.bold,
              color: DementiaUX.accentAmber,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isSessionComplete) {
      return GameScaffold(
        title: 'Pattern Path',
        instruction: 'Session Complete',
        onExitConfirmed: widget.onFinish,
        body: SessionResultScreen(
          title: 'Pattern Path',
          totalQuestions: _controller.totalRounds,
          correctAnswers: _controller.correctFirstAttemptsCount,
          accuracy: _controller.sessionAccuracy,
          totalAttempts: _controller.totalAttemptsCount,
          duration: _controller.sessionDuration,
          onBackToMenu: widget.onFinish,
        ),
      );
    }

    return Stack(
      children: [
        GameScaffold(
          title: 'Pattern Path',
          instruction: 'Question ${_controller.currentRoundNumber} of ${_controller.totalRounds}: Which shape comes next?',
          onPlayAudioPrompt: () {
            GameTtsService().speak(
              'Question ${_controller.currentRoundNumber} of ${_controller.totalRounds}. Look at the pattern on the track. Which shape comes next? Tap your answer below.',
            );
          },
          onExitConfirmed: widget.onFinish,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top row: Question progress pill
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: DementiaUX.primaryNavy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Question ${_controller.currentRoundNumber} of ${_controller.totalRounds}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: DementiaUX.primaryNavy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text(
                  'Follow the pattern path:',
                  style: TextStyle(
                    fontSize: DementiaUX.fontPrompt,
                    fontWeight: FontWeight.w600,
                    color: DementiaUX.textDark,
                  ),
                ),
                const SizedBox(height: 16),

                // Sequence track
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(DementiaUX.cardBorderRadius),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (int i = 0; i < _controller.sequence.length; i++) ...[
                        _buildShapeCard(_controller.sequence[i]),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: DementiaUX.textMuted,
                            size: 24,
                          ),
                        ),
                      ],
                      _buildQuestionSlot(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Dementia-friendly retry message banner
                if (_controller.retryFeedbackMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: DementiaUX.accentAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: DementiaUX.accentAmber,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: DementiaUX.accentAmber, size: 28),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            _controller.retryFeedbackMessage!,
                            style: const TextStyle(
                              fontSize: DementiaUX.fontBody,
                              fontWeight: FontWeight.bold,
                              color: DementiaUX.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const Text(
                  'Choose the next shape:',
                  style: TextStyle(
                    fontSize: DementiaUX.fontTitle,
                    fontWeight: FontWeight.bold,
                    color: DementiaUX.primaryNavy,
                  ),
                ),
                const SizedBox(height: 16),

                // Choice buttons
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: _controller.options.map((option) {
                    final isDimmed =
                        _controller.dimmedOptionIds.contains(option.id);
                    final color = _getShapeColor(option.id);
                    final icon = _getShapeIcon(option.id);

                    return AnimatedOpacity(
                      opacity: isDimmed ? 0.3 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: DementiaButton(
                        label: option.title,
                        icon: icon,
                        backgroundColor: color,
                        onPressed: isDimmed
                            ? null
                            : () => _controller.selectOption(option),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),

        // Celebratory feedback overlay between rounds
        if (_controller.isRoundSuccess && !_controller.isSessionComplete)
          FeedbackOverlay(
            title: 'Wonderful! (Bhal Hoise!)',
            subtitle: 'You completed the pattern with the ${_controller.targetShape.title}!',
            onDismissed: () => _controller.nextRound(),
          ),
      ],
    );
  }
}
