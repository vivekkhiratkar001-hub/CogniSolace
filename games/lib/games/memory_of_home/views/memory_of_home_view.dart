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
import '../controllers/memory_of_home_controller.dart';

/// Dementia-friendly visual memory game: Memory of Home.
/// Patients memorize a set of familiar objects, then identify which one was removed.
class MemoryOfHomeView extends StatefulWidget {
  final String patientId;
  final GameScenario scenario;
  final GameSessionConfig? sessionConfig;
  final VoidCallback onFinish;
  final Function(GameResult result)? onResult;

  const MemoryOfHomeView({
    super.key,
    required this.patientId,
    required this.scenario,
    this.sessionConfig,
    required this.onFinish,
    this.onResult,
  });

  @override
  State<MemoryOfHomeView> createState() => _MemoryOfHomeViewState();
}

class _MemoryOfHomeViewState extends State<MemoryOfHomeView> {
  late final MemoryOfHomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MemoryOfHomeController(
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

  IconData _getIconForItem(GameItem item) {
    final title = item.title.toLowerCase();
    final id = item.id.toLowerCase();

    if (title.contains('tea') || id.contains('tea')) return Icons.emoji_food_beverage_rounded;
    if (title.contains('umbrella') || id.contains('umbrella')) return Icons.umbrella_rounded;
    if (title.contains('basket') || id.contains('basket') || id.contains('khoh')) return Icons.shopping_basket_rounded;
    if (title.contains('radio') || id.contains('radio')) return Icons.radio_rounded;
    if (title.contains('glass') || id.contains('glass')) return Icons.visibility_rounded;
    if (title.contains('stick') || id.contains('stick')) return Icons.nordic_walking_rounded;
    if (title.contains('gamosa') || id.contains('gamosa')) return Icons.dry_cleaning_rounded;
    if (title.contains('lemon') || title.contains('nemu') || title.contains('orange')) return Icons.eco_rounded;
    if (title.contains('pitha') || title.contains('snack')) return Icons.bakery_dining_rounded;
    if (title.contains('newspaper') || title.contains('paper')) return Icons.newspaper_rounded;
    return Icons.category_rounded;
  }

  Widget _buildItemCard(GameItem item, {bool isPlaceholder = false}) {
    final icon = _getIconForItem(item);

    return Container(
      width: 140,
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPlaceholder ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(DementiaUX.cardBorderRadius),
        border: Border.all(
          color: isPlaceholder
              ? DementiaUX.accentAmber.withValues(alpha: 0.6)
              : DementiaUX.primaryNavy.withValues(alpha: 0.2),
          width: isPlaceholder ? 2.5 : 2.0,
        ),
        boxShadow: isPlaceholder
            ? []
            : [
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
          Icon(
            isPlaceholder ? Icons.help_outline_rounded : icon,
            size: 48,
            color: isPlaceholder ? DementiaUX.accentAmber : DementiaUX.primaryNavy,
          ),
          const SizedBox(height: 8),
          Text(
            isPlaceholder ? 'Missing ?' : item.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: DementiaUX.fontBody - 2,
              fontWeight: FontWeight.bold,
              color: isPlaceholder ? DementiaUX.accentAmber : DementiaUX.textDark,
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
        title: 'Memory of Home',
        instruction: 'Session Complete',
        onExitConfirmed: widget.onFinish,
        body: SessionResultScreen(
          title: 'Memory of Home',
          totalQuestions: _controller.totalRounds,
          correctAnswers: _controller.correctFirstAttemptsCount,
          accuracy: _controller.sessionAccuracy,
          totalAttempts: _controller.totalAttemptsCount,
          duration: _controller.sessionDuration,
          onBackToMenu: widget.onFinish,
        ),
      );
    }

    final isMemorize = _controller.phase == MemoryOfHomePhase.memorize;

    return Stack(
      children: [
        GameScaffold(
          title: 'Memory of Home',
          instruction: 'Question ${_controller.currentRoundNumber} of ${_controller.totalRounds}: ${isMemorize ? "Memorize what is on the table" : "Which one is missing?"}',
          onPlayAudioPrompt: () {
            if (isMemorize) {
              GameTtsService().speak(
                'Question ${_controller.currentRoundNumber} of ${_controller.totalRounds}. Look at these familiar objects on the table and remember them. When you are ready, tap I am ready.',
              );
            } else {
              GameTtsService().speak(
                'Question ${_controller.currentRoundNumber} of ${_controller.totalRounds}. Which object is missing from the table? Tap the correct missing object below.',
              );
            }
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
                  ],
                ),
                const SizedBox(height: 16),

                // Phase 1: Memorization
                if (isMemorize) ...[
                  const Text(
                    'Memorize what is on the table:',
                    style: TextStyle(
                      fontSize: DementiaUX.fontPrompt,
                      fontWeight: FontWeight.w600,
                      color: DementiaUX.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: _controller.initialObjects
                        .map((item) => _buildItemCard(item))
                        .toList(),
                  ),
                  const SizedBox(height: 32),
                  DementiaButton(
                    label: "I'm Ready",
                    backgroundColor: DementiaUX.primarySage,
                    onPressed: _controller.proceedToRecall,
                  ),
                ],

                // Phase 2: Recall
                if (!isMemorize) ...[
                  const Text(
                    'Here is what remains on the table:',
                    style: TextStyle(
                      fontSize: DementiaUX.fontPrompt,
                      fontWeight: FontWeight.w600,
                      color: DementiaUX.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      ..._controller.remainingObjects
                          .map((item) => _buildItemCard(item)),
                      _buildItemCard(_controller.missingItem, isPlaceholder: true),
                    ],
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
                    'Which one is missing?',
                    style: TextStyle(
                      fontSize: DementiaUX.fontTitle,
                      fontWeight: FontWeight.bold,
                      color: DementiaUX.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Choice Options
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: _controller.choiceOptions.map((option) {
                      final isDimmed =
                          _controller.dimmedOptionIds.contains(option.id);

                      return AnimatedOpacity(
                        opacity: isDimmed ? 0.3 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: DementiaButton(
                          label: option.title,
                          icon: _getIconForItem(option),
                          backgroundColor: DementiaUX.primaryNavy,
                          onPressed: isDimmed
                              ? null
                              : () => _controller.selectOption(option),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),

        // Celebratory feedback overlay between rounds
        if (_controller.isRoundSuccess && !_controller.isSessionComplete)
          FeedbackOverlay(
            title: 'Wonderful! (Bhal Hoise!)',
            subtitle: 'You remembered the ${_controller.missingItem.title}!',
            onDismissed: () => _controller.nextRound(),
          ),
      ],
    );
  }
}
