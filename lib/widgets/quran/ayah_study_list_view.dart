import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/quran_model.dart';
import '../../providers/quran_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/quran_page_helper.dart';
import '../heartbeat_tap.dart';

class AyahStudyListView extends StatelessWidget {
  final Surah surah;
  final ScrollController scrollController;
  static final Map<int, GlobalKey> ayahKeys = {};

  const AyahStudyListView({
    super.key,
    required this.surah,
    required this.scrollController,
  });

  void _copyAyah(BuildContext context, Ayah ayah) {
    Clipboard.setData(
      ClipboardData(
        text: '${ayah.text}\n\n— Surah ${surah.englishName} (${surah.number}:${ayah.numberInSurah})',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ayah ${ayah.numberInSurah} copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareAyah(BuildContext context, Ayah ayah) {
    Clipboard.setData(
      ClipboardData(
        text: '${ayah.text}\n\n— Surah ${surah.englishName} (${surah.number}:${ayah.numberInSurah})\nvia Nuswally Lillah',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ayah ${ayah.numberInSurah} copied for sharing'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildPillBadge(String text, bool isDark, Color bg, Color border, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildPageSeparator(int page, int juz, bool isDark, ThemeProvider themeProvider) {
    final lineBorderColor = isDark ? const Color(0xFF222D38) : const Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 20),
      child: Row(
        children: [
          // Left Line
          Expanded(
            child: Container(
              height: 1.0,
              color: lineBorderColor,
            ),
          ),

          // Center Page & Juz Indicator Pill
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151D24) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: lineBorderColor,
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 13,
                    color: themeProvider.primaryAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'PAGE $page',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: themeProvider.primaryAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '  •  JUZ $juz',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Line
          Expanded(
            child: Container(
              height: 1.0,
              color: lineBorderColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final quranProvider = context.watch<QuranProvider>();
    final isDark = themeProvider.isDarkMode;

    final containerColor = isDark ? const Color(0xFF151D24) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? const Color(0xFF222D38) : const Color(0xFFE2E8F0);

    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ListView.builder(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, topInset + 68, 16, bottomInset + 80),
      itemCount: quranProvider.ayahs.length + 1,
      itemBuilder: (context, index) {
        // Index 0: Hero Surah Header Card
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151D24) : const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor,
                width: 0.8,
              ),
            ),
            child: Column(
              children: [
                // Top Metadata Chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPillBadge(
                      'SURAH ${surah.number}',
                      isDark,
                      containerColor,
                      borderColor,
                      themeProvider.primaryAccent,
                    ),
                    const SizedBox(width: 8),
                    _buildPillBadge(
                      surah.revelationType.toUpperCase(),
                      isDark,
                      containerColor,
                      borderColor,
                      themeProvider.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    _buildPillBadge(
                      '${surah.numberOfAyahs} VERSES',
                      isDark,
                      containerColor,
                      borderColor,
                      themeProvider.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Centerpiece Bismillah
                if (surah.number != 9) ...[
                  Text(
                    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'HafsFont',
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFE2E8F0) : themeProvider.primaryAccent,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: themeProvider.textSecondary.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        // Ayah Row (index - 1)
        final ayahIndex = index - 1;
        final key = ayahKeys.putIfAbsent(ayahIndex, () => GlobalKey());
        final ayah = quranProvider.ayahs[ayahIndex];

        // Real Madani Page and Juz for this Ayah
        final int currentPage = QuranPageHelper.getPage(surah.number, ayah.numberInSurah);
        final int currentJuz = QuranPageHelper.getJuzFromPage(currentPage);

        // Check for Page Transition / Page Break
        bool showPageBreak = false;
        if (ayahIndex == 0) {
          showPageBreak = true;
        } else {
          final prevAyah = quranProvider.ayahs[ayahIndex - 1];
          final int prevPage = QuranPageHelper.getPage(surah.number, prevAyah.numberInSurah);
          if (prevPage != currentPage) {
            showPageBreak = true;
          }
        }

        return Column(
          key: key,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Inline Page Separator
            if (showPageBreak)
              _buildPageSeparator(currentPage, currentJuz, isDark, themeProvider),

            // Seamless Ayah Content (Clean, borderless, restful)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Utility Bar: Number Badge + Copy & Share
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Ayah Badge (e.g. "2:1")
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: themeProvider.primaryAccent.withValues(
                            alpha: isDark ? 0.10 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: themeProvider.primaryAccent.withValues(
                              alpha: isDark ? 0.22 : 0.30,
                            ),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '${surah.number}:${ayah.numberInSurah}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: themeProvider.primaryAccent,
                          ),
                        ),
                      ),

                      // Micro-actions Row (Bookmark + Copy + Share)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Bookmark
                          HeartbeatTap(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              quranProvider.toggleBookmark(surah.number);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.bookmark_outline_rounded,
                                size: 18,
                                color: themeProvider.textSecondary,
                              ),
                            ),
                          ),
                          // Copy
                          HeartbeatTap(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _copyAyah(context, ayah);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: themeProvider.textSecondary,
                              ),
                            ),
                          ),
                          // Share
                          HeartbeatTap(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _shareAyah(context, ayah);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.share_outlined,
                                size: 16,
                                color: themeProvider.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Arabic Text (Right Aligned, Large, Comfortable)
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      ayah.text,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'HafsFont',
                        fontSize: quranProvider.fontSize,
                        color: isDark ? const Color(0xFFF0F6FC) : const Color(0xFF0F172A),
                        height: 1.85,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),

                  // Translation (English & Malayalam)
                  if (ayah.translationEn.isNotEmpty || ayah.translationMl.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      themeProvider.isMalayalam && ayah.translationMl.isNotEmpty
                          ? ayah.translationMl
                          : ayah.translationEn,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: themeProvider.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Delicate Hairline Divider between Ayahs
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                height: 1.0,
                color: isDark ? const Color(0xFF1E2833) : const Color(0xFFE2E8F0),
              ),
            ),
          ],
        );
      },
    );
  }
}
