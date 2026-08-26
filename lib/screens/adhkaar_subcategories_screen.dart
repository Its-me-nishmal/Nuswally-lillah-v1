import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/adhkaar.dart';
import '../providers/adhkaar_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/heartbeat_tap.dart';
import '../widgets/jira_screen.dart';
import 'adhkaar_duas_screen.dart';

class AdhkaarSubcategoriesScreen extends StatefulWidget {
  final AdhkaarCategory category;

  const AdhkaarSubcategoriesScreen({super.key, required this.category});

  @override
  State<AdhkaarSubcategoriesScreen> createState() => _AdhkaarSubcategoriesScreenState();
}

class _AdhkaarSubcategoriesScreenState extends State<AdhkaarSubcategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('morning') || t.contains('രാവിലെ')) return Icons.wb_sunny_rounded;
    if (t.contains('evening') || t.contains('വൈകുന്നേരം')) return Icons.nights_stay_rounded;
    if (t.contains('prayer') || t.contains('നമസ്കാര')) return Icons.access_time_filled_rounded;
    if (t.contains('quran') || t.contains('ഖുർആൻ')) return Icons.menu_book_rounded;
    if (t.contains('protection') || t.contains('സംരക്ഷണം')) return Icons.shield_rounded;
    if (t.contains('illness') || t.contains('രോഗം')) return Icons.healing_rounded;
    if (t.contains('sleep') || t.contains('ഉറക്കം')) return Icons.bedtime_rounded;
    if (t.contains('travel') || t.contains('യാത്ര')) return Icons.explore_rounded;
    if (t.contains('hajj') || t.contains('ഹജ്ജ്')) return Icons.mosque_rounded;
    if (t.contains('food') || t.contains('ഭക്ഷണം')) return Icons.restaurant_rounded;
    if (t.contains('nature') || t.contains('പ്രകൃതി')) return Icons.cloud_rounded;
    if (t.contains('sorrow') || t.contains('വിഷമം')) return Icons.favorite_rounded;
    return Icons.auto_awesome_rounded;
  }

  String _getCategoryArabicTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('morning') || t.contains('രാവിലെ')) return 'أَذْكَارُ الصَّبَاحِ';
    if (t.contains('evening') || t.contains('വൈകുന്നേരം')) return 'أَذْكَارُ الْمَسَاءِ';
    if (t.contains('prayer') || t.contains('നമസ്കാര')) return 'أَدْعِيَةُ الصَّلَاةِ';
    if (t.contains('quran') || t.contains('ഖുർആൻ')) return 'أَدْعِيَةُ الْقُرْآنِ';
    if (t.contains('protection') || t.contains('സംരക്ഷണം')) return 'أَدْعِيَةُ الْحِفْظِ';
    if (t.contains('illness') || t.contains('രോഗം')) return 'أَدْعِيَةُ الْمَرِيضِ';
    if (t.contains('sleep') || t.contains('ഉറക്കം')) return 'أَذْكَارُ النَّوْمِ';
    if (t.contains('travel') || t.contains('യാത്ര')) return 'أَدْعِيَةُ السَّفَرِ';
    if (t.contains('hajj') || t.contains('ഹജ്ജ്')) return 'أَدْعِيَةُ الْحَجِّ';
    if (t.contains('food') || t.contains('ഭക്ഷണം')) return 'أَدْعِيَةُ الطَّعَامِ';
    if (t.contains('nature') || t.contains('പ്രകൃതി')) return 'أَدْعِيَةُ الطَّبِيعَةِ';
    if (t.contains('sorrow') || t.contains('വിഷമം')) return 'أَدْعِيَةُ الْفَرَجِ';
    return 'أَذْكَارٌ وَأَدْعِيَةٌ';
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final isMl = tp.isMalayalam;
    final bundle = context.watch<AdhkaarProvider>().bundle;

    if (bundle == null) {
      return JiraScreen(
        child: Center(
          child: CircularProgressIndicator(color: tp.primaryAccent),
        ),
      );
    }

    final allSubs = widget.category.subCategoryIds
        .map((id) => bundle.subCategories[id])
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

    return JiraScreen(
      child: Column(
        children: [
          // 1. Top App Bar
          _buildTopAppBar(context, tp),

          // Search Bar when active
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: tp.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tp.borderColor),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: tp.primaryAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: GoogleFonts.outfit(fontSize: 13.5, color: tp.textPrimary),
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search chapters or keywords...',
                          hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: tp.textMuted),
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
                        child: Icon(Icons.close_rounded, color: tp.textMuted, size: 16),
                      ),
                  ],
                ),
              ),
            ),

          // 2. Scrollable Content
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + MediaQuery.paddingOf(context).bottom),
              children: [
                // Hero Category Summary Card
                if (!_isSearching) ...[
                  _buildHeroCategoryCard(context, tp, categoryTitle, allSubs.length, totalInvocations, allSubs.isNotEmpty ? allSubs.first : null),
                  const SizedBox(height: 20),
                ],

                // Section Header: CHAPTERS & OCCASIONS
                _buildSectionHeader(tp, subs.length),

                const SizedBox(height: 12),

                // Chapters List
                if (subs.isEmpty)
                  _buildEmptySearchState(tp, query)
                else
                  ...subs.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final sub = entry.value;
                    return _buildChapterCard(context, tp, sub, index, isMl);
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. Top App Bar
  Widget _buildTopAppBar(BuildContext context, ThemeProvider tp) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Circular frosted back button
          HeartbeatTap(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tp.surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(color: tp.borderColor),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: tp.textPrimary,
                size: 18,
              ),
            ),
          ),

          // Center: Title
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Nuswally Lillah',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: tp.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tp.surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(color: tp.borderColor),
              ),
              child: Icon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
                color: tp.textPrimary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Hero Category Summary Card
  Widget _buildHeroCategoryCard(BuildContext context, ThemeProvider tp, String title, int chapterCount, int invocationCount, AdhkaarSubCategory? firstSub) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tp.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tp.borderColor),
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
                        color: tp.containerColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tp.borderColor),
                      ),
                      child: Icon(
                        _getCategoryIcon(title),
                        color: tp.primaryAccent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: tp.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$chapterCount Chapters • $invocationCount Invocations',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: tp.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Right: Large Arabic Calligraphy
              Text(
                _getCategoryArabicTitle(title),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'HafsFont',
                  fontSize: 20,
                  fontWeight: FontWeight.normal,
                  color: tp.primaryAccent,
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
                color: tp.containerColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tp.primaryAccent.withValues(alpha: 0.6), width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_arrow_outlined,
                    color: tp.primaryAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Start Reading',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: tp.primaryAccent,
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
  Widget _buildSectionHeader(ThemeProvider tp, int count) {
    return Row(
      children: [
        Text(
          'CHAPTERS & OCCASIONS',
          style: GoogleFonts.outfit(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
            color: tp.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: tp.containerColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: tp.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: tp.borderColor.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  // 4. Chapter Card
  Widget _buildChapterCard(BuildContext context, ThemeProvider tp, AdhkaarSubCategory sub, int index, bool isMl) {
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
            color: tp.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tp.borderColor),
          ),
          child: Row(
            children: [
              // Index Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tp.containerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: tp.primaryAccent,
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
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: tp.textPrimary,
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
                        style: TextStyle(
                          fontFamily: 'HafsFont',
                          fontSize: 13.5,
                          color: tp.primaryAccent,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${sub.duaIds.length} Invocations • $estMins Mins',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: tp.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: tp.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySearchState(ThemeProvider tp, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 40, color: tp.textMuted),
            const SizedBox(height: 10),
            Text(
              'No chapters matching "$query"',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: tp.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
