import 'package:flutter/material.dart';
import 'app_colors.dart';

/// AppTextStyles defines readable, high-contrast typography for elderly dementia patients.
///
/// Principles applied:
/// - Increased base font sizes (min 16-18sp for body, 22-30sp for headers)
/// - Strong font weights (bold/medium) to avoid thin, washed-out text
/// - Generous line heights (1.3 to 1.5) to avoid visual crowding
/// - High contrast colors against soft backgrounds
class AppTextStyles {
  AppTextStyles._(); // Private constructor

  // Screen Main Headings (Greeting, App title)
  static const TextStyle headingLarge = TextStyle(
    fontSize: 30.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
    height: 1.25,
  );

  // Section Headings & App Bar titles
  static const TextStyle headingMedium = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
    height: 1.3,
  );

  // Card Titles & Sub-headings
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // Large Button Main Labels
  static const TextStyle buttonLabel = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textLight,
    letterSpacing: 0.4,
  );

  // Large Button Subtitle / Helper hints
  static const TextStyle buttonSubtitle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: Color(0xFFE8F5E9),
    letterSpacing: 0.2,
  );

  // Primary Body Text (Instructions, dialogue messages)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  // Secondary Body Text (Timestamps, secondary details)
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  // Big Metric / Score Display
  static const TextStyle metricLarge = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.w900,
    color: AppColors.primary,
    letterSpacing: 0.5,
  );
}
