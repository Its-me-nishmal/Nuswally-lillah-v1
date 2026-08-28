import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum JiraBadgeVariant { primary, success, warning, neutral }

class JiraBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final JiraBadgeVariant variant;

  const JiraBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = JiraBadgeVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    context.watchTheme();

    Color bgColor;
    Color textColor;

    switch (variant) {
      case JiraBadgeVariant.primary:
        bgColor = context.accentSoft;
        textColor = context.accent;
        break;
      case JiraBadgeVariant.success:
        bgColor = context.accentSoft;
        textColor = context.accent;
        break;
      case JiraBadgeVariant.warning:
        bgColor = context.goldWash;
        textColor = context.gold;
        break;
      case JiraBadgeVariant.neutral:
        bgColor = context.cardBottom;
        textColor = context.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.15)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: textColor),
              const SizedBox(width: 4),
            ],
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: textColor,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
