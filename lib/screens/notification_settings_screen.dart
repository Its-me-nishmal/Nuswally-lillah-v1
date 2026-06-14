import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/prayer_provider.dart';
import '../providers/theme_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  String? _expandedPrayer;

  final Map<String, IconData> _prayerIcons = {
    'Fajr': Icons.wb_twilight_rounded,
    'Dhuhr': Icons.wb_sunny_rounded,
    'Asr': Icons.wb_cloudy_rounded,
    'Maghrib': Icons.nights_stay_rounded,
    'Isha': Icons.nightlight_round,
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final primaryColor = theme.primaryAccent;
    final bgTop = theme.backgroundTop;
    final bgBottom = theme.backgroundBottom;
    final provider = context.watch<PrayerProvider>();

    final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

    return Scaffold(
      backgroundColor: bgBottom,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, primaryColor),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const SizedBox(height: 8),
                    _buildHeroCard(context, theme),
                    const SizedBox(height: 24),
                    Text(
                      'PRAYER ALERTS CONFIGURATION',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.5,
                        color: primaryColor.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...prayers.map((prayer) => _buildPrayerConfigTile(context, provider, prayer, theme)),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
          ),
          const SizedBox(width: 8),
          Text(
            'Alerts & Notifications',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, ThemeProvider theme) {
    final primaryColor = theme.primaryAccent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.containerColor,
            theme.containerColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: primaryColor.withValues(alpha: 0.15), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.04),
            blurRadius: 15,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.ring_volume_rounded, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 14),
              Text(
                'Personalized Alerts',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Configure offline sounds and custom reminder offsets for both Adhan and Iqamah calls individually for each of the 5 daily prayers.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerConfigTile(
    BuildContext context,
    PrayerProvider provider,
    String prayer,
    ThemeProvider theme,
  ) {
    final primaryColor = theme.primaryAccent;
    final cardColor = theme.containerColor;
    final isExpanded = _expandedPrayer == prayer;
    final icon = _prayerIcons[prayer] ?? Icons.notifications;

    // Get current configuration summaries
    final adhanSound = provider.adhanNotificationSounds[prayer] ?? 'Default Alert';
    final adhanOffset = provider.adhanNotificationOffsets[prayer] ?? 0;
    final iqamahSound = provider.iqamahNotificationSounds[prayer] ?? 'Default Alert';
    final iqamahOffset = provider.iqamahNotificationOffsets[prayer] ?? 0;

    String adhanSummary = adhanSound == 'Silent' ? 'Muted 🔇' : '$adhanSound 🔊';
    if (adhanOffset > 0) adhanSummary += ' (-${adhanOffset}m)';

    String iqamahSummary = iqamahSound == 'Silent' ? 'Muted 🔇' : '$iqamahSound 🔊';
    if (iqamahOffset > 0) iqamahSummary += ' (-${iqamahOffset}m)';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardColor,
            cardColor.withValues(alpha: isExpanded ? 0.9 : 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isExpanded ? primaryColor.withValues(alpha: 0.4) : primaryColor.withValues(alpha: 0.12),
          width: isExpanded ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isExpanded ? 0.2 : 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Header clickable row
            InkWell(
              onTap: () {
                setState(() {
                  _expandedPrayer = isExpanded ? null : prayer;
                });
                HapticFeedback.lightImpact();
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: isExpanded ? primaryColor : primaryColor.withValues(alpha: 0.6),
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prayer,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Azan: $adhanSummary  |  Iqamah: $iqamahSummary',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: primaryColor.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),
            
            // Expandable settings drawer
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  children: [
                    Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                    const SizedBox(height: 20),
                    
                    // --- ADHAN NOTIFICATIONS ---
                    _buildSubHeader(context, 'Adhan (Call to Prayer) Alerts', Icons.volume_up_rounded, primaryColor),
                    const SizedBox(height: 12),
                    
                    // Adhan Sound type
                    _buildOptionsLabel(context, 'Alert Sound'),
                    const SizedBox(height: 8),
                    _buildCustomSoundSelector(
                      context: context,
                      currentValue: adhanSound,
                      options: ['Silent', 'Chime', 'Beep Only', 'Full Adhan'],
                      onSelect: (sound) {
                        provider.updateAdhanSound(prayer, sound);
                        provider.playAlertSound(sound);
                      },
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 16),
                    
                    // Adhan offset timing
                    _buildOptionsLabel(context, 'Remind Me'),
                    const SizedBox(height: 8),
                    _buildCustomOffsetSelector(
                      context: context,
                      currentValue: adhanOffset,
                      options: [
                        (0, 'At Adhan'),
                        (3, '3m Before'),
                      ],
                      onSelect: (offset) => provider.updateAdhanOffset(prayer, offset),
                      primaryColor: primaryColor,
                    ),
                    
                    const SizedBox(height: 24),
                    Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                    const SizedBox(height: 20),
                    
                    // --- IQAMAH NOTIFICATIONS ---
                    _buildSubHeader(context, 'Iqamah (Congregation) Alerts', Icons.people_rounded, primaryColor),
                    const SizedBox(height: 12),
                    
                    // Iqamah Sound type
                    _buildOptionsLabel(context, 'Alert Sound'),
                    const SizedBox(height: 8),
                    _buildCustomSoundSelector(
                      context: context,
                      currentValue: iqamahSound,
                      options: ['Silent', 'Chime', 'Soft Beep', 'Default Alert'],
                      onSelect: (sound) {
                        provider.updateIqamahNotificationSound(prayer, sound);
                        provider.playAlertSound(sound);
                      },
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 16),
                    
                    // Iqamah offset timing
                    _buildOptionsLabel(context, 'Remind Me'),
                    const SizedBox(height: 8),
                    _buildCustomOffsetSelector(
                      context: context,
                      currentValue: iqamahOffset,
                      options: [
                        (0, 'At Iqamah'),
                        (1, '1m Before'),
                        (2, '2m Before'),
                        (3, '3m Before'),
                        (5, '5m Before'),
                      ],
                      onSelect: (offset) => provider.updateIqamahNotificationOffset(prayer, offset),
                      primaryColor: primaryColor,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubHeader(BuildContext context, String label, IconData icon, Color primaryColor) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsLabel(BuildContext context, String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildCustomSoundSelector({
    required BuildContext context,
    required String currentValue,
    required List<String> options,
    required Function(String) onSelect,
    required Color primaryColor,
  }) {
    return Row(
      children: options.map((sound) {
        final isSelected = currentValue == sound;
        final Color activeThemeColor;
        switch (sound) {
          case 'Silent':
            activeThemeColor = const Color(0xFF64748B);
            break;
          case 'Chime':
            activeThemeColor = const Color(0xFFFBBF24);
            break;
          default:
            activeThemeColor = primaryColor;
        }

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                onSelect(sound);
                HapticFeedback.lightImpact();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeThemeColor.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? activeThemeColor.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.08),
                    width: isSelected ? 1.2 : 0.8,
                  ),
                ),
                child: Center(
                  child: Text(
                    sound == 'Full Adhan' ? 'Adhan' : (sound == 'Default Alert' ? 'Default' : sound),
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? activeThemeColor : Colors.white.withValues(alpha: 0.4),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomOffsetSelector({
    required BuildContext context,
    required int currentValue,
    required List<(int, String)> options,
    required Function(int) onSelect,
    required Color primaryColor,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: options.map((option) {
          final (offset, label) = option;
          final isSelected = currentValue == offset;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                onSelect(offset);
                HapticFeedback.lightImpact();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? primaryColor.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.08),
                    width: isSelected ? 1.2 : 0.8,
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? primaryColor : Colors.white.withValues(alpha: 0.4),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
