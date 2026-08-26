import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/adhkaar.dart';
import '../providers/adhkaar_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/heartbeat_tap.dart';
import '../widgets/jira_header.dart';
import '../widgets/jira_screen.dart';
import 'adhkaar_subcategories_screen.dart';
import 'names_screen.dart';
import 'quranic_duas_screen.dart';

const String kMlFont = 'BalooChettan2';

class AwraadScreen extends StatefulWidget {
  const AwraadScreen({super.key});

  @override
  State<AwraadScreen> createState() => _AwraadScreenState();
}

class _AwraadScreenState extends State<AwraadScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdhkaarProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final isMl = tp.isMalayalam;
    final adhkaar = context.watch<AdhkaarProvider>();
    final bundle = adhkaar.bundle;

    if (adhkaar.isLoading && bundle == null) {
      return JiraScreen(
        child: Column(
          children: [
            JiraHeader(
              title: isMl ? 'അവ്റാദ് & അദ്കാർ' : 'AWRAAD & ADHKAAR',
              subtitle: isMl ? 'അധികൃത ദിക്‌റുകളുടെ സമാഹാരം' : 'AUTHENTIC ADHKAAR COLLECTION',
            ),
            Expanded(
              child: Center(
                child: CircularProgressIndicator(color: tp.primaryAccent),
              ),
            ),
          ],
        ),
      );
    }

    final categories = bundle?.categories ?? [];
    final query = _searchQuery.trim().toLowerCase();
    final filteredCategories = categories.where((cat) {
      if (query.isEmpty) return true;
      return cat.title.toLowerCase().contains(query) ||
          cat.titleEn.toLowerCase().contains(query);
    }).toList();

    return JiraScreen(
      child: Column(
        children: [
          JiraHeader(
            title: isMl ? 'അവ്റാദ് & അദ്കാർ' : 'AWRAAD & ADHKAAR',
            subtitle: isMl ? 'അധികൃത ദിക്‌റുകളുടെ സമാഹാരം' : 'AUTHENTIC ADHKAAR COLLECTION',
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 8),
                if (bundle != null) const _HeroBannerCard(),
                const SizedBox(height: 16),
                _SearchBar(
                  query: _searchQuery,
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 16),
                _QuickAccessGrid(),
                const SizedBox(height: 22),
                _SectionHeader(
                  title: isMl ? 'വിഭാഗങ്ങൾ' : 'CATEGORIES',
                ),
                const SizedBox(height: 12),
                if (filteredCategories.isEmpty)
                  _EmptySearchState(query: query)
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredCategories.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.15,
                    ),
                    itemBuilder: (context, index) {
                      final category = filteredCategories[index];
                      return _CategoryCard(category: category);
                    },
                  ),
                SizedBox(height: 24 + MediaQuery.paddingOf(context).bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBannerCard extends StatelessWidget {
  const _HeroBannerCard();

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final isMl = tp.isMalayalam;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tp.primaryAccent,
            tp.primaryAccent.withValues(alpha: 0.78),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: tp.primaryAccent.withValues(alpha: 0.22),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isMl ? 'അവ്റാദ് ലൈബ്രറി' : 'AWRAAD LIBRARY',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            isMl ? 'അവ്റാദ് & അദ്കാർ' : 'AWRAAD & ADHKAAR',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontFamily: isMl ? kMlFont : GoogleFonts.outfit().fontFamily,
              fontSize: 28,
              height: 1.1,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isMl ? 'അധികൃത പ്രാർത്ഥനകളും ദിക്‌റുകളും' : 'Authentic Adhkaar & Awraad Library',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final String query;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.query, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final isMl = tp.isMalayalam;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: tp.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: tp.borderColor.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: tp.primaryAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: query)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: query.length),
                ),
              onChanged: onChanged,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: tp.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: isMl ? 'വിഭാഗങ്ങൾ തിരയുക...' : 'Search categories...',
                hintStyle: GoogleFonts.outfit(
                  fontSize: 13,
                  color: tp.textMuted,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (query.isNotEmpty)
            GestureDetector(
              onTap: () => onChanged(''),
              child: Icon(Icons.close_rounded, color: tp.textMuted, size: 18),
            ),
        ],
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final isMl = tp.isMalayalam;

    return Row(
      children: [
        Expanded(
          child: _QuickTile(
            icon: Icons.menu_book_rounded,
            title: isMl ? 'ഖുർആനിക പ്രാർത്ഥനകൾ' : 'QURANIC DUAS',
            subtitle: isMl ? 'ഖുർആനിൽ നിന്നുള്ളവ' : 'Duas from Quran',
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuranicDuasScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickTile(
            icon: Icons.auto_awesome_rounded,
            title: isMl ? 'അസ്മാഉൽ ഹുസ്ന' : '99 NAMES OF ALLAH',
            subtitle: isMl ? 'അല്ലാഹുവിന്റെ 99 നാമങ്ങൾ' : 'Asmaul Husna',
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NamesScreen()),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final isMl = tp.isMalayalam;

    return HeartbeatTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: tp.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: tp.borderColor.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: tp.primaryAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: isMl ? kMlFont : GoogleFonts.outfit().fontFamily,
                      fontSize: isMl ? 11 : 10,
                      fontWeight: isMl ? FontWeight.bold : FontWeight.w800,
                      letterSpacing: isMl ? 0.0 : 0.3,
                      color: tp.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: tp.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final AdhkaarCategory category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final isMl = tp.isMalayalam;

    return HeartbeatTap(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdhkaarSubcategoriesScreen(category: category),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tp.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: tp.borderColor.withValues(alpha: 0.6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: tp.isDarkMode ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tp.primaryAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: tp.primaryAccent,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 17,
                  color: tp.textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
            const Spacer(),
            if (isMl) ...[
              Text(
                category.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: kMlFont,
                  fontSize: 14,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              Text(
                (category.titleEn.isNotEmpty ? category.titleEn : category.title).toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: tp.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();

    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: tp.primaryAccent,
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  final String query;

  const _EmptySearchState({required this.query});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final isMl = tp.isMalayalam;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: tp.textMuted),
          const SizedBox(height: 12),
          Text(
            isMl ? 'ഫലങ്ങളൊന്നും കണ്ടെത്തിയില്ല' : 'No matching categories found',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: tp.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isMl
                ? '"നമസ്കാരം", "പ്രഭാതം", അല്ലെങ്കിൽ "ഉറക്കം" എന്ന് തിരയുക'
                : 'Try searching for another topic like "Prayer", "Daily", or "Protection"',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: tp.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
