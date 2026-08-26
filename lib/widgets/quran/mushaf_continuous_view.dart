import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/quran_model.dart';
import '../../providers/quran_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/quran_page_helper.dart';

class MushafContinuousView extends StatelessWidget {
  final Surah surah;
  final ScrollController scrollController;

  const MushafContinuousView({
    super.key,
    required this.surah,
    required this.scrollController,
  });

  String _toArabicDigits(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((c) {
      final val = int.tryParse(c);
      return val != null ? arabicDigits[val] : c;
    }).join();
  }

  Widget _buildPageSeparator(int page, int juz, bool isDark, ThemeProvider themeProvider) {
    final lineBorderColor = isDark ? const Color(0xFF2E3D4D) : const Color(0xFFCBD5E1);

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
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

    final arabicSurahName = surah.name.startsWith('سُورَةُ')
        ? surah.name
        : 'سُورَةُ ${surah.name}';

    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // Group ayahs by real Madani Mushaf page
    final Map<int, List<Ayah>> pageGroups = {};
    for (final ayah in quranProvider.ayahs) {
      final page = QuranPageHelper.getPage(surah.number, ayah.numberInSurah);
      pageGroups.putIfAbsent(page, () => []).add(ayah);
    }

    return SingleChildScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(18, topInset + 68, 18, bottomInset + 80),
      child: Column(
        children: [
          // 1. Surah Title
          Center(
            child: Text(
              arabicSurahName,
              style: TextStyle(
                fontFamily: 'HafsFont',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFE2E8F0) : themeProvider.primaryAccent,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Bismillah Header (Except Surah At-Tawbah #9)
          if (surah.number != 9) ...[
            Center(
              child: Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'HafsFont',
                  fontSize: 23,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFE2E8F0) : themeProvider.primaryAccent,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 3. Pages Rendered with Inline Madani Page Separators
          ...pageGroups.entries.map((entry) {
            final page = entry.key;
            final juz = QuranPageHelper.getJuzFromPage(page);
            final ayahsOnPage = entry.value;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Page Break Separator
                _buildPageSeparator(page, juz, isDark, themeProvider),

                // Continuous Arabic Text Block for this specific Page
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: RichText(
                    textAlign: TextAlign.justify,
                    text: TextSpan(
                      children: ayahsOnPage.map((ayah) {
                        final verseNumberArabic = _toArabicDigits(ayah.numberInSurah);
                        return TextSpan(
                          children: [
                            TextSpan(
                              text: '${ayah.text} ',
                              style: TextStyle(
                                fontFamily: 'HafsFont',
                                fontSize: quranProvider.fontSize,
                                color: isDark ? const Color(0xFFF0F6FC) : const Color(0xFF0F172A),
                                height: 2.2,
                                letterSpacing: 0.2,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  HapticFeedback.selectionClick();
                                },
                            ),
                            TextSpan(
                              text: ' ﴿$verseNumberArabic﴾ ',
                              style: TextStyle(
                                fontFamily: 'HafsFont',
                                fontSize: quranProvider.fontSize * 0.85,
                                fontWeight: FontWeight.bold,
                                color: themeProvider.primaryAccent,
                                height: 2.2,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
