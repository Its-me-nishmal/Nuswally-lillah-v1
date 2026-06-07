import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeStyle { teal, gold, emerald, purple, crimson, ocean }

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
      case 'gold':
        _themeStyle = AppThemeStyle.gold;
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
    switch (_themeStyle) {
      case AppThemeStyle.teal:
        return 'Oasis Teal';
      case AppThemeStyle.gold:
        return 'Royal Gold';
      case AppThemeStyle.emerald:
        return 'Emerald Deen';
      case AppThemeStyle.purple:
        return 'Mystic Purple';
      case AppThemeStyle.crimson:
        return 'Crimson Rose';
      case AppThemeStyle.ocean:
        return 'Ocean Breeze';
    }
  }

  // Dynamic Theme Colors
  Color get primaryAccent {
    switch (_themeStyle) {
      case AppThemeStyle.teal:
        return const Color(0xFF2DD4BF);
      case AppThemeStyle.gold:
        return const Color(0xFFF59E0B);
      case AppThemeStyle.emerald:
        return const Color(0xFF10B981);
      case AppThemeStyle.purple:
        return const Color(0xFFC084FC);
      case AppThemeStyle.crimson:
        return const Color(0xFFFB7185);
      case AppThemeStyle.ocean:
        return const Color(0xFF38BDF8);
    }
  }

  Color get backgroundTop {
    switch (_themeStyle) {
      case AppThemeStyle.teal:
        return const Color(0xFF07191C);
      case AppThemeStyle.gold:
        return const Color(0xFF161108);
      case AppThemeStyle.emerald:
        return const Color(0xFF051D14);
      case AppThemeStyle.purple:
        return const Color(0xFF150E22);
      case AppThemeStyle.crimson:
        return const Color(0xFF200B10);
      case AppThemeStyle.ocean:
        return const Color(0xFF0A1724);
    }
  }

  Color get backgroundBottom {
    switch (_themeStyle) {
      case AppThemeStyle.teal:
        return const Color(0xFF030D0F);
      case AppThemeStyle.gold:
        return const Color(0xFF0D0A04);
      case AppThemeStyle.emerald:
        return const Color(0xFF020E0A);
      case AppThemeStyle.purple:
        return const Color(0xFF0A0711);
      case AppThemeStyle.crimson:
        return const Color(0xFF100508);
      case AppThemeStyle.ocean:
        return const Color(0xFF050B12);
    }
  }

  Color get containerColor {
    switch (_themeStyle) {
      case AppThemeStyle.teal:
        return const Color(0xFF0C2529);
      case AppThemeStyle.gold:
        return const Color(0xFF221A0F);
      case AppThemeStyle.emerald:
        return const Color(0xFF0A2B1E);
      case AppThemeStyle.purple:
        return const Color(0xFF221637);
      case AppThemeStyle.crimson:
        return const Color(0xFF33111A);
      case AppThemeStyle.ocean:
        return const Color(0xFF10253B);
    }
  }

  Color get continueReadingBg {
    switch (_themeStyle) {
      case AppThemeStyle.teal:
        return const Color(0xFF144F4B);
      case AppThemeStyle.gold:
        return const Color(0xFF3F2F14);
      case AppThemeStyle.emerald:
        return const Color(0xFF0F4E36);
      case AppThemeStyle.purple:
        return const Color(0xFF3E236D);
      case AppThemeStyle.crimson:
        return const Color(0xFF5B1B2A);
      case AppThemeStyle.ocean:
        return const Color(0xFF193B61);
    }
  }
}
