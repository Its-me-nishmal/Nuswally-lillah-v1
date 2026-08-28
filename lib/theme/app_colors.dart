import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'home_design.dart';

/// Semantic colour tokens reachable from any `BuildContext`.
///
/// Screens used to hardcode hex values (and so only worked in dark mode). These
/// getters give every screen the same emerald-and-gold palette in both modes
/// without each one having to plumb a `ThemeProvider` through its helpers.
///
/// Reads use `listen: false` so they are safe to call outside `build`; screens
/// that need to repaint on a theme change already `watch<ThemeProvider>()` once
/// in their own `build`.
extension AppColors on BuildContext {
  ThemeProvider get _theme => Provider.of<ThemeProvider>(this, listen: false);

  bool get isDarkTheme => _theme.isDarkMode;

  /// Subscribes the calling widget to theme changes. Call once at the top of a
  /// `build` method so the screen repaints when dark/light is toggled.
  void watchTheme() => Provider.of<ThemeProvider>(this);

  // --- Canvas ---------------------------------------------------------
  Color get pageTop => HomeDesign.pageTop(isDarkTheme);
  Color get pageBottom => HomeDesign.pageBottom(isDarkTheme);

  // --- Card surfaces --------------------------------------------------
  Color get cardTop => HomeDesign.cardTop(isDarkTheme);
  Color get cardBottom => HomeDesign.cardBottom(isDarkTheme);
  LinearGradient get cardGradient => HomeDesign.cardGradient(isDarkTheme);

  // --- Lines ----------------------------------------------------------
  Color get cardBorder => HomeDesign.goldLine(isDarkTheme);
  Color get cardBorderStrong => HomeDesign.goldLineStrong(isDarkTheme);
  Color get hairline => HomeDesign.divider(isDarkTheme);

  // --- Text -----------------------------------------------------------
  Color get textPrimary => _theme.textPrimary;
  Color get textSecondary => _theme.textSecondary;
  Color get textMuted => _theme.textMuted;

  // --- Accent ---------------------------------------------------------
  Color get accent => _theme.primaryAccent;

  /// Accent darkened for text on light backgrounds (WCAG AA).
  Color get accentText => _theme.accentText;
  Color get accentSoft =>
      _theme.primaryAccent.withValues(alpha: isDarkTheme ? 0.13 : 0.11);
  Color get accentLine =>
      _theme.primaryAccent.withValues(alpha: isDarkTheme ? 0.26 : 0.30);

  // --- Gold -----------------------------------------------------------
  Color get gold => HomeDesign.gold;
  Color get goldText => HomeDesign.goldText(isDarkTheme);
  Color get goldWash => HomeDesign.goldWash(isDarkTheme);

  // --- Status ---------------------------------------------------------
  Color get danger =>
      isDarkTheme ? const Color(0xFFEF4444) : const Color(0xFFC62828);
  Color get success =>
      isDarkTheme ? const Color(0xFF22B96B) : const Color(0xFF15904F);

  // --- Elevation ------------------------------------------------------
  Color get cardShadow => HomeDesign.shadow(isDarkTheme);
}
