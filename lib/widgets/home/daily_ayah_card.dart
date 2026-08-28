import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/quran_provider.dart';
import '../../providers/theme_provider.dart';
import '../../screens/surah_detail_screen.dart';
import '../../theme/home_design.dart';
import '../heartbeat_tap.dart';

/// One verse a day, rotating by day-of-year.
///
/// The Arabic is copied verbatim from the bundled `assets/quran/quran.json`
/// (Uthmani script), so text and reference are authoritative and available
/// offline. Tapping opens the verse in its surah.
class DailyAyahCard extends StatelessWidget {
  const DailyAyahCard({super.key});

  static const List<_Ayah> _verses = [
    _Ayah(
      surah: 94,
      verse: 5,
      surahName: 'Ash-Sharh',
      // Verbatim from assets/quran/quran.json
      arabic: 'فَإِنَّ مَعَ ٱلۡعُسۡرِ يُسۡرًا',
      translation: 'For indeed, with hardship comes ease.',
    ),
    _Ayah(
      surah: 85,
      verse: 14,
      surahName: 'Al-Buruj',
      // Verbatim from assets/quran/quran.json
      arabic: 'وَهُوَ ٱلۡغَفُورُ ٱلۡوَدُودُ',
      translation: 'And He is the Forgiving, the Affectionate.',
    ),
    _Ayah(
      surah: 2,
      verse: 152,
      surahName: 'Al-Baqarah',
      // Verbatim from assets/quran/quran.json
      arabic: 'فَٱذۡكُرُونِيٓ أَذۡكُرۡكُمۡ وَٱشۡكُرُواْ لِي وَلَا تَكۡفُرُونِ',
      translation:
          'So remember Me; I will remember you. And be grateful to Me and do not deny Me.',
    ),
    _Ayah(
      surah: 55,
      verse: 13,
      surahName: 'Ar-Rahman',
      // Verbatim from assets/quran/quran.json
      arabic: 'فَبِأَيِّ ءَالَآءِ رَبِّكُمَا تُكَذِّبَانِ',
      translation: 'So which of the favours of your Lord would you deny?',
    ),
    _Ayah(
      surah: 13,
      verse: 28,
      surahName: 'Ar-Ra\'d',
      // Verbatim from assets/quran/quran.json
      arabic:
          'ٱلَّذِينَ ءَامَنُواْ وَتَطۡمَئِنُّ قُلُوبُهُم بِذِكۡرِ ٱللَّهِۗ أَلَا بِذِكۡرِ ٱللَّهِ تَطۡمَئِنُّ ٱلۡقُلُوبُ',
      translation:
          'Those who have believed and whose hearts are assured by the remembrance of Allah. Unquestionably, by the remembrance of Allah hearts are assured.',
    ),
    _Ayah(
      surah: 29,
      verse: 69,
      surahName: 'Al-\'Ankabut',
      // Verbatim from assets/quran/quran.json
      arabic:
          'وَٱلَّذِينَ جَٰهَدُواْ فِينَا لَنَهۡدِيَنَّهُمۡ سُبُلَنَاۚ وَإِنَّ ٱللَّهَ لَمَعَ ٱلۡمُحۡسِنِينَ',
      translation:
          'And those who strive for Us — We will surely guide them to Our ways. And indeed, Allah is with the doers of good.',
    ),
    _Ayah(
      surah: 39,
      verse: 53,
      surahName: 'Az-Zumar',
      // Verbatim from assets/quran/quran.json
      arabic:
          '۞قُلۡ يَٰعِبَادِيَ ٱلَّذِينَ أَسۡرَفُواْ عَلَىٰٓ أَنفُسِهِمۡ لَا تَقۡنَطُواْ مِن رَّحۡمَةِ ٱللَّهِۚ إِنَّ ٱللَّهَ يَغۡفِرُ ٱلذُّنُوبَ جَمِيعًاۚ إِنَّهُۥ هُوَ ٱلۡغَفُورُ ٱلرَّحِيمُ',
      translation:
          'Say: O My servants who have transgressed against themselves, do not despair of the mercy of Allah. Indeed, Allah forgives all sins. Indeed, it is He who is the Forgiving, the Merciful.',
    ),
    _Ayah(
      surah: 93,
      verse: 7,
      surahName: 'Ad-Duhaa',
      // Verbatim from assets/quran/quran.json
      arabic: 'وَوَجَدَكَ ضَآلّٗا فَهَدَىٰ',
      translation: 'And He found you lost and guided you.',
    ),
  ];

  static _Ayah _forToday() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return _verses[dayOfYear % _verses.length];
  }

  void _openVerse(BuildContext context, _Ayah ayah) {
    final surahs = context.read<QuranProvider>().surahs;
    final match = surahs.where((s) => s.number == ayah.surah);
    if (match.isEmpty) return; // Surah list not loaded yet.
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SurahDetailScreen(
          surah: match.first,
          initialAyahIndex: ayah.verse - 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final ayah = _forToday();

    return HeartbeatTap(
      onTap: () => _openVerse(context, ayah),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 15, 18, 16),
        decoration: BoxDecoration(
          gradient: HomeDesign.cardGradient(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HomeDesign.goldLine(isDark), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: HomeDesign.shadow(isDark),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  size: 14,
                  color: HomeDesign.gold,
                ),
                const SizedBox(width: 7),
                Text(
                  'DAILY AYAH',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: HomeDesign.goldText(isDark),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.north_east_rounded,
                  size: 14,
                  color: themeProvider.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 13),

            // Arabic, Uthmani script, right-aligned.
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                ayah.arabic,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'HafsFont',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: themeProvider.textPrimary,
                  height: 1.75,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Text(
              '“${ayah.translation}”',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w400,
                color: themeProvider.textPrimary.withValues(alpha: 0.88),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              '— Surah ${ayah.surahName} (${ayah.surah}:${ayah.verse})',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: themeProvider.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ayah {
  final int surah;
  final int verse;
  final String surahName;
  final String arabic;
  final String translation;

  const _Ayah({
    required this.surah,
    required this.verse,
    required this.surahName,
    required this.arabic,
    required this.translation,
  });
}
