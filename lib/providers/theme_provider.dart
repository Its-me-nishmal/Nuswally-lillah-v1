import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppAccentPalette {
  teal('Islamic Teal', Color(0xFF14B8A6)),
  emerald('Emerald Green', Color(0xFF10B981)),
  blue('Celestial Blue', Color(0xFF0C66E4)),
  amber('Royal Amber', Color(0xFFF59E0B)),
  purple('Amethyst', Color(0xFF8B5CF6));

  final String title;
  final Color color;

  const AppAccentPalette(this.title, this.color);
}

enum AppThemeStyle { teal, minimal, emerald, purple, crimson, ocean, dark, light }

class ThemeProvider with ChangeNotifier {
  static const String _spAccentKey = 'app_accent_palette_name';
  static const String _spDarkModeKey = 'is_app_dark_mode';
  static const String _spLangKey = 'app_language';

  AppAccentPalette _accent = AppAccentPalette.teal;
  bool _isDarkMode = true;
  String _appLanguage = 'en';

  AppAccentPalette get accent => _accent;
  AppThemeStyle get themeStyle => AppThemeStyle.values.firstWhere(
        (s) => s.name == _accent.name,
        orElse: () => AppThemeStyle.teal,
      );
  bool get isDarkMode => _isDarkMode;
  String get appLanguage => _appLanguage;
  bool get isMalayalam => _appLanguage == 'ml';

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _appLanguage = prefs.getString(_spLangKey) ?? 'en';
    _isDarkMode = prefs.getBool(_spDarkModeKey) ?? true;

    final savedAccent = prefs.getString(_spAccentKey);
    if (savedAccent != null) {
      try {
        _accent = AppAccentPalette.values.firstWhere(
          (a) => a.name == savedAccent,
          orElse: () => AppAccentPalette.teal,
        );
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> setAccent(AppAccentPalette newAccent) async {
    if (_accent == newAccent) return;
    _accent = newAccent;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_spAccentKey, newAccent.name);
  }

  Future<void> setThemeStyle(AppThemeStyle style) async {
    final matching = AppAccentPalette.values.firstWhere(
      (a) => a.name == style.name,
      orElse: () => AppAccentPalette.teal,
    );
    await setAccent(matching);
  }

  Future<void> toggleDarkMode() async {
    await setDarkMode(!_isDarkMode);
  }

  Future<void> setDarkMode(bool isDark) async {
    if (_isDarkMode == isDark) return;
    _isDarkMode = isDark;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_spDarkModeKey, isDark);
  }

  Future<void> setAppLanguage(String lang) async {
    if (_appLanguage == lang) return;
    _appLanguage = lang;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_spLangKey, lang);
  }

  // --- Dynamic Color Tokens ---
  Color get primaryAccent => _accent.color;
  Color get secondaryAccent => const Color(0xFF10B981);
  Color get tertiaryAccent => const Color(0xFFF59E0B);

  Color get backgroundTop =>
      _isDarkMode ? const Color(0xFF0B0E14) : const Color(0xFFF8FAFC);
  Color get backgroundBottom =>
      _isDarkMode ? const Color(0xFF080B10) : const Color(0xFFF1F5F9);
  Color get backgroundColor => backgroundTop;

  Color get surfaceColor =>
      _isDarkMode ? const Color(0xFF161B22) : const Color(0xFFFFFFFF);
  Color get containerColor =>
      _isDarkMode ? const Color(0xFF1F2633) : const Color(0xFFF1F5F9);

  Color get borderColor =>
      _isDarkMode ? const Color(0xFF30363D) : const Color(0xFFE2E8F0);
  Color get borderSubtle =>
      _isDarkMode ? const Color(0xFF21262D) : const Color(0xFFF1F5F9);

  Color get textPrimary =>
      _isDarkMode ? const Color(0xFFF0F6FC) : const Color(0xFF0F172A);
  Color get textSecondary =>
      _isDarkMode ? const Color(0xFF8B949E) : const Color(0xFF64748B);
  Color get textMuted =>
      _isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  Color get neutralColor => backgroundTop;
  Color get continueReadingBg => containerColor;
}
