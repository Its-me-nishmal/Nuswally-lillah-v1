import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/quran_model.dart';
import '../../providers/quran_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/quran_page_helper.dart';
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final quranProvider = context.watch<QuranProvider>();
    final isDark = themeProvider.isDarkMode;
    final isBookmarked = quranProvider.isBookmarked(surah.number);

    final surahTitle = surah.englishName;
    final arabicTitle = surah.name.replaceAll('سُورَةُ ', '');
    final startPage = QuranPageHelper.getPage(surah.number, 1);
    final juzNum = QuranPageHelper.getJuzFromPage(startPage);
    final isMushaf = viewMode == QuranViewMode.mushaf;

    return Container(
      height: 56.0,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Permanent Floating Back Button (Always accessible)
          HeartbeatTap(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (isCollapsed
                    ? (isDark ? const Color(0xFF151D24) : Colors.white)
                    : themeProvider.surfaceColor).withValues(alpha: isCollapsed ? 0.90 : 1.0),
                shape: BoxShape.circle,
                border: Border.all(
                  color: themeProvider.borderColor.withValues(alpha: isCollapsed ? 0.8 : 0.5),
                  width: 0.8,
                ),
                boxShadow: isCollapsed
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: themeProvider.textPrimary,
                ),
              ),
            ),
          ),

          // 2. Surah Title & Metadata (Animates in / out on scroll)
          Expanded(
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOutCubic,
              offset: isCollapsed ? const Offset(0, -0.3) : Offset.zero,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                opacity: isCollapsed ? 0.0 : 1.0,
                child: IgnorePointer(
                  ignoring: isCollapsed,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            surahTitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: themeProvider.textPrimary,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• $arabicTitle',
                            style: TextStyle(
                              fontFamily: 'HafsFont',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFFE2E8F0) : themeProvider.primaryAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Juz $juzNum • Page $startPage • ${surah.numberOfAyahs} Verses',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: themeProvider.textSecondary.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Right Actions: Mode Switcher & Bookmark (Animates in / out on scroll)
          AnimatedSlide(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOutCubic,
            offset: isCollapsed ? const Offset(0, -0.3) : Offset.zero,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
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
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isMushaf
                              ? themeProvider.primaryAccent.withValues(alpha: isDark ? 0.15 : 0.12)
                              : themeProvider.surfaceColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isMushaf
                                ? themeProvider.primaryAccent.withValues(alpha: 0.35)
                                : themeProvider.borderColor,
                            width: 0.8,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            isMushaf ? Icons.format_list_bulleted_rounded : Icons.auto_stories_rounded,
                            size: 17,
                            color: isMushaf ? themeProvider.primaryAccent : themeProvider.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Bookmark Surah
                    HeartbeatTap(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        quranProvider.toggleBookmark(surah.number);
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isBookmarked
                              ? themeProvider.primaryAccent.withValues(alpha: isDark ? 0.15 : 0.12)
                              : themeProvider.surfaceColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isBookmarked
                                ? themeProvider.primaryAccent.withValues(alpha: 0.35)
                                : themeProvider.borderColor,
                            width: 0.8,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                            size: 17,
                            color: isBookmarked ? themeProvider.primaryAccent : themeProvider.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
