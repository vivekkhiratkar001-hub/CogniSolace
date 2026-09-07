import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../services/game_tts_service.dart';
import 'audio_prompt_button.dart';

/// Dementia-friendly wrapper layout for all cognitive games.
/// Provides accident-proof exit dialog, clear high-contrast header, and soothing background.
class GameScaffold extends StatelessWidget {
  final String title;
  final String? instruction;
  final VoidCallback? onPlayAudioPrompt;
  final Widget body;
  final VoidCallback? onExitConfirmed;

  const GameScaffold({
    super.key,
    required this.title,
    this.instruction,
    this.onPlayAudioPrompt,
    required this.body,
    this.onExitConfirmed,
  });

  Future<void> _handleBack(BuildContext context) async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DementiaUX.cardBorderRadius),
        ),
        title: const Text(
          'Take a Break?',
          style: TextStyle(
            fontSize: DementiaUX.fontTitle,
            fontWeight: FontWeight.bold,
            color: DementiaUX.textDark,
          ),
        ),
        content: const Text(
          'Would you like to stop playing or return to the main menu?',
          style: TextStyle(
            fontSize: DementiaUX.fontBody,
            color: DementiaUX.textMuted,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Stay Here',
              style: TextStyle(
                fontSize: DementiaUX.fontButton,
                color: DementiaUX.primaryNavy,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DementiaUX.primarySage,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Exit / Break',
              style: TextStyle(
                fontSize: DementiaUX.fontButton,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLeave == true) {
      GameTtsService().stop();
      if (onExitConfirmed != null) {
        onExitConfirmed!();
      } else if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: DementiaUX.backgroundWarm,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          toolbarHeight: 72,
          leading: IconButton(
            iconSize: 32,
            icon: const Icon(Icons.arrow_back_rounded, color: DementiaUX.textDark),
            tooltip: 'Back to Menu',
            onPressed: () => _handleBack(context),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: DementiaUX.fontTitle,
              fontWeight: FontWeight.bold,
              color: DementiaUX.textDark,
            ),
          ),
          actions: [
            if (onPlayAudioPrompt != null)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: AudioPromptButton(onPlay: onPlayAudioPrompt!),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (instruction != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  color: DementiaUX.primaryNavy.withValues(alpha: 0.06),
                  child: Text(
                    instruction!,
                    style: const TextStyle(
                      fontSize: DementiaUX.fontPrompt,
                      fontWeight: FontWeight.w600,
                      color: DementiaUX.textDark,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}
