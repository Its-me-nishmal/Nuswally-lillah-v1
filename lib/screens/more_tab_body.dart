import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/home_design.dart';
import '../widgets/heartbeat_tap.dart';
import '../widgets/home/social_links_sheet.dart';
import 'app_update_screen.dart';
import 'audio_quran_screen.dart';
import 'awraad_screen.dart';
import 'developer_profile_screen.dart';
import 'haddad_screen.dart';
import 'names_screen.dart';
import 'notification_settings_screen.dart';
import 'progress_screen.dart';
import 'qibla_screen.dart';
import 'quranic_duas_screen.dart';
import 'settings_screen.dart';
import 'tasbeeh_screen.dart';

/// Everything that doesn't live on the Home, Quran, Library or Media tabs.
class MoreTabBody extends StatelessWidget {
  const MoreTabBody({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final sections = <_MoreSection>[
      _MoreSection('WORSHIP', [
        _MoreItem(
          'Qibla',
          'Find the direction',
          Icons.explore_rounded,
          (c) => const QiblaScreen(),
        ),
        _MoreItem(
          'Tasbeeh',
          'Dhikr counter',
          Icons.fingerprint_rounded,
          (c) => const TasbeehScreen(),
        ),
        _MoreItem(
          'Awraad',
          'Daily litanies',
          Icons.auto_stories_rounded,
          (c) => const AwraadScreen(),
        ),
        _MoreItem(
          'Haddad',
          'Ratib al-Haddad',
          Icons.menu_book_rounded,
          (c) => const HaddadScreen(),
        ),
      ]),
      _MoreSection('QURAN & DUA', [
        _MoreItem(
          'Audio Quran',
          'Listen & reflect',
          Icons.headphones_rounded,
          (c) => const AudioQuranScreen(),
        ),
        _MoreItem(
          '99 Names',
          'Asma-ul-Husna',
          Icons.auto_awesome_rounded,
          (c) => const NamesScreen(),
        ),
        _MoreItem(
          'Rabbana Duas',
          'Quranic duas',
          Icons.volunteer_activism_rounded,
          (c) => const QuranicDuasScreen(),
        ),
        _MoreItem(
          'Journal',
          'Prayer progress',
          Icons.insights_rounded,
          (c) => const ProgressJournalScreen(),
        ),
      ]),
      _MoreSection('APP', [
        _MoreItem(
          'Notifications',
          'Azan & Iqamah',
          Icons.notifications_active_rounded,
          (c) => const NotificationSettingsScreen(),
        ),
        _MoreItem(
          'Settings',
          'App preferences',
          Icons.tune_rounded,
          (c) => const SettingsScreen(),
        ),
        _MoreItem(
          'Updates',
          'Latest version',
          Icons.system_update_rounded,
          (c) => const AppUpdateScreen(),
        ),
        _MoreItem(
          'About',
          'The developer',
          Icons.person_outline_rounded,
          (c) => const DeveloperProfileScreen(),
        ),
      ]),
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 10),
        for (final section in sections) ...[
          _SectionHeader(title: section.title),
          const SizedBox(height: 10),
          _ItemGrid(items: section.items),
          const SizedBox(height: 20),
        ],
        const _FollowCard(),
        SizedBox(height: 92 + bottomInset),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: HomeDesign.goldText(isDark),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(height: 1, color: HomeDesign.goldLine(isDark)),
        ),
      ],
    );
  }
}

class _ItemGrid extends StatelessWidget {
  final List<_MoreItem> items;

  const _ItemGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 76,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _MoreTile(item: items[i]),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final _MoreItem item;

  const _MoreTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Semantics(
      button: true,
      label: '${item.label}. ${item.caption}',
      child: HeartbeatTap(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(context, MaterialPageRoute(builder: item.builder));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: HomeDesign.cardGradient(isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HomeDesign.goldLine(isDark), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: HomeDesign.shadow(isDark),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: themeProvider.primaryAccent.withValues(
                    alpha: isDark ? 0.13 : 0.11,
                  ),
                  border: Border.all(
                    color: themeProvider.primaryAccent.withValues(
                      alpha: isDark ? 0.24 : 0.28,
                    ),
                  ),
                ),
                child: Center(
                  child: Icon(
                    item.icon,
                    size: 18,
                    color: themeProvider.primaryAccent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: themeProvider.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: themeProvider.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FollowCard extends StatelessWidget {
  const _FollowCard();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return HeartbeatTap(
      onTap: () => SocialLinksSheet.show(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: HomeDesign.cardGradient(isDark),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: HomeDesign.goldLineStrong(isDark),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.favorite_rounded, size: 18, color: HomeDesign.gold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Follow Nuswally Lillah',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: themeProvider.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Channels, groups and social links',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: themeProvider.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: HomeDesign.goldText(isDark),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreSection {
  final String title;
  final List<_MoreItem> items;

  const _MoreSection(this.title, this.items);
}

class _MoreItem {
  final String label;
  final String caption;
  final IconData icon;
  final WidgetBuilder builder;

  const _MoreItem(this.label, this.caption, this.icon, this.builder);
}
