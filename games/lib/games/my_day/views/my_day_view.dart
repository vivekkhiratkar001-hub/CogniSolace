import 'package:flutter/material.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/models/game_item.dart';
import '../../../core/models/game_result.dart';
import '../../../core/models/game_scenario.dart';
import '../../../core/models/game_session_config.dart';
import '../../../core/services/game_tts_service.dart';
import '../../../core/widgets/feedback_overlay.dart';
import '../../../core/widgets/game_scaffold.dart';
import '../../../core/widgets/session_result_screen.dart';
import '../controllers/my_day_controller.dart';

class MyDayView extends StatefulWidget {
  final String patientId;
  final GameScenario scenario;
  final GameSessionConfig? sessionConfig;
  final VoidCallback onFinish;
  final Function(GameResult result)? onResult;

  const MyDayView({
    super.key,
    required this.patientId,
    required this.scenario,
    this.sessionConfig,
    required this.onFinish,
    this.onResult,
  });

  @override
  State<MyDayView> createState() => _MyDayViewState();
}

class _MyDayViewState extends State<MyDayView> {
  late final MyDayController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MyDayController(
      patientId: widget.patientId,
      scenario: widget.scenario,
      difficulty: widget.scenario.difficulty,
      sessionConfig: widget.sessionConfig,
      onSessionComplete: widget.onResult,
    )..addListener(_onUpdate);
  }

  void _onUpdate() {
    setState(() {});
  }

  @override
  void dispose() {
    GameTtsService().stop();
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    super.dispose();
  }

  IconData _getStepIcon(String? iconName) {
    switch (iconName) {
      case 'free_breakfast':
        return Icons.free_breakfast_rounded;
      case 'clean_hands':
      case 'water_drop':
        return Icons.clean_hands_rounded;
      case 'self_improvement':
        return Icons.self_improvement_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'yard':
        return Icons.yard_rounded;
      case 'storefront':
        return Icons.storefront_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  Widget _buildPlacedSlot(int index, GameItem? item) {
    final isNext = index == _controller.orderedSlots.length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: item != null
            ? Colors.green.shade50
            : (isNext ? DementiaUX.hintGlow.withValues(alpha: 0.12) : Colors.white),
        borderRadius: BorderRadius.circular(DementiaUX.cardBorderRadius),
        border: Border.all(
          color: item != null
              ? DementiaUX.successGreen
              : (isNext ? DementiaUX.accentAmber : Colors.grey.shade300),
          width: isNext ? 2.5 : 1.5,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: item != null
                ? DementiaUX.successGreen
                : DementiaUX.primaryNavy.withValues(alpha: 0.1),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: item != null ? Colors.white : DementiaUX.primaryNavy,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: item != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: DementiaUX.fontBody,
                          fontWeight: FontWeight.bold,
                          color: DementiaUX.textDark,
                        ),
                      ),
                      if (item.subtitle != null)
                        Text(
                          item.subtitle!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: DementiaUX.textMuted,
                          ),
                        ),
                    ],
                  )
                : Text(
                    isNext ? 'Tap the next activity below...' : 'Step ${index + 1}',
                    style: TextStyle(
                      fontSize: DementiaUX.fontBody,
                      fontStyle: FontStyle.italic,
                      color: isNext ? DementiaUX.accentAmber : Colors.grey.shade400,
                    ),
                  ),
          ),
          if (item != null)
            const Icon(Icons.check_circle, color: DementiaUX.successGreen, size: 28),
        ],
      ),
    );
  }

  Widget _buildAvailableCard(GameItem card) {
    final nextTarget = _controller.nextExpectedStep;
    final isHinted = _controller.showHint && nextTarget?.id == card.id;

    return InkWell(
      onTap: () => _controller.selectCard(card),
      borderRadius: BorderRadius.circular(DementiaUX.cardBorderRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 150,
        height: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(DementiaUX.cardBorderRadius),
          border: Border.all(
            color: isHinted ? DementiaUX.hintGlow : DementiaUX.primaryNavy.withValues(alpha: 0.3),
            width: isHinted ? 3.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isHinted
                  ? DementiaUX.hintGlow.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: isHinted ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getStepIcon(card.customData['icon_name'] as String?),
              size: 40,
              color: DementiaUX.primaryNavy,
            ),
            const SizedBox(height: 10),
            Text(
              card.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: DementiaUX.textDark,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isSessionComplete) {
      return GameScaffold(
        title: 'My Day Routine',
        instruction: 'Session Complete',
        onExitConfirmed: widget.onFinish,
        body: SessionResultScreen(
          title: 'My Day',
          totalQuestions: _controller.totalRounds,
          correctAnswers: _controller.correctFirstAttemptsCount,
          accuracy: _controller.sessionAccuracy,
          totalAttempts: _controller.totalAttemptsCount,
          duration: _controller.sessionDuration,
          onBackToMenu: widget.onFinish,
        ),
      );
    }

    final totalSteps = _controller.expectedOrder.length;

    return Stack(
      children: [
        GameScaffold(
          title: 'My Day Routine',
          instruction: 'Question ${_controller.currentRoundNumber} of ${_controller.totalRounds}: ${_controller.promptText}',
          onPlayAudioPrompt: () {
            GameTtsService().speak(
              'Question ${_controller.currentRoundNumber} of ${_controller.totalRounds}. Look at the activities. Arrange your daily routine in order.',
            );
          },
          onExitConfirmed: widget.onFinish,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question progress pill
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

                // Non-punitive retry feedback banner
                if (_controller.retryFeedbackMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: DementiaUX.accentAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: DementiaUX.accentAmber,
                        width: 2,
                      ),
                    ),
                    child: Row(
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
                  'Your Day Sequence:',
                  style: TextStyle(
                    fontSize: DementiaUX.fontBody,
                    fontWeight: FontWeight.bold,
                    color: DementiaUX.textDark,
                  ),
                ),
                const SizedBox(height: 12),

                // Sequence slots
                ...List.generate(totalSteps, (index) {
                  final item = index < _controller.orderedSlots.length
                      ? _controller.orderedSlots[index]
                      : null;
                  return _buildPlacedSlot(index, item);
                }),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                const Text(
                  'Available Activities (Tap in order):',
                  style: TextStyle(
                    fontSize: DementiaUX.fontBody,
                    fontWeight: FontWeight.bold,
                    color: DementiaUX.textDark,
                  ),
                ),
                const SizedBox(height: 12),

                // Available cards
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: _controller.availableCards
                      .map((card) => _buildAvailableCard(card))
                      .toList(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),

        // Celebratory feedback overlay between rounds
        if (_controller.isRoundSuccess && !_controller.isSessionComplete)
          FeedbackOverlay(
            title: 'Great Routine Recall!',
            subtitle: 'You arranged your entire day perfectly.',
            onDismissed: () => _controller.nextRound(),
          ),
      ],
    );
  }
}
