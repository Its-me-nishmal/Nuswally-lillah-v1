import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/quran_provider.dart';
import '../models/quran_model.dart';
import 'surah_detail_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      if (!mounted) return;
      context.read<QuranProvider>().fetchSurahs();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Surah> _filtered(List<Surah> surahs) {
    if (_searchQuery.isEmpty) return surahs;
    final q = _searchQuery.toLowerCase();
    return surahs.where((s) =>
      s.englishName.toLowerCase().contains(q) ||
      s.number.toString().contains(q) ||
      s.englishNameTranslation.toLowerCase().contains(q)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          image: const DecorationImage(
            image: AssetImage('assets/images/islamic_bg.png'),
            opacity: 0.05,
            repeat: ImageRepeat.repeat,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildSearchBar(context),
              _buildTabBar(context),
              Expanded(
                child: Consumer<QuranProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoadingSurahs) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (provider.surahs.isEmpty) {
                      return _buildErrorView(context, provider);
                    }

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        Column(
                          children: [
                            if (provider.lastReadSurahNumber != null)
                              _buildContinueReadingCard(context, provider),
                            Expanded(
                              child: _buildSurahList(context, provider, _filtered(provider.surahs)),
                            ),
                          ],
                        ),
                        _buildBookmarksList(context, provider),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'The Holy Quran',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueReadingCard(BuildContext context, QuranProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surahName = provider.lastReadSurahName ?? '';
    final ayahIndex = provider.lastReadAyahIndex;

    final surah = provider.surahs.firstWhere(
      (s) => s.number == provider.lastReadSurahNumber,
      orElse: () => provider.surahs.first,
    );

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SurahDetailScreen(
            surah: surah,
            initialAyahIndex: ayahIndex,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.1),
              colorScheme.secondary.withValues(alpha: isDark ? 0.2 : 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_stories_rounded, color: colorScheme.primary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONTINUE READING',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    surahName,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (ayahIndex > 0)
                    Text(
                      'Around verse ${ayahIndex + 1}',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: colorScheme.primary, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: GoogleFonts.outfit(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Search surah name or number...',
            hintStyle: GoogleFonts.outfit(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              fontSize: 14,
            ),
            prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded, color: colorScheme.primary, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TabBar(
        controller: _tabController,
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.4),
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'All Surahs'),
          Tab(text: 'Bookmarks'),
        ],
      ),
    );
  }

  Widget _buildSurahList(BuildContext context, QuranProvider provider, List<Surah> surahs) {
    if (surahs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(
              'No results found',
              style: GoogleFonts.outfit(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: surahs.length,
      physics: const BouncingScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildSurahCard(context, surahs[index], provider),
    );
  }

  Widget _buildBookmarksList(BuildContext context, QuranProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final bookmarked = provider.surahs
        .where((s) => provider.isBookmarked(s.number))
        .toList();

    if (bookmarked.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border_rounded, size: 56, color: colorScheme.primary.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(
              'No bookmarks yet',
              style: GoogleFonts.outfit(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap ♥ on any Surah to save it',
              style: GoogleFonts.outfit(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.3)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: bookmarked.length,
      physics: const BouncingScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildSurahCard(context, bookmarked[index], provider),
    );
  }

  Widget _buildSurahCard(BuildContext context, Surah surah, QuranProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBookmarked = provider.isBookmarked(surah.number);
    final isLastRead = provider.lastReadSurahNumber == surah.number;

    return GestureDetector(
      onTap: () {
        // Save as last read immediately when tapped
        provider.saveLastRead(surah.number, surah.englishName, 0);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SurahDetailScreen(surah: surah)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLastRead
              ? colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.05)
              : (isDark ? colorScheme.surfaceContainerHighest : Colors.white),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isLastRead
                ? colorScheme.primary.withValues(alpha: 0.4)
                : isBookmarked
                    ? colorScheme.secondary.withValues(alpha: 0.3)
                    : colorScheme.primary.withValues(alpha: 0.05),
            width: isLastRead ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isLastRead
                    ? colorScheme.primary.withValues(alpha: 0.2)
                    : colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  surah.number.toString(),
                  style: GoogleFonts.outfit(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        surah.englishName,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (isLastRead) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'LAST READ',
                            style: GoogleFonts.outfit(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '${surah.revelationType} • ${surah.numberOfAyahs} Verses',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => provider.toggleBookmark(surah.number),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  key: ValueKey(isBookmarked),
                  color: isBookmarked ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.2),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              surah.name,
              style: TextStyle(
                fontFamily: 'HafsFont',
                fontSize: 22,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, QuranProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 64, color: colorScheme.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('Connection Error', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary)),
          const SizedBox(height: 8),
          const Text('Please check your internet and try again.'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => provider.fetchSurahs(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
