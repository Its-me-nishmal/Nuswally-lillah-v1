import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/adhkaar.dart';
import '../models/allah_name.dart';
import '../providers/adhkaar_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/jira_theme.dart';
import '../widgets/heartbeat_tap.dart';
import 'adhkaar_subcategories_screen.dart';
import 'adhkaar_duas_screen.dart';
import 'dua_detail_screen.dart';
import 'names_screen.dart';
import 'quranic_duas_screen.dart';

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

  void _openSubCategory(BuildContext context, AdhkaarBundle? bundle, int subId) {
    if (bundle == null) return;
    final sub = bundle.subCategoryById(subId);
    if (sub != null) {
      HapticFeedback.selectionClick();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdhkaarDuasScreen(sub: sub),
        ),
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
        MaterialPageRoute(
          builder: (context) => DuaDetailScreen(dua: dua),
        ),
      );
    }
  }

  IconData _getCategoryIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('daily') || lower.contains('ദിനചര്യ')) {
      return Icons.wb_sunny_outlined;
    } else if (lower.contains('salah') || lower.contains('prayer') || lower.contains('നമസ്കാര')) {
      return Icons.mosque_outlined;
    } else if (lower.contains('protection') || lower.contains('relief') || lower.contains('രക്ഷ')) {
      return Icons.shield_outlined;
    } else if (lower.contains('life') || lower.contains('family') || lower.contains('കുടുംബം')) {
      return Icons.family_restroom_rounded;
    } else if (lower.contains('guidance') || lower.contains('blessings') || lower.contains('സന്മാർഗ്ഗം')) {
      return Icons.auto_awesome_rounded;
    } else if (lower.contains('names') || lower.contains('asma')) {
      return Icons.favorite_border_rounded;
    } else if (lower.contains('quran')) {
      return Icons.menu_book_rounded;
    }
    return Icons.auto_stories_outlined;
  }

  Color _getCategoryIconColor(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('daily') || lower.contains('ദിനചര്യ')) {
      return const Color(0xFF38BDF8);
    } else if (lower.contains('salah') || lower.contains('prayer')) {
      return JiraTheme.primaryBlue;
    } else if (lower.contains('protection')) {
      return const Color(0xFF38BDF8);
    } else if (lower.contains('life') || lower.contains('family')) {
      return const Color(0xFF60A5FA);
    } else if (lower.contains('guidance')) {
      return JiraTheme.secondaryGreen;
    }
    return const Color(0xFF38BDF8);
  }

  String _getCategorySubtitle(AdhkaarCategory cat, bool isMl) {
    final lower = cat.titleEn.toLowerCase();
    if (lower.contains('daily')) {
      return isMl ? 'ഉണരുമ്പോഴും ഉറങ്ങുമ്പോഴുമുള്ള ദിക്റുകൾ' : 'Morning, evening & daily routines';
    } else if (lower.contains('prayer') || lower.contains('worship')) {
      return isMl ? 'നമസ്കാരത്തിലെയും ശേഷവുമുള്ള ദിക്റുകൾ' : 'Adhkaar & supplications in Salah';
    } else if (lower.contains('protection') || lower.contains('relief')) {
      return isMl ? 'വിപത്തുകളിൽ നിന്നും ശത്രുക്കളിൽ നിന്നുമുള്ള രക്ഷ' : 'Fortress against harm & distress';
    } else if (lower.contains('life') || lower.contains('family')) {
      return isMl ? 'കുടുംബം, രോഗം, വിവാഹം, ജീവിത സന്ദർഭങ്ങൾ' : 'Sickness, family & life milestones';
    } else if (lower.contains('guidance') || lower.contains('blessings')) {
      return isMl ? 'സന്മാർഗ്ഗവും പാപമോചനവും പുണ്യങ്ങളും' : 'Seeking forgiveness & righteous paths';
    }
    return isMl
        ? '${cat.subCategoryIds.length} അധ്യായങ്ങൾ'
        : '${cat.subCategoryIds.length} authentic chapters';
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final isMl = tp.isMalayalam;
    final adhkaar = context.watch<AdhkaarProvider>();
    final bundle = adhkaar.bundle;

    if (adhkaar.isLoading && bundle == null) {
      return const Center(
        child: CircularProgressIndicator(color: JiraTheme.primaryBlue),
      );
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

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 8),

          // 1. Clean Text Filter Pills (Emoji-Free)
          _buildFilterPills(),

          const SizedBox(height: 18),

          // Search Mode: Display live matching invocations
          if (query.isNotEmpty) ...[
            _buildSectionHeader('MATCHING INVOCATIONS (${matchingSubs.length})'),
            const SizedBox(height: 12),
            if (matchingSubs.isEmpty)
              _buildEmptySearchState(query)
            else
              ...matchingSubs.map((sub) => _buildSubCategoryCard(context, bundle, sub, isMl)),
          ]
          // Filter Specific Modes
          else if (_selectedFilterKey == 'names') ...[
            _buildSectionHeader('ASMAUL HUSNA (99 NAMES OF ALLAH)'),
            const SizedBox(height: 12),
            _buildNamesShortcutCard(context, isMl),
            const SizedBox(height: 14),
            _buildNamesInlineList(context, adhkaar.allahNames, isMl),
          ] else if (_selectedFilterKey == 'quranic') ...[
            _buildSectionHeader('QURANIC RABBANA DUAS'),
            const SizedBox(height: 12),
            _buildQuranicDuasShortcutCard(context, isMl),
            const SizedBox(height: 14),
            _buildQuranicDuasInlineList(context, bundle, isMl),
          ] else if (_selectedFilterKey == 'adhkaar') ...[
            _buildSectionHeader('DAILY ADHKAAR & REMEMBRANCE'),
            const SizedBox(height: 12),
            _buildFilteredSubList(context, bundle, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 24, 25, 30, 31, 32], isMl),
          ] else if (_selectedFilterKey == 'supplications') ...[
            _buildSectionHeader('PRAYER & WORSHIP SUPPLICATIONS'),
            const SizedBox(height: 12),
            _buildFilteredSubList(context, bundle, [13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 34, 35], isMl),
          ] else if (_selectedFilterKey == 'protection') ...[
            _buildSectionHeader('PROTECTION & RUQYAH'),
            const SizedBox(height: 12),
            _buildFilteredSubList(context, bundle, [36, 37, 38, 39, 41, 42, 43, 44, 45, 47, 48, 157, 158, 161, 162], isMl),
          ] else if (_selectedFilterKey == 'bookmarks') ...[
            _buildSectionHeader('SAVED BOOKMARKS (${_bookmarkedKeys.length})'),
            const SizedBox(height: 12),
            _buildBookmarksList(context, bundle, isMl),
          ] else ...[
            // Default "All Collections" View:
            _buildSectionHeader(isMl ? 'വിഷയ വിഭാഗങ്ങൾ (${allCategories.length} എണ്ണം)' : 'TOPIC DIRECTORY (${allCategories.length} CATEGORIES)'),
            const SizedBox(height: 12),

            // 1. All Root Categories from Dataset (100% Clickable -> opens AdhkaarSubcategoriesScreen)
            ...allCategories.map((cat) {
              final catTitle = isMl ? cat.title : (cat.titleEn.isNotEmpty ? cat.titleEn : cat.title);
              return _buildUniformCard(
                context: context,
                icon: _getCategoryIcon(catTitle),
                iconColor: _getCategoryIconColor(catTitle),
                title: catTitle,
                subtitle: _getCategorySubtitle(cat, isMl),
                onTap: () => _openCategory(context, cat),
              );
            }),

            // 2. Curated Sacred Vault Collections
            _buildUniformCard(
              context: context,
              icon: Icons.favorite_border_rounded,
              iconColor: const Color(0xFF38BDF8),
              title: isMl ? 'അസ്മാഉൽ ഹുസ്ന' : '99 Names of Allah',
              subtitle: isMl ? 'അല്ലാഹുവിന്റെ 99 നാമങ്ങൾ അർത്ഥ സഹിതം' : 'Asma ul Husna sacred attributes & audio',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NamesScreen()),
                );
              },
            ),

            _buildUniformCard(
              context: context,
              icon: Icons.menu_book_rounded,
              iconColor: JiraTheme.secondaryGreen,
              title: isMl ? 'ഖുർആനിക റബ്ബനാ പ്രാർത്ഥനകൾ' : 'Quranic Rabbana Duas',
              subtitle: isMl ? 'വിശുദ്ധ ഖുർആനിലെ 40 റബ്ബനാ പ്രാർത്ഥനകൾ' : '40 Rabbana supplications from Holy Quran',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QuranicDuasScreen()),
                );
              },
            ),
          ],

          const SizedBox(height: 110), // Bottom clearance for floating dock
        ],
      ),
    );
  }

  // 1. Clean Text Filter Pills (NO EMOJIS)
  Widget _buildFilterPills() {
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
      height: 38,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? JiraTheme.primaryBlue : const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? JiraTheme.primaryBlue : const Color(0xFF30363D),
                    width: 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: JiraTheme.primaryBlue.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    filter['label']!,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF8B949E),
                      letterSpacing: 0.2,
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

  // 2. Uniform Category Card
  Widget _buildUniformCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: HeartbeatTap(
        onTap: onTap,
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F242C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF0F6FC),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF8B949E),
                      ),
                    ),
                  ],
                ),
              ),

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

  // 3. SubCategory Card (Sleek layout for search / filtered results)
  Widget _buildSubCategoryCard(BuildContext context, AdhkaarBundle? bundle, AdhkaarSubCategory sub, bool isMl) {
    final title = isMl ? sub.title : (sub.titleEn.isNotEmpty ? sub.titleEn : sub.title);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: HeartbeatTap(
        onTap: () => _openSubCategory(context, bundle, sub.id),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F242C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    sub.id.toString(),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF93C5FD),
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
                    if (sub.titleArabic.isNotEmpty) ...[
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
                      '${sub.duaIds.length} authentic prayers',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF8B949E),
                      ),
                    ),
                  ],
                ),
              ),

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

  // 4. Filtered Subcategories List
  Widget _buildFilteredSubList(BuildContext context, AdhkaarBundle? bundle, List<int> subIds, bool isMl) {
    if (bundle == null) return const SizedBox();
    final subs = subIds.map((id) => bundle.subCategoryById(id)).whereType<AdhkaarSubCategory>().toList();

    return Column(
      children: subs.map((s) => _buildSubCategoryCard(context, bundle, s, isMl)).toList(),
    );
  }

  // 5. Bookmarks List
  Widget _buildBookmarksList(BuildContext context, AdhkaarBundle? bundle, bool isMl) {
    if (bundle == null) return const SizedBox();
    final subs = _bookmarkedKeys.map((k) => int.tryParse(k) ?? 0).map((id) => bundle.subCategoryById(id)).whereType<AdhkaarSubCategory>().toList();

    if (subs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const Icon(Icons.bookmark_border_rounded, size: 36, color: Color(0xFF64748B)),
              const SizedBox(height: 10),
              Text(
                'No bookmarked invocations yet',
                style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF8B949E)),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: subs.map((s) => _buildSubCategoryCard(context, bundle, s, isMl)).toList(),
    );
  }

  Widget _buildNamesShortcutCard(BuildContext context, bool isMl) {
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
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: JiraTheme.primaryBlue.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF93C5FD), size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Asmaul Husna • 99 Names of Allah',
                    style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'View all 99 sacred names with calligraphy & audio',
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF8B949E)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: JiraTheme.primaryBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildNamesInlineList(BuildContext context, List<AllahName> allNames, bool isMl) {
    final names = allNames.take(20).toList();
    return Column(
      children: names.map((name) {
        return HeartbeatTap(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NamesScreen()),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F242C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          name.number.toString().padLeft(2, '0'),
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF93C5FD)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.transliteration,
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFF0F6FC)),
                        ),
                        Text(
                          name.meaning,
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8B949E)),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  name.name,
                  style: const TextStyle(
                    fontFamily: 'HafsFont',
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF93C5FD),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuranicDuasShortcutCard(BuildContext context, bool isMl) {
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
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: JiraTheme.secondaryGreen.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            const Icon(Icons.menu_book_rounded, color: JiraTheme.secondaryGreen, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '40 Rabbana Quranic Duas',
                    style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sacred prayers revealed in the Holy Quran',
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF8B949E)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: JiraTheme.secondaryGreen),
          ],
        ),
      ),
    );
  }

  Widget _buildQuranicDuasInlineList(BuildContext context, AdhkaarBundle? bundle, bool isMl) {
    if (bundle == null) return const SizedBox();
    final duas = bundle.quranicDuaIds.take(15).map((id) => bundle.duas[id]).whereType<Dua>().toList();

    return Column(
      children: duas.map((d) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: HeartbeatTap(
            onTap: () => _openDua(context, bundle, d.id),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.dua,
                    style: const TextStyle(
                      fontFamily: 'HafsFont',
                      fontSize: 18,
                      color: Color(0xFFC7D2FE),
                      height: 1.5,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isMl ? d.trans : (d.descEn.isNotEmpty ? d.descEn : d.transli),
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8B949E)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        d.ref.isNotEmpty ? d.ref : 'Holy Quran',
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: JiraTheme.secondaryGreen),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF64748B)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.0,
          color: const Color(0xFF8B949E),
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
            const SizedBox(height: 12),
            Text(
              'No collections found for "$query"',
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
