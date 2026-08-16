import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/jira_theme.dart';

class DailyAyahCard extends StatelessWidget {
  const DailyAyahCard({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final surfaceColor = isDark ? JiraTheme.darkSurface : JiraTheme.lightSurface;
    final borderColor = isDark ? JiraTheme.darkBorder : JiraTheme.lightBorder;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor.withValues(alpha: isDark ? 0.6 : 0.9),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Caption
          Text(
            'DAILY AYAH',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: JiraTheme.secondaryGreen,
            ),
          ),
          const SizedBox(height: 14),

          // Arabic Verse
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'فَاذْكُرُونِي أَذْكُرْكُمْ',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'HafsFont',
                fontSize: 27,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF0F6FC),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // English Translation
          Text(
            '"So remember Me; I will remember you."',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              color: themeProvider.textPrimary.withValues(alpha: 0.9),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),

          // Verse Reference
          Text(
            '— Surah Al-Baqarah (2:152)',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: themeProvider.textSecondary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
