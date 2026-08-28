import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/juz_model.dart';
import '../../providers/quran_provider.dart';
import '../../providers/theme_provider.dart';
import '../../screens/surah_detail_screen.dart';
import '../heartbeat_tap.dart';
import '../../theme/app_colors.dart';
import '../../theme/home_design.dart';

class JuzDirectoryCard extends StatelessWidget {
  final JuzModel juz;

  const JuzDirectoryCard({super.key, required this.juz});

  static const List<String> _arabicNumerals = [
    '١',
    '٢',
    '٣',
    '٤',
    '٥',
    '٦',
    '٧',
    '٨',
    '٩',
    '١٠',
    '١١',
    '١٢',
    '١٣',
    '١٤',
    '١٥',
    '١٦',
    '١٧',
    '١٨',
    '١٩',
    '٢٠',
    '٢١',
    '٢٢',
    '٢٣',
    '٢٤',
    '٢٥',
    '٢٦',
    '٢٧',
    '٢٨',
    '٢٩',
    '٣٠',
  ];

  @override
  Widget build(BuildContext context) {
    context.watchTheme();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final arabicDigit = (juz.id >= 1 && juz.id <= 30)
        ? _arabicNumerals[juz.id - 1]
        : juz.id.toString();

    return HeartbeatTap(
      onTap: () {
        HapticFeedback.selectionClick();
        final qp = context.read<QuranProvider>();
        if (qp.surahs.isEmpty) return;
        final targetSurah = qp.surahs.firstWhere(
          (s) => s.number == juz.startSurahNumber,
          orElse: () => qp.surahs.first,
        );

        final targetIndex = (juz.startAyah - 1).clamp(
          0,
          targetSurah.numberOfAyahs - 1,
        );
        qp.saveLastRead(
          targetSurah.number,
          targetSurah.englishName,
          targetIndex,
        );

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        color: Colors.transparent,
        child: Row(
          children: [
            // Left Squircle Number Badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: themeProvider.primaryAccent.withValues(
                  alpha: isDark ? 0.10 : 0.12,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeProvider.primaryAccent.withValues(
                    alpha: isDark ? 0.22 : 0.30,
                  ),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Text(
                  juz.id.toString(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.primaryAccent,
                  ),
                ),
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
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    juz.rangeDisplay,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w400,
                      color: themeProvider.textSecondary.withValues(
                        alpha: 0.85,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Right Column: Arabic Script Calligraphy in soft off-white
            Text(
              juz.nameAr,
              style: TextStyle(
                fontFamily: 'HafsFont',
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: HomeDesign.goldText(isDark),
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }
}
