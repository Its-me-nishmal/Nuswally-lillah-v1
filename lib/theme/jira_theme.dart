import 'package:flutter/material.dart';

/// Obsidian Sanctuary Design System Tokens & Color Strategy
class JiraTheme {
  // Brand Name: Obsidian Sanctuary

  // 1. Primary Tones: Restful Islamic Teal (#14B8A6 / #0D9488)
  static const Color primaryBlue = Color(0xFF14B8A6);
  static const Color primary = Color(0xFF14B8A6);
  static const Color primaryHover = Color(0xFF0D9488);
  static const Color primaryBlueBgDark = Color(0xFF0F2624);
  static const Color primaryBlueBgLight = Color(0xFFE6FFFA);

  // Primary Color Swatch Ramp
  static const Color primary50 = Color(0xFFE6FFFA);
  static const Color primary100 = Color(0xFFB2F5EA);
  static const Color primary200 = Color(0xFF81E6D9);
  static const Color primary300 = Color(0xFF4FD1C5);
  static const Color primary400 = Color(0xFF2DD4BF);
  static const Color primary500 = Color(0xFF14B8A6);
  static const Color primary600 = Color(0xFF0D9488);
  static const Color primary700 = Color(0xFF0F766E);
  static const Color primary800 = Color(0xFF115E59);
  static const Color primary900 = Color(0xFF134E4A);

  // 2. Secondary Tones (Emerald / Sage)
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryGreen = Color(0xFF10B981);
  static const Color secondaryGreenBgDark = Color(0xFF0D281E);
  static const Color secondaryGreenBgLight = Color(0xFFD1FAE5);

  // Secondary Color Swatch Ramp
  static const Color secondary50 = Color(0xFFECFDF5);
  static const Color secondary100 = Color(0xFFD1FAE5);
  static const Color secondary200 = Color(0xFFA7F3D0);
  static const Color secondary300 = Color(0xFF6EE7B7);
  static const Color secondary400 = Color(0xFF34D399);
  static const Color secondary500 = Color(0xFF10B981);
  static const Color secondary600 = Color(0xFF059669);
  static const Color secondary700 = Color(0xFF047857);
  static const Color secondary800 = Color(0xFF065F46);
  static const Color secondary900 = Color(0xFF064E3B);

  // 3. Tertiary Accent (Warm Amber / Gold)
  static const Color tertiary = Color(0xFFF59E0B);
  static const Color tertiaryOrange = Color(0xFFF59E0B);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color warningOrangeBgDark = Color(0xFF3B2A10);
  static const Color warningOrangeBgLight = Color(0xFFFEF3C7);

  // Tertiary Color Swatch Ramp
  static const Color tertiary50 = Color(0xFFFFF4ED);
  static const Color tertiary100 = Color(0xFFFFE5D3);
  static const Color tertiary200 = Color(0xFFFFC6A4);
  static const Color tertiary300 = Color(0xFFFFA06E);
  static const Color tertiary400 = Color(0xFFE56012);
  static const Color tertiary500 = Color(0xFFBD4600);
  static const Color tertiary600 = Color(0xFF993800);
  static const Color tertiary700 = Color(0xFF752B00);
  static const Color tertiary800 = Color(0xFF521E00);
  static const Color tertiary900 = Color(0xFF331300);

  // 4. Restful Matte Charcoal-Teal Dark Tokens
  static const Color neutral = Color(0xFF0E1418);
  static const Color darkBackground = Color(0xFF0E1418);
  static const Color darkSurface = Color(0xFF151D24);
  static const Color darkContainer = Color(0xFF1A242C);
  static const Color darkBorder = Color(0xFF232E38);
  static const Color darkBorderSubtle = Color(0xFF1B242D);
  static const Color darkTextPrimary = Color(0xFFE6ECF2);
  static const Color darkTextSecondary = Color(0xFF8FA0AF);
  static const Color darkTextMuted = Color(0xFF627280);

  // Neutral Color Swatch Ramp
  static const Color neutral950 = Color(0xFF0B0E14);
  static const Color neutral900 = Color(0xFF141920);
  static const Color neutral850 = Color(0xFF1B222C);
  static const Color neutral800 = Color(0xFF262C36);
  static const Color neutral700 = Color(0xFF1C222B);
  static const Color neutral600 = Color(0xFF484F58);
  static const Color neutral500 = Color(0xFF6E7681);
  static const Color neutral400 = Color(0xFF8B949E);
  static const Color neutral300 = Color(0xFFB1BAC4);
  static const Color neutral200 = Color(0xFFD0D7DE);
  static const Color neutral100 = Color(0xFFE2E8F0);
  static const Color neutral50 = Color(0xFFF7F8FA);
  static const Color neutral0 = Color(0xFFF0F6FC);

  // Light Mode Tokens
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightContainer = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderSubtle = Color(0xFFEDF2F7);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF64748B);

  // Info & Status Tones
  static const Color infoBlue = Color(0xFF0C66E4);
  static const Color infoBlueBgDark = Color(0xFF152540);
  static const Color infoBlueBgLight = Color(0xFFE0F2FE);

  static const Color errorRed = Color(0xFFEF4444);
  static const Color errorRedBgDark = Color(0xFF3B1219);
  static const Color errorRedBgLight = Color(0xFFFEE2E2);

  // Radius Hierarchy
  static const double radiusSmall = 6.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusCard = 12.0;
  static const double radiusHero = 16.0;
  static const double radiusPill = 28.0;

  // Elevation
  static const double zeroElevation = 0.0;
}

/// Alias for the Obsidian Sanctuary design system
typedef ObsidianTheme = JiraTheme;
