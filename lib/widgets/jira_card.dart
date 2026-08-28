import 'package:flutter/material.dart';
import '../theme/jira_theme.dart';
import '../theme/app_colors.dart';

class JiraCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final bool selected;

  const JiraCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = JiraTheme.radiusMedium,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    context.watchTheme();

    final defaultBg = selected ? (context.cardBottom) : (context.cardTop);

    final defaultBorder = selected ? context.accent : (context.cardBorder);

    final effectiveBg = backgroundColor ?? defaultBg;
    final effectiveBorder = borderColor ?? defaultBorder;

    Widget cardChild = Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: effectiveBorder, width: selected ? 1.5 : 1.0),
      ),
      child: child,
    );

    if (margin != null) {
      cardChild = Padding(padding: margin!, child: cardChild);
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardChild,
        ),
      );
    }

    return cardChild;
  }
}
