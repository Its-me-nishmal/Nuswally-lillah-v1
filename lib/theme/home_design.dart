import 'package:flutter/material.dart';

/// Design tokens for the "Emerald & Gold" home surface.
///
/// The home screen layers a warm gold hairline / accent language over the
/// existing deep charcoal-teal canvas. Every token has an explicit light-mode
/// value so the screen never borrows an unreadable dark colour on white.
class HomeDesign {
  const HomeDesign._();

  // --- Page canvas -----------------------------------------------------
  static Color pageTop(bool isDark) =>
      isDark ? const Color(0xFF07100D) : const Color(0xFFF6FAF8);
  static Color pageBottom(bool isDark) =>
      isDark ? const Color(0xFF040807) : const Color(0xFFEDF3F0);

  // --- Card surfaces (vertical gradient) -------------------------------
  static Color cardTop(bool isDark) =>
      isDark ? const Color(0xFF0E1A16) : const Color(0xFFFFFFFF);
  static Color cardBottom(bool isDark) =>
      isDark ? const Color(0xFF0A1310) : const Color(0xFFF8FBFA);

  static LinearGradient cardGradient(bool isDark) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardTop(isDark), cardBottom(isDark)],
  );

  /// Inset tone for chips, pills and wells — sits one step *above* [cardTop]
  /// so nested elements still read as raised.
  static Color inset(bool isDark) =>
      isDark ? const Color(0xFF152420) : const Color(0xFFF1F6F4);

  // --- Gold accent -----------------------------------------------------
  /// Gold used for fills, borders and icons (decorative — never small text).
  static const Color gold = Color(0xFFD9A94E);

  /// Gold safe for text: light mode drops to a darker tone so the label
  /// clears WCAG AA against white.
  static Color goldText(bool isDark) =>
      isDark ? const Color(0xFFE0B15C) : const Color(0xFF8A6314);

  static Color goldLine(bool isDark) =>
      gold.withValues(alpha: isDark ? 0.34 : 0.28);
  static Color goldLineStrong(bool isDark) =>
      gold.withValues(alpha: isDark ? 0.55 : 0.45);
  static Color goldWash(bool isDark) =>
      gold.withValues(alpha: isDark ? 0.10 : 0.09);

  // --- Hairlines & chrome ----------------------------------------------
  static Color divider(bool isDark) =>
      isDark ? const Color(0xFF16241F) : const Color(0xFFE8EEEB);

  /// Unlit progress-rail track. `divider` is too close to the card fill to
  /// read as a track, so the rail gets its own slightly lifted tone.
  static Color railIdle(bool isDark) =>
      isDark ? const Color(0xFF2C3D36) : const Color(0xFFD8E1DD);

  static Color navFill(bool isDark) =>
      isDark ? const Color(0xFF0B1512) : const Color(0xFFFFFFFF);

  static Color iconButtonFill(bool isDark) =>
      isDark ? const Color(0xFF0D1815) : const Color(0xFFFFFFFF);

  /// Solid green used for the "prayed" check nodes.
  static Color checkGreen(bool isDark) =>
      isDark ? const Color(0xFF22B96B) : const Color(0xFF15904F);

  static Color shadow(bool isDark) =>
      Colors.black.withValues(alpha: isDark ? 0.28 : 0.05);

  // --- Per-prayer identity ---------------------------------------------
  static const Map<String, Color> _prayerTint = {
    'Fajr': Color(0xFF3ECF8E),
    'Sunrise': Color(0xFFE5A83B),
    'Dhuhr': Color(0xFFE5A83B),
    'Asr': Color(0xFFF08A34),
    'Maghrib': Color(0xFFE85D3A),
    'Isha': Color(0xFF8B7BE8),
  };

  static const Map<String, IconData> _prayerIcon = {
    'Fajr': Icons.wb_twilight_rounded, // sun over the horizon
    'Sunrise': Icons.brightness_low_rounded,
    'Dhuhr': Icons.wb_sunny_rounded, // sun at its height
    'Asr': Icons.wb_sunny_outlined, // weakening sun
    'Maghrib': Icons.nights_stay_rounded, // dusk
    'Isha': Icons.bedtime_rounded, // night
  };

  static Color prayerTint(String prayer) =>
      _prayerTint[prayer] ?? const Color(0xFF3ECF8E);

  static IconData prayerIcon(String prayer) =>
      _prayerIcon[prayer] ?? Icons.access_time_rounded;

  /// Short contextual line shown under the next prayer's name. Kept tight —
  /// it shares a row with the proximity label on 360dp-wide screens.
  static String prayerTagline(String prayer) {
    switch (prayer) {
      case 'Fajr':
        return 'Start your day right';
      case 'Sunrise':
        return 'Duha prayer time';
      case 'Dhuhr':
        return 'Pause at midday';
      case 'Asr':
        return 'Afternoon dhikr';
      case 'Maghrib':
        return 'Sunset prayer';
      case 'Isha':
        return 'Close your day';
      default:
        return 'Keep to your prayers';
    }
  }
}
