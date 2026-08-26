import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'heartbeat_tap.dart';

class ThemePaletteSheet extends StatelessWidget {
  const ThemePaletteSheet({super.key});

  static void show(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const ThemePaletteSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final isDark = tp.isDarkMode;

    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        math.max(MediaQuery.paddingOf(context).bottom + 22.0, 36.0),
      ),
      decoration: BoxDecoration(
        color: tp.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: tp.borderColor, width: 0.8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: tp.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Title Row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tp.primaryAccent.withValues(alpha: isDark ? 0.15 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(Icons.palette_rounded, color: tp.primaryAccent, size: 16),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Theme & Accent Colors',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: tp.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Personalize your Islamic app aesthetic across all screens',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: tp.textSecondary,
            ),
          ),
          const SizedBox(height: 18),

          // Dark / Light Mode Segmented Switcher
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: tp.containerColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tp.borderColor, width: 0.8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: HeartbeatTap(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      tp.setDarkMode(true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: isDark ? tp.surfaceColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isDark
                            ? Border.all(color: tp.borderColor, width: 0.8)
                            : null,
                        boxShadow: isDark
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.dark_mode_rounded,
                            size: 15,
                            color: isDark ? tp.primaryAccent : tp.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Dark Obsidian',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: isDark ? FontWeight.w700 : FontWeight.w500,
                              color: isDark ? tp.textPrimary : tp.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: HeartbeatTap(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      tp.setDarkMode(false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: !isDark ? tp.surfaceColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: !isDark
                            ? Border.all(color: tp.borderColor, width: 0.8)
                            : null,
                        boxShadow: !isDark
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.light_mode_rounded,
                            size: 15,
                            color: !isDark ? tp.primaryAccent : tp.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pure Light',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: !isDark ? FontWeight.w700 : FontWeight.w500,
                              color: !isDark ? tp.textPrimary : tp.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'Islamic Accent Palette:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: tp.textSecondary,
            ),
          ),
          const SizedBox(height: 10),

          // 6 Curated Color Palettes Grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.45,
            children: AppAccentPalette.values.map((palette) {
              final isSelected = tp.accent == palette;

              return HeartbeatTap(
                onTap: () {
                  HapticFeedback.selectionClick();
                  tp.setAccent(palette);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? palette.color.withValues(alpha: isDark ? 0.18 : 0.12)
                        : tp.containerColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? palette.color : tp.borderColor,
                      width: isSelected ? 1.5 : 0.8,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: palette.color.withValues(alpha: isDark ? 0.25 : 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              color: palette.color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: palette.color.withValues(alpha: 0.6),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: isSelected
                                ? const Center(
                                    child: Icon(Icons.check, size: 9, color: Colors.white),
                                  )
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        palette.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? palette.color : tp.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),

          // Apply & Done Button
          HeartbeatTap(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: tp.primaryAccent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: tp.primaryAccent.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Apply Theme',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
