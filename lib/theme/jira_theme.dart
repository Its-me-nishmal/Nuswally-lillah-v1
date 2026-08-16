import 'package:flutter/material.dart';

/// Obsidian Sanctuary Design System Tokens & Color Strategy
class JiraTheme {
  // Brand Name: Obsidian Sanctuary

  // 1. Primary Tones (#0C66E4) - Electric Jira Blue
  static const Color primaryBlue = Color(0xFF0C66E4);
  static const Color primary = Color(0xFF0C66E4);
  static const Color primaryHover = Color(0xFF0052CC);
  static const Color primaryLightTint = Color(0xFFE9F2FF);
  static const Color primaryDarkTint = Color(0xFF1C2B42);

  // Primary Color Swatch Ramp
  static const Color primary50 = Color(0xFFF0F6FE);
  static const Color primary100 = Color(0xFFD6E6FD);
  static const Color primary200 = Color(0xFFAECDFC);
  static const Color primary300 = Color(0xFF7CB0FA);
  static const Color primary400 = Color(0xFF468DF0);
  static const Color primary500 = Color(0xFF0C66E4);
  static const Color primary600 = Color(0xFF0052CC);
  static const Color primary700 = Color(0xFF0747A6);
  static const Color primary800 = Color(0xFF052B66);
  static const Color primary900 = Color(0xFF031633);

  // 2. Secondary Tones (#10B981) - Emerald Green
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryGreen = Color(0xFF10B981);
  static const Color successGreen = Color(0xFF10B981);
  static const Color successGreenBgDark = Color(0xFF064E3B);
  static const Color successGreenBgLight = Color(0xFFD1FAE5);

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

  // 3. Tertiary Tones (#BD4600) - Vibrant Rust / Warm Amber
  static const Color tertiary = Color(0xFFBD4600);
  static const Color tertiaryOrange = Color(0xFFBD4600);
  static const Color warningOrange = Color(0xFFBD4600);
  static const Color warningOrangeBgDark = Color(0xFF331300);
  static const Color warningOrangeBgLight = Color(0xFFFFE5D3);

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

  // 4. Neutral Tones (#0B0E14) - Obsidian Midnight
  static const Color neutral = Color(0xFF0B0E14);
  static const Color darkBackground = Color(0xFF0B0E14);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkContainer = Color(0xFF1F242C);
  static const Color darkBorder = Color(0xFF30363D);
  static const Color darkBorderSubtle = Color(0xFF21262D);
  static const Color darkTextPrimary = Color(0xFFF0F6FC);
  static const Color darkTextSecondary = Color(0xFF8B949E);
  static const Color darkTextMuted = Color(0xFF6E7681);

  // Neutral Color Swatch Ramp
  static const Color neutral950 = Color(0xFF0B0E14);
  static const Color neutral900 = Color(0xFF161B22);
  static const Color neutral850 = Color(0xFF1F242C);
  static const Color neutral800 = Color(0xFF30363D);
  static const Color neutral700 = Color(0xFF21262D);
  static const Color neutral600 = Color(0xFF484F58);
  static const Color neutral500 = Color(0xFF6E7681);
  static const Color neutral400 = Color(0xFF8B949E);
  static const Color neutral300 = Color(0xFFB1BAC4);
  static const Color neutral200 = Color(0xFFD0D7DE);
  static const Color neutral100 = Color(0xFFE2E8F0);
  static const Color neutral50 = Color(0xFFF7F8FA);
  static const Color neutral0 = Color(0xFFF0F6FC);

  // Light Mode Tokens
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightContainer = Color(0xFFF1F3F5);
  static const Color lightBorder = Color(0xFFD0D7DE);
  static const Color lightBorderSubtle = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF172B4D);
  static const Color lightTextSecondary = Color(0xFF44546F);
  static const Color lightTextMuted = Color(0xFF626F86);

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
