import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/prayer_provider.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<PrayerProvider>();

    final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          image: const DecorationImage(
            image: AssetImage('assets/images/islamic_bg.png'),
            opacity: 0.03,
            repeat: ImageRepeat.repeat,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const SizedBox(height: 8),
                    _buildHeroCard(context),
                    const SizedBox(height: 24),
                    Text(
                      'PRAYER ALERTS CONFIGURATION',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.5,
                        color: colorScheme.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...prayers.map((prayer) => _buildPrayerConfigTile(context, provider, prayer, isDark)),
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

  Widget _buildAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Text(
            'Alerts & Notifications',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.ring_volume_rounded, color: Colors.white, size: 24),
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
              color: Colors.white.withValues(alpha: 0.85),
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
    bool isDark,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
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
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isExpanded ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.05),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isExpanded ? 0.08 : 0.03),
            blurRadius: 12,
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
                      color: isExpanded ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.6),
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
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Azan: $adhanSummary  |  Iqamah: $iqamahSummary',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: colorScheme.primary.withValues(alpha: 0.6),
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
                    Divider(color: colorScheme.primary.withValues(alpha: 0.1), height: 1),
                    const SizedBox(height: 20),
                    
                    // --- ADHAN NOTIFICATIONS ---
                    _buildSubHeader(context, 'Adhan (Call to Prayer) Alerts', Icons.volume_up_rounded),
                    const SizedBox(height: 12),
                    
                    // Adhan Sound type
                    _buildOptionsLabel(context, 'Alert Sound'),
                    const SizedBox(height: 8),
                    _buildSoundSelector(
                      context: context,
                      currentValue: adhanSound,
                      options: ['Silent', 'Chime', 'Beep Only', 'Full Adhan'],
                      onSelect: (sound) {
                        provider.updateAdhanSound(prayer, sound);
                        provider.playAlertSound(sound);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Adhan offset timing
                    _buildOptionsLabel(context, 'Remind Me'),
                    const SizedBox(height: 8),
                    _buildOffsetSelector(
                      context: context,
                      currentValue: adhanOffset,
                      options: [
                        (0, 'At Adhan time'),
                        (3, '3 mins before'),
                      ],
                      onSelect: (offset) => provider.updateAdhanOffset(prayer, offset),
                    ),
                    
                    const SizedBox(height: 24),
                    Divider(color: colorScheme.primary.withValues(alpha: 0.06), height: 1),
                    const SizedBox(height: 20),
                    
                    // --- IQAMAH NOTIFICATIONS ---
                    _buildSubHeader(context, 'Iqamah (Congregation) Alerts', Icons.people_rounded),
                    const SizedBox(height: 12),
                    
                    // Iqamah Sound type
                    _buildOptionsLabel(context, 'Alert Sound'),
                    const SizedBox(height: 8),
                    _buildSoundSelector(
                      context: context,
                      currentValue: iqamahSound,
                      options: ['Silent', 'Chime', 'Soft Beep', 'Default Alert'],
                      onSelect: (sound) {
                        provider.updateIqamahNotificationSound(prayer, sound);
                        provider.playAlertSound(sound);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Iqamah offset timing
                    _buildOptionsLabel(context, 'Remind Me'),
                    const SizedBox(height: 8),
                    _buildOffsetSelector(
                      context: context,
                      currentValue: iqamahOffset,
                      options: [
                        (0, 'At Iqamah time'),
                        (1, '1 min before'),
                        (2, '2 mins before'),
                        (3, '3 mins before'),
                        (5, '5 mins before'),
                      ],
                      onSelect: (offset) => provider.updateIqamahNotificationOffset(prayer, offset),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubHeader(BuildContext context, String label, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: colorScheme.secondary, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsLabel(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildSoundSelector({
    required BuildContext context,
    required String currentValue,
    required List<String> options,
    required Function(String) onSelect,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((sound) {
          final isSelected = currentValue == sound;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(sound),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onSelect(sound);
                  HapticFeedback.selectionClick();
                }
              },
              selectedColor: colorScheme.primary,
              labelStyle: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : colorScheme.onSurface,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOffsetSelector({
    required BuildContext context,
    required int currentValue,
    required List<(int, String)> options,
    required Function(int) onSelect,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) {
          final (offset, label) = option;
          final isSelected = currentValue == offset;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onSelect(offset);
                  HapticFeedback.selectionClick();
                }
              },
              selectedColor: colorScheme.secondary,
              labelStyle: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : colorScheme.onSurface,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
