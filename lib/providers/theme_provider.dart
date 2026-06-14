import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeStyle { teal, minimal, emerald, purple, crimson, ocean }

class ThemeProvider with ChangeNotifier {
  AppThemeStyle _themeStyle = AppThemeStyle.teal;

  AppThemeStyle get themeStyle => _themeStyle;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_theme_style') ?? 'teal';
    switch (saved) {
      case 'minimal':
        _themeStyle = AppThemeStyle.minimal;
        break;
      case 'emerald':
        _themeStyle = AppThemeStyle.emerald;
        break;
      case 'purple':
        _themeStyle = AppThemeStyle.purple;
        break;
      case 'crimson':
        _themeStyle = AppThemeStyle.crimson;
        break;
      case 'ocean':
        _themeStyle = AppThemeStyle.ocean;
        break;
      default:
        _themeStyle = AppThemeStyle.teal;
    }
    notifyListeners();
  }

  Future<void> setThemeStyle(AppThemeStyle style) async {
    _themeStyle = style;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme_style', style.name);
  }

  Future<void> toggleTheme() async {
    // Cycles through all available premium themes
    final nextIndex = (_themeStyle.index + 1) % AppThemeStyle.values.length;
    await setThemeStyle(AppThemeStyle.values[nextIndex]);
  }

  String get themeName {
    final style = _themeStyle;
    if (style == AppThemeStyle.teal) return 'Oasis Teal';
    if (style == AppThemeStyle.minimal) return 'Pure Minimal';
    if (style == AppThemeStyle.emerald) return 'Emerald Deen';
    if (style == AppThemeStyle.purple) return 'Mystic Purple';
    if (style == AppThemeStyle.crimson) return 'Crimson Rose';
    if (style == AppThemeStyle.ocean) return 'Ocean Breeze';
    return 'Oasis Teal';
  }

  // Dynamic Theme Colors
  Color get primaryAccent {
    final style = _themeStyle;
    if (style == AppThemeStyle.teal) return const Color(0xFF2DD4BF);
    if (style == AppThemeStyle.minimal) return const Color(0xFFF8FAFC); // Clean crisp off-white
    if (style == AppThemeStyle.emerald) return const Color(0xFF10B981);
    if (style == AppThemeStyle.purple) return const Color(0xFFC084FC);
    if (style == AppThemeStyle.crimson) return const Color(0xFFFB7185);
    if (style == AppThemeStyle.ocean) return const Color(0xFF38BDF8);
    return const Color(0xFF2DD4BF);
  }

  Color get backgroundTop {
    final style = _themeStyle;
    if (style == AppThemeStyle.teal) return const Color(0xFF07191C);
    if (style == AppThemeStyle.minimal) return const Color(0xFF0F172A); // Sleek slate dark
    if (style == AppThemeStyle.emerald) return const Color(0xFF051D14);
    if (style == AppThemeStyle.purple) return const Color(0xFF150E22);
    if (style == AppThemeStyle.crimson) return const Color(0xFF200B10);
    if (style == AppThemeStyle.ocean) return const Color(0xFF0A1724);
    return const Color(0xFF07191C);
  }

  Color get backgroundBottom {
    final style = _themeStyle;
    if (style == AppThemeStyle.teal) return const Color(0xFF030D0F);
    if (style == AppThemeStyle.minimal) return const Color(0xFF020617); // Slate deep dark
    if (style == AppThemeStyle.emerald) return const Color(0xFF020E0A);
    if (style == AppThemeStyle.purple) return const Color(0xFF0A0711);
    if (style == AppThemeStyle.crimson) return const Color(0xFF100508);
    if (style == AppThemeStyle.ocean) return const Color(0xFF050B12);
    return const Color(0xFF030D0F);
  }

  Color get containerColor {
    final style = _themeStyle;
    if (style == AppThemeStyle.teal) return const Color(0xFF0C2529);
    if (style == AppThemeStyle.minimal) return const Color(0xFF1E293B); // Slate gray container
    if (style == AppThemeStyle.emerald) return const Color(0xFF0A2B1E);
    if (style == AppThemeStyle.purple) return const Color(0xFF221637);
    if (style == AppThemeStyle.crimson) return const Color(0xFF33111A);
    if (style == AppThemeStyle.ocean) return const Color(0xFF10253B);
    return const Color(0xFF0C2529);
  }

  Color get continueReadingBg {
    final style = _themeStyle;
    if (style == AppThemeStyle.teal) return const Color(0xFF144F4B);
    if (style == AppThemeStyle.minimal) return const Color(0xFF334155); // Muted slate gray
    if (style == AppThemeStyle.emerald) return const Color(0xFF0F4E36);
    if (style == AppThemeStyle.purple) return const Color(0xFF3E236D);
    if (style == AppThemeStyle.crimson) return const Color(0xFF5B1B2A);
    if (style == AppThemeStyle.ocean) return const Color(0xFF193B61);
    return const Color(0xFF144F4B);
  }
}
