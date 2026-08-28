import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/home_design.dart';

class ThemeProvider with ChangeNotifier {
  static const String _spDarkModeKey = 'is_app_dark_mode';
  static const String _spLangKey = 'app_language';
  static const String _spHijriOffsetKey = 'hijri_offset_days';

  bool _isDarkMode = true;
  String _appLanguage = 'en';
  int _hijriOffsetDays = 0;

  bool get isDarkMode => _isDarkMode;
  String get appLanguage => _appLanguage;
  bool get isMalayalam => _appLanguage == 'ml';

  /// Days to shift the arithmetic Hijri date by, so it can be lined up with
  /// the local moon sighting. Clamped to -2..+2.
  int get hijriOffsetDays => _hijriOffsetDays;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _appLanguage = prefs.getString(_spLangKey) ?? 'en';
    _isDarkMode = prefs.getBool(_spDarkModeKey) ?? true;
    _hijriOffsetDays = (prefs.getInt(_spHijriOffsetKey) ?? 0).clamp(-2, 2);
    notifyListeners();
  }

  Future<void> setHijriOffsetDays(int days) async {
    final clamped = days.clamp(-2, 2);
    if (_hijriOffsetDays == clamped) return;
    _hijriOffsetDays = clamped;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_spHijriOffsetKey, clamped);
  }

  /// Steps the offset through -2 → +2 and wraps back to -2.
  Future<void> cycleHijriOffsetDays() =>
      setHijriOffsetDays(_hijriOffsetDays >= 2 ? -2 : _hijriOffsetDays + 1);

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

  // --- Colour Tokens ---
  /// The app's single accent. Only dark/light is user-selectable.
  Color get primaryAccent => const Color(0xFF14B8A6);
  Color get secondaryAccent => const Color(0xFF10B981);
  Color get tertiaryAccent => const Color(0xFFF59E0B);

  /// Darkened accent for accent-coloured *text* on light backgrounds, where
  /// the bright accent would fail WCAG AA contrast.
  Color get primaryAccentOnLight => const Color(0xFF0F766E);

  /// Accent tuned for text in whichever mode is active.
  Color get accentText => _isDarkMode ? primaryAccent : primaryAccentOnLight;

  // These delegate to HomeDesign so the ~277 existing call sites across the
  // app pick up the emerald-and-gold palette without being rewritten.
  Color get backgroundTop => HomeDesign.pageTop(_isDarkMode);
  Color get backgroundBottom => HomeDesign.pageBottom(_isDarkMode);
  Color get backgroundColor => backgroundTop;

  Color get surfaceColor => HomeDesign.cardTop(_isDarkMode);
  Color get containerColor => HomeDesign.inset(_isDarkMode);

  Color get borderColor => HomeDesign.goldLine(_isDarkMode);
  Color get borderSubtle => HomeDesign.divider(_isDarkMode);

  Color get textPrimary =>
      _isDarkMode ? const Color(0xFFF0F6FC) : const Color(0xFF0F172A);
  Color get textSecondary =>
      _isDarkMode ? const Color(0xFF8FA0AF) : const Color(0xFF64748B);
  Color get textMuted =>
      _isDarkMode ? const Color(0xFF627280) : const Color(0xFF94A3B8);

  Color get neutralColor => backgroundTop;
  Color get continueReadingBg => containerColor;
}
