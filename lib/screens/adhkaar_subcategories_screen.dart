import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/adhkaar.dart';
import '../providers/adhkaar_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/heartbeat_tap.dart';
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
    final isDark = tp.isDarkMode;
    final isMl = tp.isMalayalam;
    final bundle = context.watch<AdhkaarProvider>().bundle;
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const double kTopBarHeight = 56.0;

    if (bundle == null) {
      return Scaffold(
        backgroundColor: tp.backgroundTop,
        body: Center(
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

    return Scaffold(
      backgroundColor: tp.backgroundTop,
      body: Stack(
        children: [
          // Background Gradient & Subtle Islamic Pattern
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [tp.backgroundTop, tp.backgroundBottom],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.035,
              child: Image.asset(
                'assets/images/islamic_bg.png',
                repeat: ImageRepeat.repeat,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),

          // Scrollable List Content
          Positioned.fill(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, topInset + kTopBarHeight + 12, 16, bottomInset + 24),
              children: [
                // Hero Category Summary Card
                if (!_isSearching) ...[
                  _buildHeroCategoryCard(context, tp, isDark, categoryTitle, allSubs.length, totalInvocations),
                  const SizedBox(height: 18),
                ],

                // Section Header
                _buildSectionHeader(tp, subs.length),
                const SizedBox(height: 10),

                // Unified iOS Grouped Card
                if (subs.isEmpty)
                  _buildEmptySearchState(tp, query)
                else
                  Container(
                    decoration: BoxDecoration(
                      color: tp.surfaceColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: tp.borderColor, width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: subs.asMap().entries.map((entry) {
                          final index = entry.key + 1;
                          final sub = entry.value;
                          final isLast = entry.key == subs.length - 1;

                          return Column(
                            children: [
                              _buildChapterRowItem(context, tp, sub, index, isMl, isDark),
                              if (!isLast) _buildHairlineDivider(isDark),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Fixed Frosted 56px Top Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topInset + kTopBarHeight,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.only(top: topInset),
                  decoration: BoxDecoration(
                    color: tp.backgroundTop.withValues(alpha: isDark ? 0.85 : 0.90),
                    border: Border(
                      bottom: BorderSide(
                        color: tp.borderColor.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: _buildTopAppBar(context, tp, isDark, categoryTitle),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context, ThemeProvider tp, bool isDark, String categoryTitle) {
    if (_isSearching) {
      return Container(
        height: 56.0,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        child: Row(
          children: [
            HeartbeatTap(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tp.surfaceColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: tp.borderColor, width: 0.8),
                ),
                child: Center(
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: tp.textPrimary, size: 16),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF151D24) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: tp.borderColor, width: 0.8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: tp.primaryAccent, size: 17),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: tp.textPrimary),
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search chapters or duas...',
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: tp.textMuted),
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
          ],
        ),
      );
    }

    return Container(
      height: 56.0,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular Back Button
          HeartbeatTap(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tp.surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(color: tp.borderColor, width: 0.8),
              ),
              child: Center(
                child: Icon(Icons.arrow_back_ios_new_rounded, color: tp.textPrimary, size: 16),
              ),
            ),
          ),

          // Center Title
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    categoryTitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: tp.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Islamic Library • Adhkaar',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: tp.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Button
          HeartbeatTap(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isSearching = true);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tp.surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(color: tp.borderColor, width: 0.8),
              ),
              child: Center(
                child: Icon(Icons.search_rounded, color: tp.textPrimary, size: 17),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCategoryCard(
    BuildContext context,
    ThemeProvider tp,
    bool isDark,
    String title,
    int chapterCount,
    int invocationCount,
  ) {
    final arabicTitle = _getCategoryArabicTitle(title);
    final icon = _getCategoryIcon(title);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tp.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tp.borderColor, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tp.primaryAccent.withValues(alpha: isDark ? 0.12 : 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: tp.primaryAccent.withValues(alpha: isDark ? 0.3 : 0.4),
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Icon(icon, color: tp.primaryAccent, size: 24),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: tp.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$chapterCount Chapters • $invocationCount Authentic Duas',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: tp.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151D24) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF222D38) : const Color(0xFFE2E8F0),
                width: 0.8,
              ),
            ),
            child: Text(
              arabicTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'HafsFont',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFE2E8F0) : tp.primaryAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeProvider tp, int count) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        'CHAPTERS & OCCASIONS ($count)',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: tp.textSecondary,
        ),
      ),
    );
  }

  Widget _buildHairlineDivider(bool isDark) {
    return Container(
      height: 1.0,
      margin: const EdgeInsets.only(left: 68),
      color: isDark ? const Color(0xFF222D38) : const Color(0xFFE2E8F0),
    );
  }

  Widget _buildChapterRowItem(
    BuildContext context,
    ThemeProvider tp,
    AdhkaarSubCategory sub,
    int index,
    bool isMl,
    bool isDark,
  ) {
    final title = isMl ? sub.title : (sub.titleEn.isNotEmpty ? sub.titleEn : sub.title);

    return HeartbeatTap(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdhkaarDuasScreen(sub: sub),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: Colors.transparent,
        child: Row(
          children: [
            // Left Teal Number Badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tp.primaryAccent.withValues(alpha: isDark ? 0.12 : 0.14),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: tp.primaryAccent.withValues(alpha: isDark ? 0.25 : 0.35),
                  width: 0.8,
                ),
              ),
              child: Center(
                child: Text(
                  index.toString().padLeft(2, '0'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: tp.primaryAccent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Center Titles
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: tp.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (sub.titleArabic.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      sub.titleArabic,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'HafsFont',
                        fontSize: 13.5,
                        color: isDark ? const Color(0xFFE2E8F0) : tp.primaryAccent,
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    '${sub.duaIds.length} authentic prayers',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: tp.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: tp.textMuted,
            ),
          ],
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
            const SizedBox(height: 12),
            Text(
              'No chapters found for "$query"',
              style: GoogleFonts.plusJakartaSans(
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
