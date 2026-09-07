import 'package:flutter/material.dart';

/// A reusable, large, high-contrast button widget for COGNISOLACE.
///
/// Designed specifically for elderly dementia patients:
/// - Minimum height around 80+ pixels for easy, tremor-friendly tap targets
/// - Full width for balanced screen layout on mobile and tablet
/// - Large high-contrast icon in a circular badge
/// - Bold, legible typography with optional explanatory subtitle
/// - Reusable across the Home Screen and other activity screens
class LargeButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color textColor;

  const LargeButton({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onPressed,
    this.backgroundColor,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    // Screen responsiveness: adjust sizing for mobile vs tablet
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // Default to calming forest green if no background color is supplied
    final effectiveBackgroundColor = backgroundColor ?? const Color(0xFF1B5E20);

    return Container(
      width: double.infinity, // Full width requirement
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Material(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(22.0),
        elevation: 3.5,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: BorderRadius.circular(22.0),
          onTap: onPressed,
          child: Container(
            constraints: BoxConstraints(
              minHeight: isTablet ? 96.0 : 84.0, // Minimum height around 80+ pixels
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24.0 : 18.0,
              vertical: 16.0,
            ),
            child: Row(
              children: [
                // 1. Large Circular Icon Container
                Container(
                  width: isTablet ? 60.0 : 52.0,
                  height: isTablet ? 60.0 : 52.0,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: isTablet ? 36.0 : 30.0,
                      color: textColor,
                    ),
                  ),
                ),

                const SizedBox(width: 18.0),

                // 2. Large Readable Text: Title and Optional Subtitle
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isTablet ? 24.0 : 21.0,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                      // Optional Subtitle
                      if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4.0),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: isTablet ? 16.5 : 14.5,
                            fontWeight: FontWeight.w500,
                            color: textColor.withValues(alpha: 0.92),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8.0),

                // 3. Directional Arrow Indicator
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: isTablet ? 26.0 : 22.0,
                  color: textColor.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
