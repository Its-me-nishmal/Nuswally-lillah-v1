import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/prayer_provider.dart';
import '../providers/quran_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/jira_theme.dart';
import '../widgets/heartbeat_tap.dart';
import '../widgets/quran/reciter_picker_sheet.dart';
import '../services/app_share_service.dart';
import 'app_update_screen.dart';
import 'developer_profile_screen.dart';
import 'location_selection_screen.dart';
import 'notification_settings_screen.dart';

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
      backgroundColor: const Color(0xFF161B22),
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
                      color: const Color(0xFF30363D),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Arabic Font Size (${tempSize.toInt()} px)',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFF0F6FC),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Preview Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0E14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF30363D)),
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
                      activeTrackColor: JiraTheme.primaryBlue,
                      inactiveTrackColor: const Color(0xFF30363D),
                      thumbColor: Colors.white,
                      overlayColor: JiraTheme.primaryBlue.withValues(alpha: 0.2),
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
                      Text('Smaller (20px)', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF8B949E))),
                      Text('Default (30px)', style: GoogleFonts.inter(fontSize: 11.5, color: JiraTheme.primaryBlue)),
                      Text('Larger (44px)', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF8B949E))),
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
      backgroundColor: const Color(0xFF161B22),
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
                    color: const Color(0xFF30363D),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Asr Calculation Method',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF0F6FC),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F242C),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: JiraTheme.primaryBlue),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: JiraTheme.primaryBlue, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Standard (Shafi'i, Hanbali, Maliki)",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFF0F6FC),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Shadow length equals object height (1x ratio)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF8B949E),
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
    final notificationLabel = preAzanMin == 0 ? 'Exact Time (0 min)' : '$preAzanMin min before';

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0B0E14),
                  Color(0xFF0D121D),
                  Color(0xFF070A10),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 1. Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            color: const Color(0xFF161B22),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF30363D)),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_back_rounded,
                              size: 20,
                              color: Color(0xFFF0F6FC),
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
                              color: const Color(0xFFF0F6FC),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: JiraTheme.primaryBlue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: JiraTheme.primaryBlue.withValues(alpha: 0.8),
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
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 30 + MediaQuery.paddingOf(context).bottom),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Hero App Language Card
                      _buildLanguageHeroCard(context, themeProvider, isMalayalam),

                      const SizedBox(height: 24),

                      // Section 1: PRAYER & CALCULATION
                      _buildSectionHeader('PRAYER & CALCULATION'),
                      const SizedBox(height: 10),
                      _buildGroupContainer([
                        _buildSettingsTile(
                          icon: Icons.location_on_outlined,
                          title: 'Selected Location',
                          trailingValue: locationName,
                          trailingColor: const Color(0xFF93C5FD),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LocationSelectionScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFF30363D)),
                        _buildSettingsTile(
                          icon: Icons.notifications_active_outlined,
                          iconColor: JiraTheme.secondaryGreen,
                          title: 'Azan Notifications',
                          trailingValue: notificationLabel,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFF30363D)),
                        _buildSettingsTile(
                          icon: Icons.access_time_rounded,
                          title: 'Asr Calculation',
                          trailingValue: "Standard (Shafi'i/...)",
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _showAsrCalculationInfo(context);
                          },
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
                        const Divider(height: 1, color: Color(0xFF30363D)),
                        _buildSettingsTile(
                          icon: Icons.text_fields_rounded,
                          title: 'Arabic Font Size',
                          trailingValue: '${quranProvider.fontSize.toInt()} px (Default)',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _showFontSizePicker(context, quranProvider);
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFF30363D)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.menu_book_rounded, color: Color(0xFF8B949E), size: 20),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'Continuous Mushaf Reading',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFF0F6FC),
                                  ),
                                ),
                              ),
                              Switch.adaptive(
                                value: _continuousReadingMode,
                                onChanged: (val) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _continuousReadingMode = val);
                                },
                                activeThumbColor: JiraTheme.primaryBlue,
                                activeTrackColor: JiraTheme.primaryBlue.withValues(alpha: 0.4),
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
                          iconColor: const Color(0xFF34D399),
                          title: 'Share with Family & Friends',
                          trailingValue: 'Sadaqah Jariyah',
                          trailingColor: const Color(0xFF34D399),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            AppShareService.shareApp(context);
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFF30363D)),
                        _buildSettingsTile(
                          icon: Icons.star_rounded,
                          iconColor: const Color(0xFFFBBF24),
                          title: 'Rate & Review on Play Store',
                          trailingValue: '5 Stars',
                          trailingColor: const Color(0xFFFBBF24),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            AppShareService.openPlayStoreRating();
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFF30363D)),
                        _buildSettingsTile(
                          icon: Icons.feedback_outlined,
                          iconColor: const Color(0xFF38BDF8),
                          title: 'Feedback & Bug Reports',
                          trailingValue: 'Email Support',
                          trailingColor: const Color(0xFF93C5FD),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            AppShareService.sendFeedbackReport();
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFF30363D)),
                        _buildSettingsTile(
                          icon: Icons.person_outline_rounded,
                          iconColor: JiraTheme.primaryBlue,
                          title: 'About Developer',
                          trailingValue: 'Muhammed Nishmal',
                          trailingColor: const Color(0xFF93C5FD),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const DeveloperProfileScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFF30363D)),
                        _buildSettingsTile(
                          icon: Icons.info_outline_rounded,
                          title: 'App Updates & Version',
                          trailingValue: 'v1.0.0',
                          showChevron: true,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AppUpdateScreen()),
                            );
                          },
                        ),
                      ]),

                      const SizedBox(height: 36),

                      // Footer Attribution & Bismillah
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                              style: TextStyle(
                                fontFamily: 'HafsFont',
                                fontSize: 18,
                                color: Color(0xFF8B949E),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Crafted with Ihsan for the Ummah',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
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
  Widget _buildLanguageHeroCard(BuildContext context, ThemeProvider themeProvider, bool isMalayalam) {
    return Container(
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: JiraTheme.primaryBlue.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: JiraTheme.primaryBlue.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: Color(0xFF93C5FD),
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
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFF0F6FC),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select primary language for Adhkaar & Surahs',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF8B949E),
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
              color: const Color(0xFF0D121D),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF30363D)),
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
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !isMalayalam ? JiraTheme.primaryBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'ENGLISH',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: !isMalayalam ? FontWeight.w800 : FontWeight.w600,
                            color: !isMalayalam ? Colors.white : const Color(0xFF8B949E),
                            letterSpacing: 0.5,
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
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isMalayalam ? JiraTheme.primaryBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'MALAYALAM',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: isMalayalam ? FontWeight.w800 : FontWeight.w600,
                            color: isMalayalam ? Colors.white : const Color(0xFF8B949E),
                            letterSpacing: 0.5,
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
        style: GoogleFonts.outfit(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.0,
          color: const Color(0xFF8B949E),
        ),
      ),
    );
  }

  Widget _buildGroupContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
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
    return HeartbeatTap(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor ?? const Color(0xFF8B949E),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF0F6FC),
                ),
              ),
            ),
            if (trailingValue != null) ...[
              Text(
                trailingValue,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: trailingColor ?? const Color(0xFF8B949E),
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (showChevron)
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFF64748B),
              ),
          ],
        ),
      ),
    );
  }
}
