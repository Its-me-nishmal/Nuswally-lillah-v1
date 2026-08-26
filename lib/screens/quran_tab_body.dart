import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/juz_model.dart';
import '../models/quran_model.dart';
import '../providers/quran_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/jira_theme.dart';
import '../widgets/heartbeat_tap.dart';
import '../widgets/quran/juz_directory_card.dart';
import '../widgets/quran/quran_filter_chips.dart';
import '../widgets/quran/surah_directory_card.dart';
import 'surah_detail_screen.dart';

/// Quran list directory tab body used inside [HomeScreen].
class QuranTabBody extends StatefulWidget {
  final String searchQuery;

  const QuranTabBody({super.key, this.searchQuery = ''});

  @override
  State<QuranTabBody> createState() => _QuranTabBodyState();
}

class _QuranTabBodyState extends State<QuranTabBody> {
  QuranFilterType _activeFilter = QuranFilterType.all;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<QuranProvider>().fetchSurahs();
    });
  }

  List<JuzModel> _filterJuzs(List<JuzModel> juzs) {
    if (widget.searchQuery.isEmpty) return juzs;
    final q = widget.searchQuery.toLowerCase();
    return juzs.where((j) =>
      j.nameEn.toLowerCase().contains(q) ||
      j.nameAr.contains(q) ||
      j.startSurahName.toLowerCase().contains(q) ||
      j.endSurahName.toLowerCase().contains(q) ||
      j.id.toString() == q
    ).toList();
  }

  List<Surah> _filterSurahs(List<Surah> surahs, QuranProvider provider) {
    List<Surah> list = surahs;

    // Apply Filter Chips
    switch (_activeFilter) {
      case QuranFilterType.bookmarks:
        list = list.where((s) => provider.isBookmarked(s.number)).toList();
        break;
      case QuranFilterType.meccan:
        list = list.where((s) => s.revelationType.toLowerCase() == 'meccan').toList();
        break;
      case QuranFilterType.medinan:
        list = list.where((s) => s.revelationType.toLowerCase() == 'medinan').toList();
        break;
      case QuranFilterType.juz:
      case QuranFilterType.all:
        break;
    }

    // Apply Search Query
    if (widget.searchQuery.isNotEmpty) {
      final q = widget.searchQuery.toLowerCase();
      list = list.where((s) =>
        s.englishName.toLowerCase().contains(q) ||
        s.name.contains(q) ||
        s.malayalamName.toLowerCase().contains(q) ||
        s.englishNameTranslation.toLowerCase().contains(q) ||
        s.malayalamNameTranslation.toLowerCase().contains(q) ||
        s.number.toString().contains(q)
      ).toList();
    }

    return list;
  }

  Widget _buildInlineLastReadBanner(
    BuildContext context,
    QuranProvider provider,
    ThemeProvider themeProvider,
  ) {
    final isDark = themeProvider.isDarkMode;
    final surahNumber = provider.lastReadSurahNumber ?? 2;
    final ayahIndex = provider.lastReadAyahIndex;

    final Surah? targetSurah = provider.surahs.isNotEmpty
        ? provider.surahs.firstWhere(
            (s) => s.number == surahNumber,
            orElse: () => provider.surahs.first,
          )
        : null;

    if (targetSurah == null) return const SizedBox.shrink();

    final surahName = targetSurah.englishName;
    final ayahNumber = ayahIndex + 1;
    final lineBorderColor = isDark
        ? const Color(0xFF222D38)
        : const Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 12),
      child: Row(
        children: [
          // Left extending line
          Expanded(
            child: Container(
              height: 1.0,
              color: lineBorderColor,
            ),
          ),

          // Center interactive Last Read Pill
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: HeartbeatTap(
              onTap: () {
                HapticFeedback.selectionClick();
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF151D24) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: lineBorderColor,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      size: 13,
                      color: themeProvider.primaryAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LAST READ: ',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: themeProvider.textSecondary,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      '$surahName : $ayahNumber',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: themeProvider.primaryAccent,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: themeProvider.primaryAccent,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Right extending line
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

  Widget _buildQuickSurahsBar(
    BuildContext context,
    QuranProvider provider,
    ThemeProvider themeProvider,
  ) {
    final isDark = themeProvider.isDarkMode;
    final quickSurahs = const [
      (36, 'Yaseen'),
      (67, 'Al-Mulk'),
      (18, 'Al-Kahf'),
      (55, 'Ar-Rahman'),
      (56, 'Al-Waqi\'ah'),
      (32, 'As-Sajdah'),
      (73, 'Al-Muzzammil'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      child: Row(
        children: quickSurahs.map((item) {
          final surahNum = item.$1;
          final surahName = item.$2;

          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: HeartbeatTap(
              onTap: () {
                HapticFeedback.selectionClick();
                if (provider.surahs.isEmpty) return;
                final targetSurah = provider.surahs.firstWhere(
                  (s) => s.number == surahNum,
                  orElse: () => provider.surahs.first,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SurahDetailScreen(surah: targetSurah),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5.5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF151D24) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF222D38) : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: themeProvider.primaryAccent.withValues(
                          alpha: isDark ? 0.12 : 0.15,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$surahNum',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: themeProvider.primaryAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      surahName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: themeProvider.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Consumer<QuranProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingSurahs) {
          return Center(
            child: CircularProgressIndicator(color: themeProvider.primaryAccent),
          );
        }

        if (provider.surahs.isEmpty) {
          return _buildErrorView(context, provider, themeProvider);
        }

        final filteredSurahs = _filterSurahs(provider.surahs, provider);
        final filteredJuzs = _filterJuzs(provider.juzs);
        final bookmarkedCount = provider.surahs.where((s) => provider.isBookmarked(s.number)).length;

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 12),

            // 1. Sleek Filter Category Segmented Pills
            if (widget.searchQuery.isEmpty) ...[
              QuranFilterChips(
                activeFilter: _activeFilter,
                totalCount: provider.surahs.length,
                bookmarksCount: bookmarkedCount,
                onFilterSelected: (filter) {
                  setState(() {
                    _activeFilter = filter;
                  });
                },
              ),
              const SizedBox(height: 10),

              // 2. Quick Daily Surahs Mini-Pills Bar (Yaseen, Mulk, Kahf, Rahman, etc.)
              if (_activeFilter == QuranFilterType.all) ...[
                _buildQuickSurahsBar(context, provider, themeProvider),
                const SizedBox(height: 10),
              ],

              // 3. Modern Line-to-Line Inline Last Read Separator
              _buildInlineLastReadBanner(context, provider, themeProvider),
            ],

            // 4. Unified Grouped Directory List (iOS Style with Hairlines)
            if (_activeFilter == QuranFilterType.juz) ...[
              if (filteredJuzs.isEmpty)
                _buildEmptyView(themeProvider)
              else
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? JiraTheme.darkSurface : JiraTheme.lightSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? JiraTheme.darkBorderSubtle : JiraTheme.lightBorderSubtle,
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
                        blurRadius: 14,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(filteredJuzs.length, (index) {
                        final juz = filteredJuzs[index];
                        final isLast = index == filteredJuzs.length - 1;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            JuzDirectoryCard(juz: juz),
                            if (!isLast)
                              Padding(
                                padding: const EdgeInsets.only(left: 68, right: 16),
                                child: Container(
                                  height: 1.0,
                                  color: isDark ? const Color(0xFF222D38) : const Color(0xFFE5E9EE),
                                ),
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
            ] else ...[
              if (filteredSurahs.isEmpty)
                _buildEmptyView(themeProvider)
              else
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? JiraTheme.darkSurface : JiraTheme.lightSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? JiraTheme.darkBorderSubtle : JiraTheme.lightBorderSubtle,
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
                        blurRadius: 14,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(filteredSurahs.length, (index) {
                        final surah = filteredSurahs[index];
                        final isLast = index == filteredSurahs.length - 1;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SurahDirectoryCard(
                              surah: surah,
                              isBookmarked: provider.isBookmarked(surah.number),
                              onBookmarkToggle: () => provider.toggleBookmark(surah.number),
                            ),
                            if (!isLast)
                              Padding(
                                padding: const EdgeInsets.only(left: 68, right: 16),
                                child: Container(
                                  height: 1.0,
                                  color: isDark ? const Color(0xFF222D38) : const Color(0xFFE5E9EE),
                                ),
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
            ],

            SizedBox(height: 80 + MediaQuery.paddingOf(context).bottom), // Bottom clearance for attached bar
          ],
        );
      },
    );
  }

  Widget _buildEmptyView(ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _activeFilter == QuranFilterType.bookmarks
                  ? Icons.bookmark_border_rounded
                  : Icons.search_off_rounded,
              size: 48,
              color: themeProvider.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              _activeFilter == QuranFilterType.bookmarks
                  ? 'No bookmarks yet'
                  : 'No matching Surahs found',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: themeProvider.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, QuranProvider provider, ThemeProvider themeProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: themeProvider.textMuted),
          const SizedBox(height: 12),
          Text(
            'Failed to load Quran data',
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: themeProvider.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.fetchSurahs(),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.primaryAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
