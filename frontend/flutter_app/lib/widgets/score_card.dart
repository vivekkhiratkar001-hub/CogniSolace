import 'package:flutter/material.dart';

/// A reusable, high-contrast score card widget for COGNISOLACE.
///
/// Designed specifically for elderly dementia patients:
/// - Displays an Icon, Title, and Value clearly
/// - Clean, uncluttered layout without overwhelming charts
/// - Large readable typography and rounded corners
/// - Reusable across the Progress Screen and game outcome screens
class ScoreCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? emoji;
  final String? description;
  final Color? accentColor;
  final bool isValueText;

  const ScoreCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.emoji,
    this.description,
    this.accentColor,
    this.isValueText = false,
  });

  @override
  Widget build(BuildContext context) {
    // Screen responsiveness: adjust padding and sizing for phone vs tablet
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // Default accent color is soothing forest green
    final effectiveAccentColor = accentColor ?? const Color(0xFF1B5E20);

    const Color textPrimary = Color(0xFF1A2E22);
    const Color textSecondary = Color(0xFF37474F);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: EdgeInsets.all(isTablet ? 22.0 : 18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.0),
        border: Border.all(
          color: effectiveAccentColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8.0,
            offset: const Offset(0, 3.0),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Large Circular Icon Avatar
          Container(
            width: isTablet ? 60.0 : 50.0,
            height: isTablet ? 60.0 : 50.0,
            decoration: BoxDecoration(
              color: effectiveAccentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                size: isTablet ? 32.0 : 26.0,
                color: effectiveAccentColor,
              ),
            ),
          ),

          const SizedBox(width: 16.0),

          // 2. Title & Optional Description Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  emoji != null ? '$emoji $title' : title,
                  style: TextStyle(
                    fontSize: isTablet ? 20.0 : 18.0,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                if (description != null && description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4.0),
                  Text(
                    description!,
                    style: TextStyle(
                      fontSize: isTablet ? 15.0 : 13.5,
                      color: textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12.0),

          // 3. High-Contrast Large Value Display
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 18.0 : 14.0,
              vertical: isTablet ? 10.0 : 8.0,
            ),
            decoration: BoxDecoration(
              color: effectiveAccentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: effectiveAccentColor.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: isValueText
                    ? (isTablet ? 18.0 : 16.0)
                    : (isTablet ? 26.0 : 22.0),
                fontWeight: FontWeight.w900,
                color: effectiveAccentColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
