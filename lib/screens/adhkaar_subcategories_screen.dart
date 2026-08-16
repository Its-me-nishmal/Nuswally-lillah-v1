import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/adhkaar.dart';
import '../providers/adhkaar_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/jira_theme.dart';
import '../widgets/heartbeat_tap.dart';
import 'adhkaar_duas_screen.dart';

class AdhkaarSubcategoriesScreen extends StatefulWidget {
  final AdhkaarCategory category;

  const AdhkaarSubcategoriesScreen({super.key, required this.category});

  @override
  State<AdhkaarSubcategoriesScreen> createState() => _AdhkaarSubcategoriesScreenState();
}

class _AdhkaarSubcategoriesScreenState extends State<AdhkaarSubcategoriesScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('morning') || lower.contains('evening') || lower.contains('പ്രഭാതം')) {
      return Icons.wb_sunny_outlined;
    } else if (lower.contains('salah') || lower.contains('prayer') || lower.contains('നമസ്കാരം')) {
      return Icons.mosque_outlined;
    } else if (lower.contains('daily') || lower.contains('life') || lower.contains('ജീവിതം')) {
      return Icons.directions_walk_rounded;
    } else if (lower.contains('protection') || lower.contains('ruqyah') || lower.contains('സംരക്ഷണം')) {
      return Icons.shield_outlined;
    } else if (lower.contains('names') || lower.contains('asma') || lower.contains('അസ്മാ')) {
      return Icons.favorite_border_rounded;
    } else if (lower.contains('quran') || lower.contains('ഖുർആൻ')) {
      return Icons.menu_book_rounded;
    }
    return Icons.auto_stories_outlined;
  }

  String _getCategoryArabicTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('morning') || lower.contains('evening')) {
      return 'أَذْكَارُ\nالصَّبَاحِ\nوَالْمَسَاءِ';
    } else if (lower.contains('salah') || lower.contains('prayer')) {
      return 'أَذْكَارُ\nالصَّلَاةِ';
    } else if (lower.contains('daily')) {
      return 'أَدْعِيَةُ\nالْيَوْمِ';
    } else if (lower.contains('protection')) {
      return 'الرُّقْيَةُ\nوَالْحِمَايَةُ';
    }
    return 'الأَذْكَارُ\nوَالأَدْعِيَةُ';
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final isMl = tp.isMalayalam;
    final bundle = context.watch<AdhkaarProvider>().bundle;

    if (bundle == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0E14),
        body: Center(child: CircularProgressIndicator(color: JiraTheme.primaryBlue)),
      );
    }

    final allSubs = widget.category.subCategoryIds
        .map((id) => bundle.subCategoryById(id))
        .whereType<AdhkaarSubCategory>()
        .toList();

    final totalInvocations = allSubs.fold<int>(0, (sum, sub) => sum + sub.duaIds.length);

    final query = _searchQuery.trim().toLowerCase();
    final subs = query.isEmpty
        ? allSubs
        : allSubs.where((s) {
            return s.title.toLowerCase().contains(query) ||
                s.titleEn.toLowerCase().contains(query) ||
                s.titleArabic.toLowerCase().contains(query);
          }).toList();

    final categoryTitle = isMl
        ? widget.category.title
        : (widget.category.titleEn.isNotEmpty ? widget.category.titleEn : widget.category.title);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top App Bar
            _buildTopAppBar(context),

            // Search Bar when active
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF30363D)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Color(0xFF38BDF8), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: GoogleFonts.outfit(fontSize: 13.5, color: Colors.white),
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search chapters or keywords...',
                            hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF8B949E)),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: const Icon(Icons.close_rounded, color: Color(0xFF8B949E), size: 16),
                        ),
                    ],
                  ),
                ),
              ),

            // 2. Scrollable Content
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 8),

                  // Hero Category Summary Card
                  if (!_isSearching) ...[
                    _buildHeroCategoryCard(context, categoryTitle, allSubs.length, totalInvocations, allSubs.isNotEmpty ? allSubs.first : null),
                    const SizedBox(height: 20),
                  ],

                  // Section Header: CHAPTERS & OCCASIONS
                  _buildSectionHeader(subs.length),

                  const SizedBox(height: 12),

                  // Chapters List
                  if (subs.isEmpty)
                    _buildEmptySearchState(query)
                  else
                    ...subs.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final sub = entry.value;
                      return _buildChapterCard(context, sub, index, isMl);
                    }),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Top App Bar
  Widget _buildTopAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Circular frosted back button
          HeartbeatTap(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFFF0F6FC),
                size: 20,
              ),
            ),
          ),

          // Center: Title
          Text(
            'Nuswally Lillah',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFF0F6FC),
              letterSpacing: 0.5,
            ),
          ),

          // Right: Search button
          HeartbeatTap(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              child: Icon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
                color: const Color(0xFFF0F6FC),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Hero Category Summary Card
  Widget _buildHeroCategoryCard(BuildContext context, String title, int chapterCount, int invocationCount, AdhkaarSubCategory? firstSub) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF30363D)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Icon + Title Stack
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F242C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF30363D)),
                      ),
                      child: Icon(
                        _getCategoryIcon(title),
                        color: const Color(0xFF38BDF8),
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFF0F6FC),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$chapterCount Chapters • $invocationCount Invocations',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF8B949E),
                      ),
                    ),
                  ],
                ),
              ),

              // Right: Large Arabic Calligraphy
              Text(
                _getCategoryArabicTitle(title),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontFamily: 'HafsFont',
                  fontSize: 22,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF93C5FD),
                  height: 1.45,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Bottom Action: Start Reading button
          HeartbeatTap(
            onTap: () {
              if (firstSub != null) {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdhkaarDuasScreen(sub: firstSub),
                  ),
                );
              }
            },
            child: Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0B0E14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: JiraTheme.primaryBlue.withValues(alpha: 0.6), width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.play_arrow_outlined,
                    color: Color(0xFF93C5FD),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Start Reading',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF93C5FD),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Section Header
  Widget _buildSectionHeader(int count) {
    return Row(
      children: [
        Text(
          'CHAPTERS & OCCASIONS',
          style: GoogleFonts.outfit(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
            color: const Color(0xFF8B949E),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF1F242C),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF8B949E),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFF30363D).withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  // 4. Chapter Card (Matching Stitch Screenshot)
  Widget _buildChapterCard(BuildContext context, AdhkaarSubCategory sub, int index, bool isMl) {
    final title = isMl ? sub.title : (sub.titleEn.isNotEmpty ? sub.titleEn : sub.title);
    final estMins = (sub.duaIds.length * 0.8).ceil().clamp(1, 20);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: HeartbeatTap(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdhkaarDuasScreen(sub: sub),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF30363D)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Index Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F242C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF93C5FD),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title & Subtitle Stack
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: isMl ? 'BalooChettan2' : GoogleFonts.outfit().fontFamily,
                        fontSize: isMl ? 14.5 : 14.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF0F6FC),
                        height: isMl ? 1.35 : 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sub.titleArabic.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        sub.titleArabic,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontFamily: 'HafsFont',
                          fontSize: 13.5,
                          color: Color(0xFF93C5FD),
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${sub.duaIds.length} Invocations • $estMins Mins',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF8B949E),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySearchState(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 40, color: Color(0xFF64748B)),
            const SizedBox(height: 10),
            Text(
              'No chapters matching "$query"',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8B949E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
