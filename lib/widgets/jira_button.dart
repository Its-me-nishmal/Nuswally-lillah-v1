import 'package:flutter/material.dart';
import '../theme/jira_theme.dart';
import '../theme/app_colors.dart';

enum JiraButtonType { primary, secondary, outline, ghost }

enum JiraButtonSize { small, medium, large }

class JiraButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final JiraButtonType type;
  final JiraButtonSize size;
  final IconData? icon;
  final bool fullWidth;
  final bool isLoading;

  const JiraButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = JiraButtonType.primary,
    this.size = JiraButtonSize.medium,
    this.icon,
    this.fullWidth = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    context.watchTheme();

    // Padding specs
    EdgeInsets padding;
    double fontSize;
    double iconSize;
    double height;

    switch (size) {
      case JiraButtonSize.small:
        padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
        fontSize = 12;
        iconSize = 14;
        height = 32;
        break;
      case JiraButtonSize.medium:
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
        fontSize = 13.5;
        iconSize = 16;
        height = 40;
        break;
      case JiraButtonSize.large:
        padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
        fontSize = 15;
        iconSize = 18;
        height = 48;
        break;
    }

    // Color definitions
    Color bgColor;
    Color fgColor;
    BorderSide borderSide = BorderSide.none;

    switch (type) {
      case JiraButtonType.primary:
        bgColor = context.accent;
        fgColor = Colors.white;
        break;
      case JiraButtonType.secondary:
        bgColor = context.cardBottom;
        fgColor = context.textPrimary;
        borderSide = BorderSide(color: context.cardBorder, width: 1);
        break;
      case JiraButtonType.outline:
        bgColor = Colors.transparent;
        fgColor = context.textPrimary;
        borderSide = BorderSide(color: context.cardBorder, width: 1);
        break;
      case JiraButtonType.ghost:
        bgColor = Colors.transparent;
        fgColor = context.textSecondary;
        break;
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: iconSize, color: fgColor),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: fgColor,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );

    Widget buttonWidget = SizedBox(
      height: height,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(JiraTheme.radiusMedium),
        elevation: 0,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(JiraTheme.radiusMedium),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(JiraTheme.radiusMedium),
              border: borderSide != BorderSide.none
                  ? Border.fromBorderSide(borderSide)
                  : null,
            ),
            child: content,
          ),
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: buttonWidget);
    }

    return buttonWidget;
  }
}
