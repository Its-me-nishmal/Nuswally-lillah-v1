import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/quran_model.dart';
import '../../providers/theme_provider.dart';
import '../heartbeat_tap.dart';
import '../../screens/surah_detail_screen.dart';

class SurahDirectoryCard extends StatelessWidget {
  final Surah surah;
  final bool isBookmarked;
  final VoidCallback? onBookmarkToggle;

  const SurahDirectoryCard({
    super.key,
    required this.surah,
    this.isBookmarked = false,
    this.onBookmarkToggle,
  });

  String _formatMeaning(String translation) {
    return translation.toUpperCase();
  }

  String _formatRevelation(String type) {
    return type.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final formattedNumber = surah.number.toString().padLeft(2, '0');
    final meaningText = _formatMeaning(surah.englishNameTranslation);
    final revelationText = _formatRevelation(surah.revelationType);
    final versesText = '${surah.numberOfAyahs} VERSES';
    final subtitleText = '$meaningText • $revelationText • $versesText';

    return HeartbeatTap(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SurahDetailScreen(surah: surah),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        color: Colors.transparent,
        child: Row(
          children: [
            // Left Squircle Number Badge with Islamic Teal Accent
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
                  formattedNumber,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.primaryAccent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Middle Column (English Title + Subtitle)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    surah.englishName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.textPrimary,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitleText,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: themeProvider.textSecondary.withValues(alpha: 0.85),
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Right Arabic Name (Soft Off-White Calligraphy)
            Text(
              surah.name.replaceAll('سُورَةُ ', ''),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'HafsFont',
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFE2E8F0) : themeProvider.primaryAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
