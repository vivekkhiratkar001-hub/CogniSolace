import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../services/game_tts_service.dart';

/// Prominent speaker button allowing the elderly user to easily replay the voice prompt.
class AudioPromptButton extends StatelessWidget {
  final VoidCallback onPlay;
  final bool? isPlaying;
  final String label;
  final String tooltip;

  const AudioPromptButton({
    super.key,
    required this.onPlay,
    this.isPlaying,
    this.label = 'Listen Instructions',
    this.tooltip = 'Listen to spoken instructions',
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GameTtsService().isSpeaking,
      builder: (context, speaking, child) {
        final active = isPlaying ?? speaking;

        return Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: onPlay,
            borderRadius: BorderRadius.circular(30),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: active
                    ? DementiaUX.accentAmber.withValues(alpha: 0.3)
                    : DementiaUX.accentAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: DementiaUX.accentAmber,
                  width: active ? 2.5 : 2.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    active ? Icons.volume_up : Icons.volume_up_outlined,
                    color: DementiaUX.accentAmber,
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: DementiaUX.fontBody,
                      fontWeight: FontWeight.bold,
                      color: DementiaUX.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
