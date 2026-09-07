import 'package:flutter/material.dart';

/// AppColors defines the central color palette for COGNISOLACE.
///
/// Designed specifically for elderly dementia patients:
/// - High contrast for aging eyes and visual clarity
/// - Calming, nature-inspired tones (North Eastern Tea Gardens & Forest tones)
/// - Prevents bright glare while avoiding somber dark schemes
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary Regional Brand Colors (North Eastern Tea Garden Greens)
  static const Color primary = Color(0xFF1B5E20); // Deep Forest / Tea Garden Green
  static const Color primaryLight = Color(0xFFE8F5E9); // Gentle light green for backgrounds/chips
  static const Color primaryDark = Color(0xFF003300);

  // Functional Screen Colors (High contrast, distinguishable)
  static const Color assistantBlue = Color(0xFF0277BD); // Soothing Sky/Water Blue for AI Companion
  static const Color assistantLight = Color(0xFFE1F5FE);

  static const Color reminderOrange = Color(0xFFD84315); // Warm Amber/Orange for daily routines & reminders
  static const Color reminderLight = Color(0xFFFBE9E7);

  static const Color progressPurple = Color(0xFF4527A0); // Royal Purple for positive reinforcement & progress
  static const Color progressLight = Color(0xFFEDE7F6);

  static const Color gamesTeal = Color(0xFF00695C); // Deep Teal for Cognitive Games
  static const Color gamesLight = Color(0xFFE0F2F1);

  // Background & Surface Colors (Glare-free, warm off-whites)
  static const Color background = Color(0xFFF7FAF7); // Soft calming off-white green
  static const Color surface = Colors.white; // Card and container surface
  static const Color surfaceMuted = Color(0xFFF1F5F2);

  // High-Contrast Typography Colors
  static const Color textPrimary = Color(0xFF1A2E22); // Deep green-slate (near black, highly legible)
  static const Color textSecondary = Color(0xFF37474F); // High-contrast slate grey for supporting text
  static const Color textLight = Colors.white; // Text on dark button surfaces

  // Feedback & State Colors
  static const Color success = Color(0xFF2E7D32); // Positive reinforcement green
  static const Color warning = Color(0xFFF57F17); // Cautionary amber
  static const Color cardBorder = Color(0xFFD6E2D8); // Subtle borders for tactile boundary clarity
}
