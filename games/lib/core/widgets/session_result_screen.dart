import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import 'dementia_button.dart';

/// Reusable, dementia-friendly session summary screen for all CogniSolace cognitive games.
/// Presents reassuring, non-stigmatizing performance statistics without medical claims.
class SessionResultScreen extends StatelessWidget {
  final String title;
  final int totalQuestions;
  final int correctAnswers;
  final double accuracy;
  final int totalAttempts;
  final int? hintsUsed;
  final Duration duration;
  final String encouragingMessage;
  final VoidCallback onBackToMenu;

  const SessionResultScreen({
    super.key,
    required this.title,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.accuracy,
    required this.totalAttempts,
    this.hintsUsed,
    required this.duration,
    this.encouragingMessage = 'Wonderful effort! Every day is a new step forward.',
    required this.onBackToMenu,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes min $seconds sec';
    }
    return '$seconds sec';
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
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: DementiaUX.primaryNavy.withValues(alpha: 0.15),
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
                'You completed $totalQuestions questions.',
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
              _buildStatRow('Correct Answers', '$correctAnswers / $totalQuestions'),
              const SizedBox(height: 12),
              _buildStatRow('Accuracy', '${(accuracy * 100).round()}%'),
              const SizedBox(height: 12),
              _buildStatRow('Total Attempts', '$totalAttempts'),
              if (hintsUsed != null) ...[
                const SizedBox(height: 12),
                _buildStatRow('Hints Used', '$hintsUsed'),
              ],
              const SizedBox(height: 12),
              _buildStatRow('Time', _formatDuration(duration)),

              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: DementiaUX.primaryNavy.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  encouragingMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
                onPressed: onBackToMenu,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
