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
import '../controllers/daily_market_controller.dart';

class DailyMarketView extends StatefulWidget {
  final String patientId;
  final GameScenario scenario;
  final GameSessionConfig? sessionConfig;
  final VoidCallback onFinish;
  final Function(GameResult result)? onResult;

  const DailyMarketView({
    super.key,
    required this.patientId,
    required this.scenario,
    this.sessionConfig,
    required this.onFinish,
    this.onResult,
  });

  @override
  State<DailyMarketView> createState() => _DailyMarketViewState();
}

class _DailyMarketViewState extends State<DailyMarketView> {
  late final DailyMarketController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DailyMarketController(
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'market_fruit':
      case 'fruit':
        return Icons.eco_rounded;
      case 'market_vegetable':
      case 'vegetable':
        return Icons.grass_rounded;
      case 'market_beverage':
      case 'beverage':
        return Icons.local_cafe_rounded;
      case 'market_craft':
      case 'craft':
        return Icons.shopping_basket_rounded;
      case 'market_snack':
      case 'snack':
        return Icons.bakery_dining_rounded;
      default:
        return Icons.storefront_rounded;
    }
  }

  Widget _buildMarketCard(GameItem item) {
    final isCollected = _controller.collectedItemIds.contains(item.id);
    final isDimmed = _controller.dimmedDistractorIds.contains(item.id);
    final isTargetAndHinted = _controller.showHint &&
        _controller.isTarget(item.id) &&
        !isCollected;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isDimmed ? 0.25 : (isCollected ? 0.75 : 1.0),
      child: GestureDetector(
        onTap: isDimmed || isCollected
            ? null
            : () => _controller.tapMarketItem(item),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isCollected ? Colors.green.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(DementiaUX.cardBorderRadius),
            border: Border.all(
              color: isCollected
                  ? DementiaUX.successGreen
                  : (isTargetAndHinted
                      ? DementiaUX.hintGlow
                      : Colors.grey.shade300),
              width: isTargetAndHinted ? 4.0 : 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isTargetAndHinted
                    ? DementiaUX.hintGlow.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: isTargetAndHinted ? 14 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: DementiaUX.primarySage.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCategoryIcon(item.category),
                      size: 40,
                      color: DementiaUX.primarySage,
                    ),
                  ),
                  if (isCollected)
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: DementiaUX.successGreen.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: DementiaUX.fontBody,
                  fontWeight: FontWeight.bold,
                  color: isCollected
                      ? DementiaUX.successGreen
                      : DementiaUX.textDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  item.subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: DementiaUX.textMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isSessionComplete) {
      return GameScaffold(
        title: 'Daily Market Stall',
        instruction: 'Session Complete',
        onExitConfirmed: widget.onFinish,
        body: SessionResultScreen(
          title: 'Daily Market',
          totalQuestions: _controller.totalRounds,
          correctAnswers: _controller.correctFirstAttemptsCount,
          accuracy: _controller.sessionAccuracy,
          totalAttempts: _controller.totalAttemptsCount,
          duration: _controller.sessionDuration,
          onBackToMenu: widget.onFinish,
        ),
      );
    }

    final targets = _controller.targetItems;

    return Stack(
      children: [
        GameScaffold(
          title: 'Daily Market Stall',
          instruction: 'Question ${_controller.currentRoundNumber} of ${_controller.totalRounds}: ${_controller.promptText}',
          onPlayAudioPrompt: () {
            GameTtsService().speak(
              'Question ${_controller.currentRoundNumber} of ${_controller.totalRounds}. ${_controller.promptText}',
            );
          },
          onExitConfirmed: widget.onFinish,
          body: Column(
            children: [
              // Top Progress & Shopping Basket Banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
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
                    const Spacer(),
                    const Icon(
                      Icons.shopping_basket_rounded,
                      color: DementiaUX.primarySage,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Basket: ${_controller.collectedItemIds.length}/${targets.length}',
                      style: const TextStyle(
                        fontSize: DementiaUX.fontBody,
                        fontWeight: FontWeight.bold,
                        color: DementiaUX.textDark,
                      ),
                    ),
                    if (_controller.remainingTargetsCount == 0) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle,
                          color: DementiaUX.successGreen, size: 24),
                    ],
                  ],
                ),
              ),

              // Market Stall Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: _controller.marketStall.length,
                  itemBuilder: (context, index) {
                    final item = _controller.marketStall[index];
                    return _buildMarketCard(item);
                  },
                ),
              ),
            ],
          ),
        ),

        // Celebratory feedback overlay between rounds
        if (_controller.isRoundSuccess && !_controller.isSessionComplete)
          FeedbackOverlay(
            title: 'Shopping Done! (Bahut Bhal!)',
            subtitle: 'You collected all your market items perfectly.',
            onDismissed: () => _controller.nextRound(),
          ),
      ],
    );
  }
}
