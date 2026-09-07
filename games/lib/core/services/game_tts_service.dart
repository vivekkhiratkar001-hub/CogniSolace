import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Lightweight, dementia-accessible Text-to-Speech service for CogniSolace.
/// Designed for offline-first, browser/web safe speech with a gentle, slower pace.
class GameTtsService {
  static final GameTtsService _instance = GameTtsService._internal();
  factory GameTtsService() => _instance;
  GameTtsService._internal();

  FlutterTts? _tts;
  bool _isInitialized = false;
  final ValueNotifier<bool> isSpeaking = ValueNotifier<bool>(false);

  Future<void> _init() async {
    if (_isInitialized) return;
    try {
      _tts = FlutterTts();

      // Slower, clear pace appropriate for elderly dementia patients
      await _tts?.setLanguage('en-US');
      await _tts?.setSpeechRate(0.45);
      await _tts?.setVolume(1.0);
      await _tts?.setPitch(1.0);

      _tts?.setStartHandler(() {
        isSpeaking.value = true;
      });
      _tts?.setCompletionHandler(() {
        isSpeaking.value = false;
      });
      _tts?.setErrorHandler((dynamic _) {
        isSpeaking.value = false;
      });
      _tts?.setCancelHandler(() {
        isSpeaking.value = false;
      });

      _isInitialized = true;
    } catch (_) {
      // Graceful fallback if TTS is unsupported in current environment
      _tts = null;
      _isInitialized = true;
    }
  }

  /// Speaks the given instruction text safely without crashing if speech fails.
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await _init();
      if (_tts != null) {
        await _tts!.stop();
        await _tts!.speak(text);
      }
    } catch (_) {
      isSpeaking.value = false;
    }
  }

  /// Stops any ongoing speech immediately.
  Future<void> stop() async {
    try {
      if (_tts != null) {
        await _tts!.stop();
      }
    } catch (_) {}
    isSpeaking.value = false;
  }
}
