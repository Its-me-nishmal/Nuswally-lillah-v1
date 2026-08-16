import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/jira_theme.dart';

enum AppThemeStyle { teal, minimal, emerald, purple, crimson, ocean, dark, light }

class ThemeProvider with ChangeNotifier {
  AppThemeStyle _themeStyle = AppThemeStyle.dark;
  String _appLanguage = 'en';

  bool get isDarkMode => true;
  AppThemeStyle get themeStyle => _themeStyle;
  String get themeName => 'Dark Mode';
  String get appLanguage => _appLanguage;
  bool get isMalayalam => _appLanguage == 'ml';

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _appLanguage = prefs.getString('app_language') ?? 'en';
    // Light mode toggling disabled for v1 - Obsidian Sanctuary is always dark
    // _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
    notifyListeners();
  }

  Future<void> setAppLanguage(String lang) async {
    if (_appLanguage == lang) return;
    _appLanguage = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang);
  }

  Future<void> toggleDarkMode() async {
    // Light mode disabled for v1 redesign - keep always dark
    /*
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    */
  }

  Future<void> toggleTheme() async {
    await toggleDarkMode();
  }

  Future<void> setDarkMode(bool isDark) async {
    // Light mode disabled for v1 redesign
  }

  Future<void> setThemeStyle(AppThemeStyle style) async {
    _themeStyle = style;
    notifyListeners();
  }

  // --- Dynamic Obsidian Sanctuary Tokens (Always Dark) ---
  Color get primaryAccent => JiraTheme.primaryBlue;
  Color get secondaryAccent => JiraTheme.secondaryGreen;
  Color get tertiaryAccent => JiraTheme.tertiaryOrange;
  Color get neutralColor => JiraTheme.darkBackground;

  Color get backgroundTop => JiraTheme.darkBackground;
  Color get backgroundBottom => JiraTheme.darkBackground;
  Color get backgroundColor => JiraTheme.darkBackground;
  Color get surfaceColor => JiraTheme.darkSurface;
  Color get containerColor => JiraTheme.darkContainer;
  Color get borderColor => JiraTheme.darkBorder;
  Color get borderSubtle => JiraTheme.darkBorderSubtle;
  Color get textPrimary => JiraTheme.darkTextPrimary;
  Color get textSecondary => JiraTheme.darkTextSecondary;
  Color get textMuted => JiraTheme.darkTextMuted;
  Color get continueReadingBg => JiraTheme.darkContainer;
}
