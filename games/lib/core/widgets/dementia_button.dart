import 'package:flutter/material.dart';
import '../constants/game_constants.dart';

/// A dementia-accessible large-format button with clear contrast,
/// minimum 60dp touch target, and high tactile visual feedback.
class DementiaButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final bool isHighlighted;

  const DementiaButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.backgroundColor = DementiaUX.primaryNavy,
    this.textColor = Colors.white,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: DementiaUX.largeButtonHeight,
      constraints: const BoxConstraints(minWidth: 160),
      decoration: BoxDecoration(
        color: onPressed == null ? Colors.grey.shade300 : backgroundColor,
        borderRadius: BorderRadius.circular(DementiaUX.cardBorderRadius),
        border: isHighlighted
            ? Border.all(color: DementiaUX.hintGlow, width: 4.0)
            : null,
        boxShadow: [
          BoxShadow(
            color: (isHighlighted ? DementiaUX.hintGlow : Colors.black)
                .withValues(alpha: 0.18),
            blurRadius: isHighlighted ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DementiaUX.cardBorderRadius),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 28, color: textColor),
                  const SizedBox(width: 12),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: DementiaUX.fontButton,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
