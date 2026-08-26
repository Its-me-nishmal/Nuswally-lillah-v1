import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/juz_model.dart';
import '../models/quran_model.dart';
import '../providers/quran_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/quran/juz_directory_card.dart';
import '../widgets/quran/quran_last_read_card.dart';
import '../widgets/quran/quran_filter_chips.dart';
import '../widgets/quran/surah_directory_card.dart';

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

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

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
            // 1. Last Read Hero Card (only shown when not searching and on 'All Surahs')
            if (widget.searchQuery.isEmpty && _activeFilter == QuranFilterType.all) ...[
              const SizedBox(height: 6),
              const QuranLastReadCard(),
              const SizedBox(height: 20),
            ] else ...[
              const SizedBox(height: 12),
            ],

            // 2. Filter Category Pills (when not searching)
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
              const SizedBox(height: 16),
            ],

            // 3. Directory List (Juz or Surah)
            if (_activeFilter == QuranFilterType.juz) ...[
              if (filteredJuzs.isEmpty)
                _buildEmptyView(themeProvider)
              else
                ...List.generate(filteredJuzs.length, (index) {
                  final juz = filteredJuzs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: JuzDirectoryCard(juz: juz),
                  );
                }),
            ] else ...[
              if (filteredSurahs.isEmpty)
                _buildEmptyView(themeProvider)
              else
                ...List.generate(filteredSurahs.length, (index) {
                  final surah = filteredSurahs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: SurahDirectoryCard(
                      surah: surah,
                      isBookmarked: provider.isBookmarked(surah.number),
                      onBookmarkToggle: () => provider.toggleBookmark(surah.number),
                    ),
                  );
                }),
            ],

            SizedBox(height: 100 + MediaQuery.paddingOf(context).bottom), // Dynamic bottom clearance for floating bar
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
