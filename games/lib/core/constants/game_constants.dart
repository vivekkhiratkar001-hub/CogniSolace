import 'package:flutter/material.dart';

/// Design constants tailored specifically for elderly dementia patients.
/// Principles:
/// 1. High contrast without harsh flashing
/// 2. Large touch targets (>= 56-64 dp) to accommodate tremors/motor decline
/// 3. Calming, non-threatening color palettes
/// 4. Generous spacing and large readable typography
abstract class DementiaUX {
  // Minimum touch targets (Material 3 recommends 48dp, elderly need >= 56dp)
  static const double minTouchTargetSize = 60.0;
  static const double largeButtonHeight = 64.0;
  static const double cardBorderRadius = 18.0;

  // Calming, accessible colors
  static const Color primaryNavy = Color(0xFF1E3A5F);       // Deep readable blue
  static const Color primarySage = Color(0xFF2E6F40);       // Natural calming green
  static const Color accentAmber = Color(0xFFD97706);       // Warm supportive amber
  static const Color backgroundWarm = Color(0xFFF9F6F0);    // Warm off-white, reduces eye strain
  static const Color surfaceCard = Color(0xFFFFFFFF);       // Clean card background
  static const Color textDark = Color(0xFF1F2937);          // High-contrast readable text (WCAG AAA)
  static const Color textMuted = Color(0xFF4B5563);         // Muted secondary text
  static const Color successGreen = Color(0xFF15803D);      // Positive reinforcement
  static const Color hintGlow = Color(0xFFFBBF24);          // Gentle warm guiding pulse

  // Font Sizes (Scalable for elderly users)
  static const double fontTitle = 26.0;
  static const double fontPrompt = 22.0;
  static const double fontBody = 18.0;
  static const double fontButton = 20.0;

  // Interaction timeouts
  static const Duration hintInactivityTimeout = Duration(seconds: 12);
  static const Duration feedbackDisplayDuration = Duration(milliseconds: 1800);
}
