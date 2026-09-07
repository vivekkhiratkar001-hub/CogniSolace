import 'package:flutter/material.dart';
import '../constants/game_constants.dart';

/// Gentle, non-startling celebratory overlay shown when an action is successful.
/// Avoids loud bells, flashing strobes, or overwhelming particles.
class FeedbackOverlay extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onDismissed;

  const FeedbackOverlay({
    super.key,
    this.title = 'Well Done! (Bhal Hoise!)',
    this.subtitle = 'You remembered so well.',
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.4),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(DementiaUX.cardBorderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: DementiaUX.successGreen.withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
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
                          Icons.check_circle_rounded,
                          color: DementiaUX.successGreen,
                          size: 54,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: DementiaUX.fontTitle,
                          fontWeight: FontWeight.bold,
                          color: DementiaUX.textDark,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: DementiaUX.fontBody,
                            color: DementiaUX.textMuted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DementiaUX.primarySage,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onDismissed,
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: DementiaUX.fontButton,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
