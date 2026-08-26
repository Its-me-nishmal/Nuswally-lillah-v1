import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/jira_theme.dart';
import 'heartbeat_tap.dart';

/// Shared top app-bar style matching the Home screen header language.
///
/// - 36x36 flat back button (`8px` radius, `1px` border, surface color)
/// - Outfit font bold title with wide letter-spacing
/// - Optional 10px w600 subtitle (e.g. live Hijri date / step info)
/// - Optional trailing [actions] (e.g. `TelegramThemeToggle`, settings)
class JiraHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? leading;
  final List<Widget> actions;
  final bool centerTitle;
  final EdgeInsetsGeometry padding;

  const JiraHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.onBack,
    this.leading,
    this.actions = const [],
    this.centerTitle = false,
    this.padding = const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final surfaceColor = isDark ? JiraTheme.darkSurface : JiraTheme.lightSurface;
    final borderColor = isDark ? JiraTheme.darkBorder : JiraTheme.lightBorder;

    Widget backButton = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Center(
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: themeProvider.textPrimary,
        ),
      ),
    );

    Widget titleColumn = Column(
      crossAxisAlignment: centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: themeProvider.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: centerTitle ? TextAlign.center : TextAlign.start,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: themeProvider.textSecondary.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: centerTitle ? TextAlign.center : TextAlign.start,
          ),
        ],
      ],
    );

    final Widget leadingWidget;
    if (leading != null) {
      leadingWidget = leading!;
    } else if (showBack) {
      leadingWidget = HeartbeatTap(
        onTap: () {
          if (onBack != null) {
            onBack!();
          } else {
            Navigator.pop(context);
          }
        },
        child: backButton,
      );
    } else {
      leadingWidget = const SizedBox(width: 36, height: 36);
    }

    return Padding(
      padding: padding,
      child: Row(
        children: [
          leadingWidget,
          const SizedBox(width: 12),
          Expanded(child: titleColumn),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 8),
            ...actions,
          ],
        ],
      ),
    );
  }
}
