import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/prayer_provider.dart';
import '../providers/quran_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/heartbeat_tap.dart';
import '../widgets/quran/reciter_picker_sheet.dart';
import '../services/app_share_service.dart';
import 'app_update_screen.dart';
import 'developer_profile_screen.dart';
import 'location_selection_screen.dart';
import 'notification_settings_screen.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _continuousReadingMode = true;

  void _showReciterPicker(BuildContext context, QuranProvider quranProvider) {
    ReciterPickerSheet.show(context);
  }

  void _showFontSizePicker(BuildContext context, QuranProvider quranProvider) {
    double tempSize = quranProvider.fontSize;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardTop,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Arabic Font Size (${tempSize.toInt()} px)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Preview Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.pageTop,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.cardBorder),
                    ),
                    child: Center(
                      child: Text(
                        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                        style: TextStyle(
                          fontFamily: 'HafsFont',
                          fontSize: tempSize,
                          color: const Color(0xFFC7D2FE),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: context.accent,
                      inactiveTrackColor: context.cardBorder,
                      thumbColor: Colors.white,
                      overlayColor: context.accent.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: tempSize,
                      min: 20.0,
                      max: 44.0,
                      divisions: 12,
                      onChanged: (val) {
                        setModalState(() => tempSize = val);
                        quranProvider.updateFontSize(val);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Smaller (20px)',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: context.textSecondary,
                        ),
                      ),
                      Text(
                        'Default (30px)',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: context.accent,
                        ),
                      ),
                      Text(
                        'Larger (44px)',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAsrCalculationInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardTop,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Asr Calculation Method',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardBottom,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.accent),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: context.accent,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Standard (Shafi'i, Hanbali, Maliki)",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Shadow length equals object height (1x ratio)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watchTheme();
    final themeProvider = context.watch<ThemeProvider>();
    final prayerProvider = context.watch<PrayerProvider>();
    final quranProvider = context.watch<QuranProvider>();

    final isMalayalam = themeProvider.isMalayalam;
    final locationName = prayerProvider.selectedLocation != null
        ? '${prayerProvider.selectedLocation!.name}, ${prayerProvider.selectedLocation!.district}'
        : 'Kozhikode, Kerala';

    final qariFullName = quranProvider.selectedQariObj.name;
    final qariShortName = qariFullName.split(' ').take(2).join(' ');

    final preAzanMin = prayerProvider.preAzanReminderMinutes;
    final notificationLabel = preAzanMin == 0
        ? 'Exact Time (0 min)'
        : '$preAzanMin min before';

    return Scaffold(
      backgroundColor: context.pageTop,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.pageTop,
                  context.cardBottom,
                  context.pageBottom,
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 1. Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      HeartbeatTap(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: context.cardTop,
                            shape: BoxShape.circle,
                            border: Border.all(color: context.cardBorder),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.arrow_back_rounded,
                              size: 20,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'SETTINGS',
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: context.accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: context.accent.withValues(alpha: 0.8),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 40), // Balance
                    ],
                  ),
                ),

                // 2. Settings Group Lists
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      30 + MediaQuery.paddingOf(context).bottom,
                    ),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Hero App Language Card
                      _buildLanguageHeroCard(
                        context,
                        themeProvider,
                        isMalayalam,
                      ),

                      const SizedBox(height: 24),

                      // Section: APPEARANCE
                      _buildSectionHeader('APPEARANCE'),
                      const SizedBox(height: 10),
                      _buildGroupContainer([
                        _buildSettingsTile(
                          icon: themeProvider.isDarkMode
                              ? Icons.dark_mode_outlined
                              : Icons.light_mode_outlined,
                          iconColor: themeProvider.primaryAccent,
                          title: 'Dark Mode',
                          trailingValue: themeProvider.isDarkMode
                              ? 'On'
                              : 'Off',
                          trailingColor: themeProvider.primaryAccent,
                          showChevron: false,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            themeProvider.toggleDarkMode();
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.calendar_month_outlined,
                          iconColor: themeProvider.primaryAccent,
                          title: 'Hijri Date Adjustment',
                          trailingValue: _hijriOffsetLabel(
                            themeProvider.hijriOffsetDays,
                          ),
                          trailingColor: themeProvider.primaryAccent,
                          showChevron: false,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            themeProvider.cycleHijriOffsetDays();
                          },
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // Section 1: PRAYER & CALCULATION
                      _buildSectionHeader('PRAYER & CALCULATION'),
                      const SizedBox(height: 10),
                      _buildGroupContainer([
                        _buildSettingsTile(
                          icon: Icons.location_on_outlined,
                          title: 'Selected Location',
                          trailingValue: locationName,
                          trailingColor: context.accent,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const LocationSelectionScreen(),
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, color: context.cardBorder),
                        _buildSettingsTile(
                          icon: Icons.notifications_active_outlined,
                          iconColor: context.accent,
                          title: 'Azan Notifications',
                          trailingValue: notificationLabel,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, color: context.cardBorder),
                        _buildSettingsTile(
                          icon: Icons.access_time_rounded,
                          title: 'Asr Calculation',
                          trailingValue: "Standard (Shafi'i/...)",
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _showAsrCalculationInfo(context);
                          },
                        ),
                        Divider(height: 1, color: context.cardBorder),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.pin_drop_outlined,
                                color: themeProvider.primaryAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lock Screen Prayer Bar',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: context.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Live ongoing countdown on lock screen',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        color: context.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: prayerProvider.stickyNotificationEnabled,
                                onChanged: (val) {
                                  HapticFeedback.selectionClick();
                                  prayerProvider.setStickyNotificationEnabled(
                                    val,
                                  );
                                },
                                activeThumbColor: themeProvider.primaryAccent,
                                activeTrackColor: themeProvider.primaryAccent
                                    .withValues(alpha: 0.4),
                              ),
                            ],
                          ),
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // Section 2: QURAN & AUDIO PREFERENCES
                      _buildSectionHeader('QURAN & AUDIO PREFERENCES'),
                      const SizedBox(height: 10),
                      _buildGroupContainer([
                        _buildSettingsTile(
                          icon: Icons.headphones_outlined,
                          title: 'Default Reciter',
                          trailingValue: qariShortName,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _showReciterPicker(context, quranProvider);
                          },
                        ),
                        Divider(height: 1, color: context.cardBorder),
                        _buildSettingsTile(
                          icon: Icons.text_fields_rounded,
                          title: 'Arabic Font Size',
                          trailingValue:
                              '${quranProvider.fontSize.toInt()} px (Default)',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _showFontSizePicker(context, quranProvider);
                          },
                        ),
                        Divider(height: 1, color: context.cardBorder),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                color: context.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'Continuous Mushaf Reading',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ),
                              Switch.adaptive(
                                value: _continuousReadingMode,
                                onChanged: (val) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _continuousReadingMode = val);
                                },
                                activeThumbColor: context.accent,
                                activeTrackColor: context.accent.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // Section 3: ABOUT & COMMUNITY
                      _buildSectionHeader('ABOUT & COMMUNITY'),
                      const SizedBox(height: 10),
                      _buildGroupContainer([
                        _buildSettingsTile(
                          icon: Icons.share_rounded,
                          iconColor: context.accent,
                          title: 'Share with Family & Friends',
                          trailingValue: 'Sadaqah Jariyah',
                          trailingColor: context.accent,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            AppShareService.shareApp(context);
                          },
                        ),
                        Divider(height: 1, color: context.cardBorder),
                        _buildSettingsTile(
                          icon: Icons.star_rounded,
                          iconColor: context.gold,
                          title: 'Rate & Review on Play Store',
                          trailingValue: '5 Stars',
                          trailingColor: context.gold,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            AppShareService.openPlayStoreRating();
                          },
                        ),
                        Divider(height: 1, color: context.cardBorder),
                        _buildSettingsTile(
                          icon: Icons.feedback_outlined,
                          iconColor: context.accent,
                          title: 'Feedback & Bug Reports',
                          trailingValue: 'Email Support',
                          trailingColor: context.accent,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            AppShareService.sendFeedbackReport();
                          },
                        ),
                        Divider(height: 1, color: context.cardBorder),
                        _buildSettingsTile(
                          icon: Icons.person_outline_rounded,
                          iconColor: context.accent,
                          title: 'About Developer',
                          trailingValue: 'Muhammed Nishmal',
                          trailingColor: context.accent,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DeveloperProfileScreen(),
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, color: context.cardBorder),
                        _buildSettingsTile(
                          icon: Icons.info_outline_rounded,
                          title: 'App Updates & Version',
                          trailingValue: 'v1.0.0',
                          showChevron: true,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AppUpdateScreen(),
                              ),
                            );
                          },
                        ),
                      ]),

                      const SizedBox(height: 36),

                      // Footer Attribution & Bismillah
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                              style: TextStyle(
                                fontFamily: 'HafsFont',
                                fontSize: 18,
                                color: context.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Crafted with Ihsan for the Ummah',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: context.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Language Hero Card with Segmented Switcher
  Widget _buildLanguageHeroCard(
    BuildContext context,
    ThemeProvider themeProvider,
    bool isMalayalam,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardTop,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  Icons.language_rounded,
                  color: context.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Language',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select primary language for Adhkaar & Surahs',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Segmented Switcher
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: context.cardBottom,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.cardBorder),
            ),
            child: Row(
              children: [
                // ENGLISH
                Expanded(
                  child: HeartbeatTap(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      themeProvider.setAppLanguage('en');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: !isMalayalam
                            ? context.accent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'ENGLISH',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: !isMalayalam
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: !isMalayalam
                                ? Colors.white
                                : context.textSecondary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // MALAYALAM
                Expanded(
                  child: HeartbeatTap(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      themeProvider.setAppLanguage('ml');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: isMalayalam
                            ? context.accent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'MALAYALAM',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: isMalayalam
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isMalayalam
                                ? Colors.white
                                : context.textSecondary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: context.textSecondary,
        ),
      ),
    );
  }

  Widget _buildGroupContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardTop,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  /// The arithmetic Hijri calendar can sit a day either side of the local
  /// sighting; this label shows the user's chosen nudge.
  String _hijriOffsetLabel(int days) {
    if (days == 0) return 'Default';
    final unit = days.abs() == 1 ? 'day' : 'days';
    return '${days > 0 ? '+' : '-'}${days.abs()} $unit';
  }

  Widget _buildSettingsTile({
    required IconData icon,
    Color? iconColor,
    required String title,
    String? trailingValue,
    Color? trailingColor,
    bool showChevron = true,
    required VoidCallback onTap,
  }) {
    final themeProvider = context.read<ThemeProvider>();
    return HeartbeatTap(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? context.textSecondary),
            const SizedBox(width: 14),
            // Title gets the larger share; the value takes only what it
            // needs (loose fit) and ellipsises rather than overflowing.
            Expanded(
              flex: 5,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: themeProvider.textPrimary,
                ),
              ),
            ),
            if (trailingValue != null) ...[
              const SizedBox(width: 8),
              Flexible(
                flex: 4,
                fit: FlexFit.loose,
                child: Text(
                  trailingValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: trailingColor ?? themeProvider.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: themeProvider.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}
