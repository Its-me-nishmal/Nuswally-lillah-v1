import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/quran_model.dart';
import '../../providers/quran_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/jira_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final quranProvider = context.watch<QuranProvider>();
    final isDark = themeProvider.isDarkMode;

    final surfaceColor = isDark ? JiraTheme.darkSurface : JiraTheme.lightSurface;
    final borderColor = isDark ? JiraTheme.darkBorder : JiraTheme.lightBorder;

    final arabicSurahName = surah.name.startsWith('سُورَةُ')
        ? surah.name
        : 'سُورَةُ ${surah.name}';

    return SingleChildScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 140),
      child: Column(
        children: [
          // 1. Surah Name Ornamental Capsule Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor.withValues(alpha: isDark ? 0.6 : 0.9),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                arabicSurahName,
                style: const TextStyle(
                  fontFamily: 'HafsFont',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC7D2FE),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. Bismillah Header (Except Surah At-Tawbah #9)
          if (surah.number != 9) ...[
            const Center(
              child: Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'HafsFont',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE2E8F0),
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 3. Ultra-High Performance Continuous Mushaf Text (0 WidgetSpans)
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text.rich(
              textAlign: TextAlign.justify,
              TextSpan(
                children: List.generate(quranProvider.ayahs.length, (index) {
                  final ayah = quranProvider.ayahs[index];
                  final isPlaying = quranProvider.currentPlayingIndex == index;
                  final isHighlighted = quranProvider.highlightedAyahIndex == index;
                  final isActive = isPlaying || isHighlighted;
                  final arabicNumeral = _toArabicDigits(ayah.numberInSurah);

                  return TextSpan(
                    children: [
                      // Verse Arabic Text
                      TextSpan(
                        text: '${ayah.text} ',
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            HapticFeedback.selectionClick();
                            quranProvider.selectAyah(index);
                          },
                        style: TextStyle(
                          fontFamily: 'HafsFont',
                          fontSize: quranProvider.fontSize,
                          height: 2.2,
                          color: isDark ? const Color(0xFFF0F6FC) : const Color(0xFF0F172A),
                          backgroundColor: Colors.transparent,
                          fontWeight: FontWeight.normal,
                        ),
                      ),

                      // High-Performance Inline Verse Number Glyph (﴿١﴾)
                      TextSpan(
                        text: ' ﴿$arabicNumeral﴾ ',
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            HapticFeedback.selectionClick();
                            quranProvider.selectAyah(index);
                          },
                        style: TextStyle(
                          fontFamily: 'HafsFont',
                          fontSize: quranProvider.fontSize * 0.85,
                          color: isActive
                              ? (isDark ? const Color(0xFF60A5FA) : JiraTheme.primaryBlue)
                              : (isDark ? const Color(0xFF93C5FD).withValues(alpha: 0.7) : JiraTheme.primaryBlue.withValues(alpha: 0.6)),
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
