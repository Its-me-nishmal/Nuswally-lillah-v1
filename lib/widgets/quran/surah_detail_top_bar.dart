import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/quran_model.dart';
import '../../providers/quran_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/jira_theme.dart';
import '../heartbeat_tap.dart';

enum QuranViewMode { mushaf, list }

class SurahDetailTopBar extends StatelessWidget {
  final Surah surah;
  final QuranViewMode viewMode;
  final ValueChanged<QuranViewMode> onViewModeChanged;
  final VoidCallback onOpenSettings;
  final bool isCollapsed;

  const SurahDetailTopBar({
    super.key,
    required this.surah,
    required this.viewMode,
    required this.onViewModeChanged,
    required this.onOpenSettings,
    this.isCollapsed = false,
  });

  int _calculateJuz(int surahNumber) {
    if (surahNumber == 1 || (surahNumber == 2 && surahNumber <= 141)) return 1;
    if (surahNumber == 2) return 2;
    if (surahNumber == 3) return 3;
    if (surahNumber == 4) return 4;
    if (surahNumber == 5) return 6;
    if (surahNumber == 18) return 15;
    if (surahNumber >= 78) return 30;
    return (surahNumber ~/ 4) + 1;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final quranProvider = context.watch<QuranProvider>();
    final isDark = themeProvider.isDarkMode;
    final isBookmarked = quranProvider.isBookmarked(surah.number);

    final surahTitle = surah.englishName.toUpperCase();
    final arabicTitle = surah.name.replaceAll('سُورَةُ ', '');
    final juzNum = _calculateJuz(surah.number);
    final isMushaf = viewMode == QuranViewMode.mushaf;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Circular Back Button (Always accessible)
          HeartbeatTap(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: themeProvider.surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: themeProvider.borderColor,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 17,
                  color: themeProvider.textPrimary,
                ),
              ),
            ),
          ),

          // 2. Surah Title & Metadata (Animates in / out on scroll)
          Expanded(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: isCollapsed ? 0.0 : 1.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        surahTitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• $arabicTitle',
                        style: TextStyle(
                          fontFamily: 'HafsFont',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFFC7D2FE) : JiraTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isMushaf
                        ? 'Juz $juzNum • Page ${surah.number * 2 + 1}'
                        : '${surah.numberOfAyahs} • $arabicTitle Verses',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w400,
                      color: themeProvider.textSecondary.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Right Actions: Mode Switcher + Typography + Bookmark
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: isCollapsed ? 0.0 : 1.0,
            child: IgnorePointer(
              ignoring: isCollapsed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Toggle between Continuous Mushaf Reading and Ayah List
                  HeartbeatTap(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onViewModeChanged(
                        isMushaf ? QuranViewMode.list : QuranViewMode.mushaf,
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isMushaf
                            ? const Color(0xFFA4C6FB)
                            : themeProvider.surfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isMushaf
                              ? const Color(0xFFA4C6FB)
                              : themeProvider.borderColor,
                          width: 1.0,
                        ),
                        boxShadow: isMushaf
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFA4C6FB).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Icon(
                          isMushaf
                              ? Icons.auto_stories_rounded
                              : Icons.format_list_bulleted_rounded,
                          size: 19,
                          color: isMushaf
                              ? const Color(0xFF0B0E14)
                              : themeProvider.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Typography "Tt" button
                  HeartbeatTap(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onOpenSettings();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: themeProvider.surfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: themeProvider.borderColor,
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Tt',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: themeProvider.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Bookmark Toggle Button
                  HeartbeatTap(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      quranProvider.toggleBookmark(surah.number);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: themeProvider.surfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: themeProvider.borderColor,
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          size: 19,
                          color: isBookmarked
                              ? JiraTheme.primaryBlue
                              : themeProvider.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
