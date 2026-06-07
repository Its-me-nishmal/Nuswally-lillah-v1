import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFF051424),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF051424),
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
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF5EEAD4)));
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF5EEAD4)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'The Holy Quran',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueReadingCard(BuildContext context, QuranProvider provider) {
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
          color: const Color(0xFF144F4B).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF5EEAD4).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_stories_rounded, color: Color(0xFF5EEAD4), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONTINUE READING',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: const Color(0xFF5EEAD4).withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    surahName,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (ayahIndex > 0)
                    Text(
                      'Around verse ${ayahIndex + 1}',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11,
                        color: const Color(0xFFD4E4FA).withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF5EEAD4), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF122131),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF5EEAD4).withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: GoogleFonts.hankenGrotesk(fontSize: 15, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search surah name or number...',
            hintStyle: GoogleFonts.hankenGrotesk(
              color: const Color(0xFFD4E4FA).withValues(alpha: 0.4),
              fontSize: 14,
            ),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF5EEAD4), size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF5EEAD4), size: 18),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TabBar(
        controller: _tabController,
        labelStyle: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w500, fontSize: 13),
        labelColor: const Color(0xFF5EEAD4),
        unselectedLabelColor: const Color(0xFFD4E4FA).withValues(alpha: 0.4),
        indicatorColor: const Color(0xFF5EEAD4),
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
    final isBookmarked = provider.isBookmarked(surah.number);
    final isLastRead = provider.lastReadSurahNumber == surah.number;

    final activeColor = const Color(0xFF5EEAD4);
    final normalColor = const Color(0xFFD4E4FA);

    return GestureDetector(
      onTap: () {
        provider.saveLastRead(surah.number, surah.englishName, 0);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SurahDetailScreen(surah: surah)),
        );
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isLastRead
              ? const Color(0xFF144F4B).withValues(alpha: 0.3)
              : const Color(0xFF122131),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: isLastRead
                ? activeColor.withValues(alpha: 0.4)
                : isBookmarked
                    ? activeColor.withValues(alpha: 0.2)
                    : activeColor.withValues(alpha: 0.06),
            width: isLastRead ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: activeColor.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  surah.number.toString(),
                  style: GoogleFonts.jetBrainsMono(
                    color: activeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (isLastRead) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: activeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: activeColor.withValues(alpha: 0.2), width: 0.5),
                          ),
                          child: Text(
                            'LAST READ',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: activeColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${surah.revelationType} • ${surah.numberOfAyahs} Verses',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11,
                      color: normalColor.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                provider.toggleBookmark(surah.number);
                HapticFeedback.mediumImpact();
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  key: ValueKey(isBookmarked),
                  color: isBookmarked ? activeColor : normalColor.withValues(alpha: 0.2),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              surah.name,
              style: TextStyle(
                fontFamily: 'HafsFont',
                fontSize: 22,
                color: activeColor,
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
