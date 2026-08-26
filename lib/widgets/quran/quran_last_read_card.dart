import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/quran_model.dart';
import '../../providers/quran_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/jira_theme.dart';
import '../heartbeat_tap.dart';
import '../../screens/surah_detail_screen.dart';

class QuranLastReadCard extends StatelessWidget {
  const QuranLastReadCard({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final quranProvider = context.watch<QuranProvider>();
    final isDark = themeProvider.isDarkMode;

    final surfaceColor = isDark ? JiraTheme.darkSurface : JiraTheme.lightSurface;
    final borderColor = isDark ? JiraTheme.darkBorderSubtle : JiraTheme.lightBorderSubtle;

    // Use actual last read if available, else standard Al-Baqarah
    final surahNumber = quranProvider.lastReadSurahNumber ?? 2;
    final ayahIndex = quranProvider.lastReadAyahIndex;
    final ayahDisplay = ayahIndex > 0 ? 'AYAH ${ayahIndex + 1}' : 'AYAH 152';

    final Surah? surah = quranProvider.surahs.isNotEmpty
        ? quranProvider.surahs.firstWhere(
            (s) => s.number == surahNumber,
            orElse: () => quranProvider.surahs.first,
          )
        : null;

    final surahName = surah?.englishName ?? 'Al-Baqarah';
    final surahMeaning = surah?.englishNameTranslation ?? 'The Cow';

    return HeartbeatTap(
      onTap: () {
        HapticFeedback.selectionClick();
        final qp = context.read<QuranProvider>();
        if (qp.surahs.isEmpty) return;
        final targetSurah = qp.surahs.firstWhere(
          (s) => s.number == surahNumber,
          orElse: () => qp.surahs.first,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SurahDetailScreen(
              surah: targetSurah,
              initialAyahIndex: ayahIndex,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: LAST READ Pill + Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: themeProvider.primaryAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: themeProvider.primaryAccent.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: themeProvider.primaryAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LAST READ • $ayahDisplay',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.primaryAccent,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Continue',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.primaryAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Center: Surah Name on Left + Arabic Calligraphy on Right
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Title & Meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        surahName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: themeProvider.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        surahMeaning,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: themeProvider.textSecondary.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Arabic Calligraphy in restful off-white
                Text(
                  'فَاذْكُرُونِي\nأَذْكُرْكُمْ',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'HafsFont',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFE2E8F0) : themeProvider.primaryAccent,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
