import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/juz_model.dart';
import '../../providers/quran_provider.dart';
import '../../providers/theme_provider.dart';
import '../../screens/surah_detail_screen.dart';
import '../../theme/jira_theme.dart';
import '../heartbeat_tap.dart';

class JuzDirectoryCard extends StatelessWidget {
  final JuzModel juz;

  const JuzDirectoryCard({
    super.key,
    required this.juz,
  });

  static const List<String> _arabicNumerals = [
    '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩', '١٠',
    '١١', '١٢', '١٣', '١٤', '١٥', '١٦', '١٧', '١٨', '١٩', '٢٠',
    '٢١', '٢٢', '٢٣', '٢٤', '٢٥', '٢٦', '٢٧', '٢٨', '٢٩', '٣٠'
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final surfaceColor = isDark ? JiraTheme.darkSurface : JiraTheme.lightSurface;
    final containerColor = isDark ? JiraTheme.darkContainer : JiraTheme.lightContainer;
    final borderColor = isDark ? JiraTheme.darkBorder : JiraTheme.lightBorder;

    final arabicDigit = (juz.id >= 1 && juz.id <= 30) ? _arabicNumerals[juz.id - 1] : juz.id.toString();

    return HeartbeatTap(
      onTap: () {
        HapticFeedback.selectionClick();
        final qp = context.read<QuranProvider>();
        if (qp.surahs.isEmpty) return;
        final targetSurah = qp.surahs.firstWhere(
          (s) => s.number == juz.startSurahNumber,
          orElse: () => qp.surahs.first,
        );

        final targetIndex = (juz.startAyah - 1).clamp(0, targetSurah.numberOfAyahs - 1);
        qp.saveLastRead(targetSurah.number, targetSurah.englishName, targetIndex);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SurahDetailScreen(
              surah: targetSurah,
              initialAyahIndex: targetIndex,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor.withValues(alpha: isDark ? 0.6 : 0.9),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Medallion Number Badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF388BFD).withValues(alpha: 0.3) : const Color(0xFF0C66E4).withValues(alpha: 0.2),
                  width: 1.2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 4,
                    child: Text(
                      'JUZ',
                      style: GoogleFonts.outfit(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656F7D),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    child: Text(
                      juz.id.toString(),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFFD0D7DE) : JiraTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Middle Column (Juz Name + Surah Range)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Juz $arabicDigit • ${juz.nameEn}',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFF0F6FC) : const Color(0xFF1F2328),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    juz.rangeDisplay,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656F7D),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Right Column: Arabic Script Calligraphy
            Text(
              juz.nameAr,
              style: const TextStyle(
                fontFamily: 'HafsFont',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981), // Emerald Arabic highlight
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }
}
