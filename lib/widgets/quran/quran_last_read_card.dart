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
    final borderColor = isDark ? JiraTheme.darkBorder : JiraTheme.lightBorder;

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
        if (surah != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SurahDetailScreen(
                surah: surah,
                initialAyahIndex: ayahIndex,
              ),
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor.withValues(alpha: isDark ? 0.6 : 0.9),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Last Read Capsule + Time Ago
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F291E) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: JiraTheme.secondaryGreen.withValues(alpha: 0.3),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: JiraTheme.secondaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LAST READ • $ayahDisplay',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: JiraTheme.secondaryGreen,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '2h ago',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: themeProvider.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

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
                        style: GoogleFonts.outfit(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          color: themeProvider.textPrimary,
                          letterSpacing: 0.2,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$surahMeaning • Page 23',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: themeProvider.textSecondary.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Arabic Calligraphy
                Text(
                  'فَاذْكُرُونِي\nأَذْكُرْكُمْ',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'HafsFont',
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC7D2FE),
                    height: 1.35,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Bottom Action: Forward Arrow Button
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? JiraTheme.darkContainer : JiraTheme.lightContainer,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor.withValues(alpha: 0.7),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: themeProvider.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
