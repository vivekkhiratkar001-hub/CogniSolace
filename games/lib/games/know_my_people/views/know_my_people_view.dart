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
import '../controllers/know_my_people_controller.dart';

class KnowMyPeopleView extends StatefulWidget {
  final String patientId;
  final GameScenario scenario;
  final GameSessionConfig? sessionConfig;
  final VoidCallback onFinish;
  final Function(GameResult result)? onResult;

  const KnowMyPeopleView({
    super.key,
    required this.patientId,
    required this.scenario,
    this.sessionConfig,
    required this.onFinish,
    this.onResult,
  });

  @override
  State<KnowMyPeopleView> createState() => _KnowMyPeopleViewState();
}

class _KnowMyPeopleViewState extends State<KnowMyPeopleView> {
  late final KnowMyPeopleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = KnowMyPeopleController(
      patientId: widget.patientId,
      scenario: widget.scenario,
      difficulty: widget.scenario.difficulty,
      sessionConfig: widget.sessionConfig,
      onSessionComplete: widget.onResult,
    )..addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    GameTtsService().stop();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes min $seconds sec';
    }
    return '$seconds sec';
  }

  Widget _buildPortrait(GameItem person) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DementiaUX.cardBorderRadius),
        border: Border.all(
          color: DementiaUX.primaryNavy.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DementiaUX.cardBorderRadius - 2),
        child: person.imageAsset != null && person.imageAsset!.isNotEmpty
            ? Image.asset(
                person.imageAsset!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallbackAvatar(person.title),
              )
            : _buildFallbackAvatar(person.title),
      ),
    );
  }

  Widget _buildFallbackAvatar(String name) {
    return Container(
      color: DementiaUX.primaryNavy.withValues(alpha: 0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.face_rounded,
              size: 88,
              color: DementiaUX.primaryNavy,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: DementiaUX.fontBody,
                fontWeight: FontWeight.bold,
                color: DementiaUX.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Displays the encouraging summary screen when all session rounds are finished
  Widget _buildSessionResultScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DementiaUX.cardBorderRadius),
            boxShadow: [
              BoxShadow(
                color: DementiaUX.successGreen.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: DementiaUX.successGreen.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DementiaUX.successGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  color: DementiaUX.successGreen,
                  size: 56,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Great job!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: DementiaUX.fontTitle + 2,
                  fontWeight: FontWeight.bold,
                  color: DementiaUX.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You completed ${_controller.totalRounds} questions.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: DementiaUX.fontPrompt,
                  color: DementiaUX.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Statistics grid
              _buildStatRow('Correct Answers',
                  '${_controller.correctFirstAttemptsCount} / ${_controller.totalRounds}'),
              const SizedBox(height: 12),
              _buildStatRow('Accuracy',
                  '${(_controller.sessionAccuracy * 100).round()}%'),
              const SizedBox(height: 12),
              _buildStatRow('Total Attempts', '${_controller.totalAttemptsCount}'),
              const SizedBox(height: 12),
              _buildStatRow('Hints Used', '${_controller.totalHintsUsed}'),
              const SizedBox(height: 12),
              _buildStatRow('Time', _formatDuration(_controller.sessionDuration)),

              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: DementiaUX.primaryNavy.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Wonderful effort! Every day is a new step forward.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: DementiaUX.fontBody - 2,
                    color: DementiaUX.primaryNavy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              DementiaButton(
                label: 'Back to Menu',
                backgroundColor: DementiaUX.primaryNavy,
                onPressed: widget.onFinish,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: DementiaUX.fontBody,
            color: DementiaUX.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: DementiaUX.fontBody,
            fontWeight: FontWeight.bold,
            color: DementiaUX.textDark,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isSessionComplete) {
      return GameScaffold(
        title: 'Know My People',
        instruction: 'Session Complete',
        onExitConfirmed: widget.onFinish,
        body: _buildSessionResultScreen(),
      );
    }

    final target = _controller.targetPerson;

    return Stack(
      children: [
        GameScaffold(
          title: 'Know My People',
          instruction: 'Question ${_controller.currentRoundNumber} of ${_controller.totalRounds}',
          onPlayAudioPrompt: () {
            GameTtsService().speak(
              'Question ${_controller.currentRoundNumber} of ${_controller.totalRounds}. Look at the person. ${widget.scenario.promptText}',
            );
          },
          onExitConfirmed: widget.onFinish,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Top row: Question progress and circular hint button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: DementiaUX.primaryNavy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Question ${_controller.currentRoundNumber} of ${_controller.totalRounds}',
                        style: const TextStyle(
                          fontSize: DementiaUX.fontBody,
                          fontWeight: FontWeight.bold,
                          color: DementiaUX.primaryNavy,
                        ),
                      ),
                    ),

                    // User-controlled circular hint button (💡)
                    IconButton(
                      icon: const Icon(Icons.lightbulb_rounded),
                      tooltip: 'Need a hint?',
                      color: DementiaUX.accentAmber,
                      iconSize: 32,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            DementiaUX.accentAmber.withValues(alpha: 0.15),
                        minimumSize: const Size(56, 56), // Large touch target
                        shape: const CircleBorder(),
                      ),
                      onPressed: _controller.showHint ? null : _controller.requestHint,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _buildPortrait(target),
                const SizedBox(height: 20),

                // Retry feedback banner when an incorrect choice is selected
                if (_controller.retryFeedbackMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: DementiaUX.accentAmber,
                        width: 2.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: DementiaUX.accentAmber,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
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

                // Explicit patient-requested hint banner
                if (_controller.showHint)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: DementiaUX.hintGlow.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: DementiaUX.hintGlow,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lightbulb_rounded,
                            color: DementiaUX.accentAmber, size: 28),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'Hint: ${_controller.hintText}',
                            style: const TextStyle(
                              fontSize: DementiaUX.fontBody,
                              fontWeight: FontWeight.w600,
                              color: DementiaUX.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // Choice Buttons
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: _controller.options.map((option) {
                    final isDimmed =
                        _controller.dimmedOptionIds.contains(option.id);

                    final label = option.subtitle != null &&
                            option.subtitle!.isNotEmpty
                        ? '${option.title} (${option.subtitle})'
                        : option.title;

                    return AnimatedOpacity(
                      opacity: isDimmed ? 0.3 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: DementiaButton(
                        label: label,
                        backgroundColor: DementiaUX.primaryNavy,
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
            subtitle: 'You recognized ${target.title} (${target.subtitle})!',
            onDismissed: () => _controller.nextRound(),
          ),
      ],
    );
  }
}
