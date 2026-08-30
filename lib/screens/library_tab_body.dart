import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/adhkaar.dart';
import '../models/allah_name.dart';
import '../providers/adhkaar_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/heartbeat_tap.dart';
import 'adhkaar_subcategories_screen.dart';
import 'adhkaar_duas_screen.dart';
import 'haddad_screen.dart';
import 'dua_detail_screen.dart';
import 'moulid_reader_screen.dart';
import 'names_screen.dart';
import 'quranic_duas_screen.dart';
import '../theme/app_colors.dart';
import '../theme/home_design.dart';

class LibraryTabBody extends StatefulWidget {
  final String searchQuery;

  const LibraryTabBody({super.key, this.searchQuery = ''});

  @override
  State<LibraryTabBody> createState() => _LibraryTabBodyState();
}

class _LibraryTabBodyState extends State<LibraryTabBody> {
  String _selectedFilterKey = 'all';
  final Set<String> _bookmarkedKeys = {'1', '24', '30'};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdhkaarProvider>().load();
    });
  }

  void _openCategory(BuildContext context, AdhkaarCategory cat) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdhkaarSubcategoriesScreen(category: cat),
      ),
    );
  }

  void _openSubCategory(
    BuildContext context,
    AdhkaarBundle? bundle,
    int subId,
  ) {
    if (bundle == null) return;
    final sub = bundle.subCategoryById(subId);
    if (sub != null) {
      HapticFeedback.selectionClick();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdhkaarDuasScreen(sub: sub)),
      );
    }
  }

  void _openDua(BuildContext context, AdhkaarBundle? bundle, int duaId) {
    if (bundle == null) return;
    final dua = bundle.duas[duaId];
    if (dua != null) {
      HapticFeedback.selectionClick();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DuaDetailScreen(dua: dua)),
      );
    }
  }

  IconData _getCategoryIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('daily') || lower.contains('ദിനചര്യ')) {
      return Icons.wb_sunny_outlined;
    } else if (lower.contains('salah') ||
        lower.contains('prayer') ||
        lower.contains('നമസ്കാര')) {
      return Icons.mosque_outlined;
    } else if (lower.contains('protection') ||
        lower.contains('relief') ||
        lower.contains('രക്ഷ')) {
      return Icons.shield_outlined;
    } else if (lower.contains('life') ||
        lower.contains('family') ||
        lower.contains('കുടുംബം')) {
      return Icons.family_restroom_rounded;
    } else if (lower.contains('guidance') ||
        lower.contains('blessings') ||
        lower.contains('സന്മാർഗ്ഗം')) {
      return Icons.auto_awesome_rounded;
    } else if (lower.contains('names') || lower.contains('asma')) {
      return Icons.favorite_border_rounded;
    } else if (lower.contains('quran')) {
      return Icons.menu_book_rounded;
    }
    return Icons.auto_stories_outlined;
  }

  String _getCategorySubtitle(AdhkaarCategory cat, bool isMl) {
    final lower = cat.titleEn.toLowerCase();
    if (lower.contains('daily')) {
      return isMl
          ? 'ഉണരുമ്പോഴും ഉറങ്ങുമ്പോഴുമുള്ള ദിക്റുകൾ'
          : 'Morning, evening & daily routines';
    } else if (lower.contains('prayer') || lower.contains('worship')) {
      return isMl
          ? 'നമസ്കാരത്തിലെയും ശേഷവുമുള്ള ദിക്റുകൾ'
          : 'Adhkaar & supplications in Salah';
    } else if (lower.contains('protection') || lower.contains('relief')) {
      return isMl
          ? 'വിപത്തുകളിൽ നിന്നും ശത്രുക്കളിൽ നിന്നുമുള്ള രക്ഷ'
          : 'Fortress against harm & distress';
    } else if (lower.contains('life') || lower.contains('family')) {
      return isMl
          ? 'കുടുംബം, രോഗം, വിവാഹം, ജീവിത സന്ദർഭങ്ങൾ'
          : 'Sickness, family & life milestones';
    } else if (lower.contains('guidance') || lower.contains('blessings')) {
      return isMl
          ? 'സന്മാർഗ്ഗവും പാപമോചനവും പുണ്യങ്ങളും'
          : 'Seeking forgiveness & righteous paths';
    }
    return isMl
        ? '${cat.subCategoryIds.length} അധ്യായങ്ങൾ'
        : '${cat.subCategoryIds.length} authentic chapters';
  }

  @override
  Widget build(BuildContext context) {
    context.watchTheme();
    final tp = context.watch<ThemeProvider>();
    final isDark = tp.isDarkMode;
    final isMl = tp.isMalayalam;
    final adhkaar = context.watch<AdhkaarProvider>();
    final bundle = adhkaar.bundle;

    if (adhkaar.isLoading && bundle == null) {
      return Center(child: CircularProgressIndicator(color: tp.primaryAccent));
    }

    final query = widget.searchQuery.trim().toLowerCase();

    // All categories & subcategories from dataset
    final allCategories = bundle?.categories ?? [];
    final allSubs = bundle?.subCategories ?? [];

    // Filter subcategories when searching via top app bar
    final matchingSubs = allSubs.where((sub) {
      if (query.isEmpty) return true;
      return sub.title.toLowerCase().contains(query) ||
          sub.titleEn.toLowerCase().contains(query) ||
          sub.titleArabic.toLowerCase().contains(query);
    }).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 12),

        // 1. Sleek Filter Capsules Bar (Aligned with list margin)
        _buildFilterPills(tp, isDark),

        const SizedBox(height: 14),

        // 2. Quick Vault Shortcuts Bar
        if (query.isEmpty && _selectedFilterKey == 'all') ...[
          _buildQuickShortcutsBar(context, tp, bundle, isDark, isMl),
          const SizedBox(height: 16),
        ],

        // 3. Search Mode: Display live matching invocations
        if (query.isNotEmpty) ...[
          _buildSectionHeader(
            'MATCHING INVOCATIONS (${matchingSubs.length})',
            tp,
          ),
          const SizedBox(height: 10),
          if (matchingSubs.isEmpty)
            _buildEmptySearchState(query, tp)
          else
            _buildGroupedCard(
              isDark: isDark,
              surfaceColor: tp.surfaceColor,
              borderColor: tp.borderColor,
              children: matchingSubs.asMap().entries.map((entry) {
                final isLast = entry.key == matchingSubs.length - 1;
                return Column(
                  children: [
                    _buildSubCategoryRowItem(
                      context,
                      bundle,
                      entry.value,
                      isMl,
                      tp,
                      isDark,
                    ),
                    if (!isLast) _buildHairlineDivider(isDark),
                  ],
                );
              }).toList(),
            ),
        ]
        // Filter Specific Modes
        else if (_selectedFilterKey == 'names') ...[
          _buildSectionHeader('ASMAUL HUSNA (99 NAMES OF ALLAH)', tp),
          const SizedBox(height: 10),
          _buildNamesShortcutCard(context, isMl, tp, isDark),
          const SizedBox(height: 12),
          _buildNamesGroupedList(context, adhkaar.allahNames, isMl, tp, isDark),
        ] else if (_selectedFilterKey == 'quranic') ...[
          _buildSectionHeader('QURANIC RABBANA DUAS', tp),
          const SizedBox(height: 10),
          _buildQuranicDuasShortcutCard(context, isMl, tp, isDark),
          const SizedBox(height: 12),
          _buildQuranicDuasGroupedList(context, bundle, isMl, tp, isDark),
        ] else if (_selectedFilterKey == 'adhkaar') ...[
          _buildSectionHeader('DAILY ADHKAAR & REMEMBRANCE', tp),
          const SizedBox(height: 10),
          _buildFilteredGroupedList(
            context,
            bundle,
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 24, 25, 30, 31, 32],
            isMl,
            tp,
            isDark,
          ),
        ] else if (_selectedFilterKey == 'supplications') ...[
          _buildSectionHeader('PRAYER & WORSHIP SUPPLICATIONS', tp),
          const SizedBox(height: 10),
          _buildFilteredGroupedList(
            context,
            bundle,
            [13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 34, 35],
            isMl,
            tp,
            isDark,
          ),
        ] else if (_selectedFilterKey == 'protection') ...[
          _buildSectionHeader('PROTECTION & RUQYAH', tp),
          const SizedBox(height: 10),
          _buildFilteredGroupedList(
            context,
            bundle,
            [36, 37, 38, 39, 41, 42, 43, 44, 45, 47, 48, 157, 158, 161, 162],
            isMl,
            tp,
            isDark,
          ),
        ] else if (_selectedFilterKey == 'bookmarks') ...[
          _buildSectionHeader(
            'SAVED BOOKMARKS (${_bookmarkedKeys.length})',
            tp,
          ),
          const SizedBox(height: 10),
          _buildBookmarksGroupedList(context, bundle, isMl, tp, isDark),
        ] else ...[
          // Default "All Collections" View:
          _buildSectionHeader(
            isMl
                ? 'വിഷയ വിഭാഗങ്ങൾ (${allCategories.length} എണ്ണം)'
                : 'TOPIC DIRECTORY (${allCategories.length} CATEGORIES)',
            tp,
          ),
          const SizedBox(height: 10),

          // Unified Grouped Card with Hairlines
          _buildGroupedCard(
            isDark: isDark,
            surfaceColor: tp.surfaceColor,
            borderColor: tp.borderColor,
            children: [
              ...allCategories.asMap().entries.map((entry) {
                final cat = entry.value;
                final catTitle = isMl
                    ? cat.title
                    : (cat.titleEn.isNotEmpty ? cat.titleEn : cat.title);

                return Column(
                  children: [
                    _buildCategoryRowItem(
                      context: context,
                      icon: _getCategoryIcon(catTitle),
                      title: catTitle,
                      subtitle: _getCategorySubtitle(cat, isMl),
                      tp: tp,
                      isDark: isDark,
                      onTap: () => _openCategory(context, cat),
                    ),
                    _buildHairlineDivider(isDark),
                  ],
                );
              }),

              // Curated Sacred Vault Shortcuts inside the Grouped Card
              _buildCategoryRowItem(
                context: context,
                icon: Icons.favorite_border_rounded,
                title: isMl ? 'അസ്മാഉൽ ഹുസ്ന' : '99 Names of Allah',
                subtitle: isMl
                    ? 'അല്ലാഹുവിന്റെ 99 നാമങ്ങൾ അർത്ഥ സഹിതം'
                    : 'Asma ul Husna sacred attributes & audio',
                tp: tp,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NamesScreen(),
                    ),
                  );
                },
              ),
              _buildHairlineDivider(isDark),

              _buildCategoryRowItem(
                context: context,
                icon: Icons.menu_book_rounded,
                title: isMl
                    ? 'ഖുർആനിക റബ്ബനാ പ്രാർത്ഥനകൾ'
                    : 'Quranic Rabbana Duas',
                subtitle: isMl
                    ? 'വിശുദ്ധ ഖുർആനിലെ 40 റബ്ബനാ പ്രാർത്ഥനകൾ'
                    : '40 Rabbana supplications from Holy Quran',
                tp: tp,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QuranicDuasScreen(),
                    ),
                  );
                },
              ),
              _buildHairlineDivider(isDark),

              _buildCategoryRowItem(
                context: context,
                icon: Icons.auto_awesome_rounded,
                title: isMl ? 'മങ്കൂസ് മൗലിദ് (ടെക്സ്റ്റ് റീഡർ)' : 'Manqoos Moulid (Native Text)',
                subtitle: isMl ? '14 ഫസലുകളും ബൈത്തുകളും ഖിയാമും മനോഹരമായ അറബിക് ഫോണ്ടിൽ' : 'All 14 Fasl, Baith & Qiyam in rich native typography',
                tp: tp,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MoulidReaderScreen()),
                  );
                },
              ),
              _buildHairlineDivider(isDark),

              _buildCategoryRowItem(
                context: context,
                icon: Icons.menu_book_rounded,
                title: isMl ? 'റാതീബുൽ ഹദ്ദാദ് (ടെക്സ്റ്റ് റീഡർ)' : 'Ratib al-Haddad (Native Text)',
                subtitle: isMl ? 'ഇമാം ഹദ്ദാദ് (റ) തങ്ങളുടെ സമ്പൂർണ്ണ റാത്തീബും ദുആയും' : 'Complete litany & prayers of Imam al-Haddad in rich typography',
                tp: tp,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HaddadScreen()),
                  );
                },
              ),
            ],
          ),
        ],

        SizedBox(height: 80 + MediaQuery.paddingOf(context).bottom),
      ],
    );
  }

  // Quick Shortcuts Mini-Pills Bar
  Widget _buildQuickShortcutsBar(
    BuildContext context,
    ThemeProvider tp,
    AdhkaarBundle? bundle,
    bool isDark,
    bool isMl,
  ) {
    final shortcuts = [
      {
        'title': isMl ? 'അസ്മാഉൽ ഹുസ്ന' : '99 Names',
        'icon': Icons.auto_awesome_rounded,
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NamesScreen()),
          );
        },
      },
      {
        'title': isMl ? 'റബ്ബനാ ദുആകൾ' : '40 Rabbana',
        'icon': Icons.menu_book_rounded,
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QuranicDuasScreen()),
          );
        },
      },
      {
        'title': isMl ? 'പ്രഭാത ദിക്റുകൾ' : 'Morning',
        'icon': Icons.wb_sunny_outlined,
        'action': () => _openSubCategory(context, bundle, 1),
      },
      {
        'title': isMl ? 'പ്രദോഷ ദിക്റുകൾ' : 'Evening',
        'icon': Icons.nights_stay_outlined,
        'action': () => _openSubCategory(context, bundle, 2),
      },
      {
        'title': isMl ? 'നമസ്കാര ശേഷം' : 'After Salah',
        'icon': Icons.mosque_outlined,
        'action': () => _openSubCategory(context, bundle, 30),
      },
      {
        'title': isMl ? 'ഉറങ്ങുമ്പോൾ' : 'Sleep Duas',
        'icon': Icons.bedtime_outlined,
        'action': () => _openSubCategory(context, bundle, 24),
      },
      {
        'title': isMl ? 'റുഖ്‌യ & രക്ഷ' : 'Ruqyah',
        'icon': Icons.shield_outlined,
        'action': () => _openSubCategory(context, bundle, 41),
      },
    ];

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: shortcuts.length,
        itemBuilder: (context, index) {
          final item = shortcuts[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: HeartbeatTap(
              onTap: () {
                HapticFeedback.selectionClick();
                (item['action'] as VoidCallback)();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isDark ? context.cardTop : context.cardBottom,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? context.hairline : context.cardBorder,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 14,
                      color: tp.primaryAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item['title'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: tp.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Filter Capsules Bar
  Widget _buildFilterPills(ThemeProvider tp, bool isDark) {
    final filters = [
      {'key': 'all', 'label': 'All Collections'},
      {'key': 'adhkaar', 'label': 'Daily Adhkaar'},
      {'key': 'supplications', 'label': 'Salah Duas'},
      {'key': 'protection', 'label': 'Protection & Ruqyah'},
      {'key': 'names', 'label': '99 Names'},
      {'key': 'quranic', 'label': 'Quranic Duas'},
      {'key': 'bookmarks', 'label': 'Bookmarks'},
    ];

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilterKey == filter['key'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: HeartbeatTap(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedFilterKey = filter['key']!);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? tp.primaryAccent.withValues(alpha: isDark ? 0.14 : 0.12)
                      : tp.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? tp.primaryAccent.withValues(
                            alpha: isDark ? 0.35 : 0.4,
                          )
                        : tp.borderColor,
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Text(
                    filter['label']!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? tp.primaryAccent : tp.textSecondary,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Unified Grouped Card Container (iOS Style)
  Widget _buildGroupedCard({
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 0.8),
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
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }

  Widget _buildHairlineDivider(bool isDark) {
    return Container(
      height: 1.0,
      margin: const EdgeInsets.only(left: 68),
      color: isDark ? context.hairline : context.cardBorder,
    );
  }

  // Category Row Item
  Widget _buildCategoryRowItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeProvider tp,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return HeartbeatTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: Colors.transparent,
        child: Row(
          children: [
            // Left Teal Squircle Badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tp.primaryAccent.withValues(alpha: isDark ? 0.12 : 0.14),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: tp.primaryAccent.withValues(
                    alpha: isDark ? 0.25 : 0.35,
                  ),
                  width: 0.8,
                ),
              ),
              child: Center(
                child: Icon(icon, color: tp.primaryAccent, size: 20),
              ),
            ),
            const SizedBox(width: 14),

            // Titles
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
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: tp.textSecondary.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),

            Icon(Icons.chevron_right_rounded, size: 20, color: tp.textMuted),
          ],
        ),
      ),
    );
  }

  // Subcategory Row Item (Search / Filter)
  Widget _buildSubCategoryRowItem(
    BuildContext context,
    AdhkaarBundle? bundle,
    AdhkaarSubCategory sub,
    bool isMl,
    ThemeProvider tp,
    bool isDark,
  ) {
    final title = isMl
        ? sub.title
        : (sub.titleEn.isNotEmpty ? sub.titleEn : sub.title);

    return HeartbeatTap(
      onTap: () => _openSubCategory(context, bundle, sub.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: Colors.transparent,
        child: Row(
          children: [
            // Number Badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tp.primaryAccent.withValues(alpha: isDark ? 0.12 : 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: tp.primaryAccent.withValues(
                    alpha: isDark ? 0.22 : 0.30,
                  ),
                  width: 0.8,
                ),
              ),
              child: Center(
                child: Text(
                  sub.id.toString(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: tp.primaryAccent,
                  ),
                ),
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
                      fontSize: 14,
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
                        fontSize: 13,
                        color: isDark
                            ? HomeDesign.goldText(isDark)
                            : tp.primaryAccent,
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

            Icon(Icons.chevron_right_rounded, size: 20, color: tp.textMuted),
          ],
        ),
      ),
    );
  }

  // Filtered Subcategories List in Grouped Card
  Widget _buildFilteredGroupedList(
    BuildContext context,
    AdhkaarBundle? bundle,
    List<int> subIds,
    bool isMl,
    ThemeProvider tp,
    bool isDark,
  ) {
    if (bundle == null) return const SizedBox();
    final subs = subIds
        .map((id) => bundle.subCategoryById(id))
        .whereType<AdhkaarSubCategory>()
        .toList();

    return _buildGroupedCard(
      isDark: isDark,
      surfaceColor: tp.surfaceColor,
      borderColor: tp.borderColor,
      children: subs.asMap().entries.map((entry) {
        final isLast = entry.key == subs.length - 1;
        return Column(
          children: [
            _buildSubCategoryRowItem(
              context,
              bundle,
              entry.value,
              isMl,
              tp,
              isDark,
            ),
            if (!isLast) _buildHairlineDivider(isDark),
          ],
        );
      }).toList(),
    );
  }

  // Bookmarks List in Grouped Card
  Widget _buildBookmarksGroupedList(
    BuildContext context,
    AdhkaarBundle? bundle,
    bool isMl,
    ThemeProvider tp,
    bool isDark,
  ) {
    if (bundle == null) return const SizedBox();
    final subs = _bookmarkedKeys
        .map((k) => int.tryParse(k) ?? 0)
        .map((id) => bundle.subCategoryById(id))
        .whereType<AdhkaarSubCategory>()
        .toList();

    if (subs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(
                Icons.bookmark_border_rounded,
                size: 36,
                color: tp.textMuted,
              ),
              const SizedBox(height: 10),
              Text(
                'No bookmarked invocations yet',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: tp.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildGroupedCard(
      isDark: isDark,
      surfaceColor: tp.surfaceColor,
      borderColor: tp.borderColor,
      children: subs.asMap().entries.map((entry) {
        final isLast = entry.key == subs.length - 1;
        return Column(
          children: [
            _buildSubCategoryRowItem(
              context,
              bundle,
              entry.value,
              isMl,
              tp,
              isDark,
            ),
            if (!isLast) _buildHairlineDivider(isDark),
          ],
        );
      }).toList(),
    );
  }

  // 99 Names Shortcut Card
  Widget _buildNamesShortcutCard(
    BuildContext context,
    bool isMl,
    ThemeProvider tp,
    bool isDark,
  ) {
    return HeartbeatTap(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NamesScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tp.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tp.primaryAccent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: tp.primaryAccent, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Asmaul Husna • 99 Names of Allah',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: tp.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'View all 99 sacred names with calligraphy & audio',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: tp.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: tp.primaryAccent,
            ),
          ],
        ),
      ),
    );
  }

  // 99 Names Grouped List
  Widget _buildNamesGroupedList(
    BuildContext context,
    List<AllahName> allNames,
    bool isMl,
    ThemeProvider tp,
    bool isDark,
  ) {
    final names = allNames.take(20).toList();

    return _buildGroupedCard(
      isDark: isDark,
      surfaceColor: tp.surfaceColor,
      borderColor: tp.borderColor,
      children: names.asMap().entries.map((entry) {
        final name = entry.value;
        final isLast = entry.key == names.length - 1;

        return Column(
          children: [
            HeartbeatTap(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NamesScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: tp.primaryAccent.withValues(
                              alpha: isDark ? 0.12 : 0.14,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              name.number.toString().padLeft(2, '0'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: tp.primaryAccent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.transliteration,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: tp.textPrimary,
                              ),
                            ),
                            Text(
                              name.meaning,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: tp.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      name.name,
                      style: TextStyle(
                        fontFamily: 'HafsFont',
                        fontSize: 19,
                        color: isDark
                            ? HomeDesign.goldText(isDark)
                            : tp.primaryAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!isLast) _buildHairlineDivider(isDark),
          ],
        );
      }).toList(),
    );
  }

  // Quranic Duas Shortcut Card
  Widget _buildQuranicDuasShortcutCard(
    BuildContext context,
    bool isMl,
    ThemeProvider tp,
    bool isDark,
  ) {
    return HeartbeatTap(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const QuranicDuasScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tp.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tp.primaryAccent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.menu_book_rounded, color: tp.primaryAccent, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '40 Rabbana Quranic Duas',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: tp.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sacred prayers revealed in the Holy Quran',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: tp.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: tp.primaryAccent,
            ),
          ],
        ),
      ),
    );
  }

  // Quranic Duas Grouped List
  Widget _buildQuranicDuasGroupedList(
    BuildContext context,
    AdhkaarBundle? bundle,
    bool isMl,
    ThemeProvider tp,
    bool isDark,
  ) {
    if (bundle == null) return const SizedBox();
    final duas = bundle.quranicDuaIds
        .take(15)
        .map((id) => bundle.duas[id])
        .whereType<Dua>()
        .toList();

    return _buildGroupedCard(
      isDark: isDark,
      surfaceColor: tp.surfaceColor,
      borderColor: tp.borderColor,
      children: duas.asMap().entries.map((entry) {
        final d = entry.value;
        final isLast = entry.key == duas.length - 1;

        return Column(
          children: [
            HeartbeatTap(
              onTap: () => _openDua(context, bundle, d.id),
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.dua,
                      style: TextStyle(
                        fontFamily: 'HafsFont',
                        fontSize: 17,
                        color: context.textPrimary,
                        height: 1.6,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isMl
                          ? d.trans
                          : (d.descEn.isNotEmpty ? d.descEn : d.transli),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: tp.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          d.ref.isNotEmpty ? d.ref : 'Holy Quran',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: tp.primaryAccent,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: tp.textMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (!isLast) _buildHairlineDivider(isDark),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(String title, ThemeProvider tp) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: tp.textSecondary,
        ),
      ),
    );
  }

  Widget _buildEmptySearchState(String query, ThemeProvider tp) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 40, color: tp.textMuted),
            const SizedBox(height: 12),
            Text(
              'No collections found for "$query"',
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
