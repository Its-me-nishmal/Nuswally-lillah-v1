import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/quran_model.dart';
import '../../providers/quran_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/jira_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final quranProvider = context.watch<QuranProvider>();
    final isDark = themeProvider.isDarkMode;

    final surfaceColor = isDark ? JiraTheme.darkSurface : JiraTheme.lightSurface;
    final containerColor = isDark ? JiraTheme.darkContainer : JiraTheme.lightContainer;
    final borderColor = isDark ? JiraTheme.darkBorder : JiraTheme.lightBorder;

    return ListView.builder(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 140),
      itemCount: quranProvider.ayahs.length + 1,
      itemBuilder: (context, index) {
        // Index 0: Hero Surah Header Card matching Image 2
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor.withValues(alpha: isDark ? 0.6 : 0.9),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Metadata Chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPillBadge('SURAH ${surah.number}', isDark, containerColor, borderColor),
                    const SizedBox(width: 8),
                    _buildPillBadge(surah.revelationType.toUpperCase(), isDark, containerColor, borderColor),
                    const SizedBox(width: 8),
                    _buildPillBadge('${surah.numberOfAyahs} VERSES', isDark, containerColor, borderColor),
                  ],
                ),
                const SizedBox(height: 28),

                // Centerpiece Bismillah
                if (surah.number != 9) ...[
                  const Text(
                    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'HafsFont',
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC7D2FE),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: themeProvider.textSecondary.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        // Ayah Card (index - 1)
        final ayahIndex = index - 1;
        final key = ayahKeys.putIfAbsent(ayahIndex, () => GlobalKey());
        final ayah = quranProvider.ayahs[ayahIndex];
        final isPlaying = quranProvider.currentPlayingIndex == ayahIndex;
        final isHighlighted = quranProvider.highlightedAyahIndex == ayahIndex;
        final isActive = isPlaying || isHighlighted;

        return Container(
          key: key,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? JiraTheme.primaryBlue.withValues(alpha: 0.8)
                  : borderColor.withValues(alpha: isDark ? 0.6 : 0.9),
              width: isActive ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? JiraTheme.primaryBlue.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Utility Bar: Number Badge + Action Icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Ayah Badge (e.g. "2:1")
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: borderColor,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      '${surah.number}:${ayah.numberInSurah}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFD0D7DE) : JiraTheme.primaryBlue,
                      ),
                    ),
                  ),

                  // Micro-actions Row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Play Verse
                      HeartbeatTap(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          quranProvider.togglePlayAyah(ayahIndex);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_outlined,
                            size: 18,
                            color: isPlaying ? JiraTheme.primaryBlue : themeProvider.textSecondary,
                          ),
                        ),
                      ),
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
                            size: 17,
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
                            size: 17,
                            color: themeProvider.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Arabic Verse Calligraphy (RTL)
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  ayah.text,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'HafsFont',
                    fontSize: quranProvider.fontSize,
                    height: 2.0,
                    color: isDark ? const Color(0xFFF0F6FC) : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPillBadge(String text, bool isDark, Color containerColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF8B949E),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
