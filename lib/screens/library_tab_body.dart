import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/adhkaar.dart';
import '../providers/adhkaar_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/heartbeat_tap.dart';
import 'adhkaar_duas_screen.dart';
import 'haddad_screen.dart';
import 'moulid_reader_screen.dart';
import 'names_screen.dart';
import 'quranic_duas_screen.dart';
import 'aurad_category_screen.dart';
import '../theme/app_colors.dart';
import '../theme/home_design.dart';
import '../theme/jira_theme.dart';

class LibraryTabBody extends StatefulWidget {
  final String searchQuery;

  const LibraryTabBody({super.key, this.searchQuery = ''});

  @override
  State<LibraryTabBody> createState() => _LibraryTabBodyState();
}

class _LibraryTabBodyState extends State<LibraryTabBody> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdhkaarProvider>().load();
    });
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

    // All subcategories from dataset
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

        // Search Mode: Display live matching invocations
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
        ] else ...[
          // Default Clean View: Header + Recent Pills + 3x3 Categories Grid
          // 1. Classical Calligraphy Header
          _buildAuradHeader(tp, isDark, isMl),
          const SizedBox(height: 16),

          // 2. Recent Litanies Horizontal Carousel
          _buildSectionHeader(
            isMl ? 'സമീപകാലത്ത് പാരായണം ചെയ്തവ' : 'RECENT INVOCATIONS',
            tp,
          ),
          const SizedBox(height: 8),
          _buildRecentLiturgiesBar(context, tp, bundle, isDark, isMl),
          const SizedBox(height: 18),

          // 3. 3x3 App-Style Categories Grid
          _buildSectionHeader(
            isMl ? 'വിശുദ്ധ വിഭാഗങ്ങൾ' : 'CATEGORIES',
            tp,
          ),
          const SizedBox(height: 10),
          _buildAuradGridSystem(context, tp, bundle, isDark, isMl),
        ],

        SizedBox(height: 80 + MediaQuery.paddingOf(context).bottom),
      ],
    );
  }

  // 1. Classical Islamic Calligraphy Banner
  Widget _buildAuradHeader(ThemeProvider tp, bool isDark, bool isMl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? tp.surfaceColor : tp.containerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tp.primaryAccent.withValues(alpha: isDark ? 0.25 : 0.18),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: tp.primaryAccent.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'الأَوْرَادُ وَالْمَنَاقِب',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'AdobeArabic',
              fontSize: 34,
              fontWeight: FontWeight.bold,
              height: 1.1,
              color: JiraTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isMl
                ? 'വിശുദ്ധ ഔറാദുകൾ, അദ്കാറുകൾ, മൗലിദുകൾ'
                : 'SACRED LITURGIES, ADHKAAR & SUPPLICATIONS',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: tp.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // 2. Horizontal Recent Invocations Carousel
  Widget _buildRecentLiturgiesBar(
    BuildContext context,
    ThemeProvider tp,
    AdhkaarBundle? bundle,
    bool isDark,
    bool isMl,
  ) {
    final recentItems = [
      {
        'title': isMl ? 'റാത്തീബുൽ ഹദ്ദാദ്' : 'Haddad Ratheeb',
        'icon': Icons.menu_book_rounded,
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HaddadScreen()),
          );
        },
      },
      {
        'title': isMl ? 'മങ്കൂസ് മൗലിദ്' : 'Manqoos Moulid',
        'icon': Icons.auto_stories_rounded,
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MoulidReaderScreen()),
          );
        },
      },
      {
        'title': isMl ? 'പ്രഭാത ദിക്റുകൾ' : 'Morning Adhkaar',
        'icon': Icons.wb_sunny_outlined,
        'action': () => _openSubCategory(context, bundle, 1),
      },
      {
        'title': isMl ? 'പ്രദോഷ ദിക്റുകൾ' : 'Evening Adhkaar',
        'icon': Icons.nights_stay_outlined,
        'action': () => _openSubCategory(context, bundle, 2),
      },
      {
        'title': isMl ? 'നമസ്കാര ശേഷം' : 'Dua After Salah',
        'icon': Icons.mosque_outlined,
        'action': () => _openSubCategory(context, bundle, 30),
      },
      {
        'title': isMl ? '40 റബ്ബനാ' : '40 Rabbana Duas',
        'icon': Icons.auto_awesome_rounded,
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QuranicDuasScreen()),
          );
        },
      },
      {
        'title': isMl ? 'അസ്മാഉൽ ഹുസ്ന' : '99 Names of Allah',
        'icon': Icons.favorite_border_rounded,
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NamesScreen()),
          );
        },
      },
    ];

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: recentItems.length,
        itemBuilder: (context, index) {
          final item = recentItems[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: HeartbeatTap(
              onTap: () {
                HapticFeedback.selectionClick();
                (item['action'] as VoidCallback)();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? tp.surfaceColor : tp.containerColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: tp.borderColor,
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
                        fontSize: 12,
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


  void _openAuradCategory(
    BuildContext context,
    String key,
    String titleEn,
    String titleMl,
    IconData icon,
  ) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuradCategoryScreen(
          categoryKey: key,
          categoryTitleEn: titleEn,
          categoryTitleMl: titleMl,
          icon: icon,
        ),
      ),
    );
  }

  // 4. App-Style 3x3 Grid System
  Widget _buildAuradGridSystem(
    BuildContext context,
    ThemeProvider tp,
    AdhkaarBundle? bundle,
    bool isDark,
    bool isMl,
  ) {
    final gridItems = [
      {
        'key': 'dikr',
        'title': isMl ? 'ദിക്റുകൾ' : 'Dikr',
        'titleEn': 'Dikr',
        'titleMl': 'ദിക്റുകൾ',
        'sub': isMl ? 'അദ്കാറുകൾ' : 'Daily Adhkaar',
        'icon': Icons.wb_sunny_outlined,
      },
      {
        'key': 'dua',
        'title': isMl ? 'പ്രാർത്ഥനകൾ' : 'Dua',
        'titleEn': 'Dua',
        'titleMl': 'പ്രാർത്ഥനകൾ',
        'sub': isMl ? 'നമസ്കാര ദുആ' : 'Supplications',
        'icon': Icons.volunteer_activism_outlined,
      },
      {
        'key': 'swalath',
        'title': isMl ? 'സ്വലാത്തുകൾ' : 'Swalath',
        'titleEn': 'Swalath',
        'titleMl': 'സ്വലാത്തുകൾ',
        'sub': isMl ? 'നബി ﷺ മേൽ' : 'Salawat on Nabi',
        'icon': Icons.mosque_outlined,
      },
      {
        'key': 'moulid',
        'title': isMl ? 'മൗലിദുകൾ' : 'Moulid',
        'titleEn': 'Moulid',
        'titleMl': 'മൗലിദുകൾ',
        'sub': isMl ? 'മങ്കൂസ് മൗലിദ്' : 'Manqoos Moulid',
        'icon': Icons.auto_stories_outlined,
      },
      {
        'key': 'baith',
        'title': isMl ? 'ബൈത്തുകൾ' : 'Baith',
        'titleEn': 'Baith',
        'titleMl': 'ബൈത്തുകൾ',
        'sub': isMl ? 'കവിതകൾ' : 'Poetic Litanies',
        'icon': Icons.stars_outlined,
      },
      {
        'key': 'malappatt',
        'title': isMl ? 'മാലപ്പാട്ട്' : 'Malappatt',
        'titleEn': 'Malappatt',
        'titleMl': 'മാലപ്പാട്ട്',
        'sub': isMl ? 'മഹാന്മാർ' : 'Traditions & Odes',
        'icon': Icons.description_outlined,
      },
      {
        'key': 'ratheeb',
        'title': isMl ? 'റാത്തീബുകൾ' : 'Ratheeb',
        'titleEn': 'Ratheeb',
        'titleMl': 'റാത്തീബുകൾ',
        'sub': isMl ? 'ഹദ്ദാദ് റാത്തീബ്' : 'Ratib al-Haddad',
        'icon': Icons.nightlight_outlined,
      },
      {
        'key': 'majlisunnoor',
        'title': isMl ? 'മജ്‌ലിസുന്നൂർ' : 'Majlisunnoor',
        'titleEn': 'Majlisunnoor',
        'titleMl': 'മജ്‌ലിസുന്നൂർ',
        'sub': isMl ? 'ബദ്‌രീങ്ങൾ & യാസീൻ' : 'Badr & Yaseen',
        'icon': Icons.stars_rounded,
      },
      {
        'key': 'more',
        'title': isMl ? 'കൂടുതൽ' : 'More',
        'titleEn': 'More & Vault',
        'titleMl': 'കൂടുതൽ ഔറാദുകൾ',
        'sub': isMl ? 'റുഖ്‌യ & ജനാസ' : 'Ruqyah & Other',
        'icon': Icons.grid_view_rounded,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: gridItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final item = gridItems[index];
        return HeartbeatTap(
          onTap: () {
            _openAuradCategory(
              context,
              item['key'] as String,
              item['titleEn'] as String,
              item['titleMl'] as String,
              item['icon'] as IconData,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? tp.surfaceColor : tp.containerColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tp.borderColor, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: tp.primaryAccent.withValues(
                      alpha: isDark ? 0.16 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    size: 24,
                    color: tp.primaryAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['title'] as String,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tp.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['sub'] as String,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: tp.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
