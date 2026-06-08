import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/prayer_provider.dart';
import '../../providers/theme_provider.dart';

// Sound option model
class _SoundOption {
  final String key;
  final String label;
  final String subtitle;
  final IconData icon;
  const _SoundOption(
      {required this.key,
      required this.label,
      required this.subtitle,
      required this.icon});
}

const _soundOptions = [
  _SoundOption(
    key: 'Full Adhan',
    label: 'Full Adhan',
    subtitle: 'Complete Muezzin call',
    icon: Icons.volume_up_rounded,
  ),
  _SoundOption(
    key: 'Chime',
    label: 'Chime',
    subtitle: 'Gentle bell reminder',
    icon: Icons.notifications_active_rounded,
  ),
  _SoundOption(
    key: 'Silent',
    label: 'Silent',
    subtitle: 'No sound — vibrate only',
    icon: Icons.notifications_off_rounded,
  ),
];

const _prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
const _prayerArabic = {
  'Fajr': 'الفجر',
  'Dhuhr': 'الظهر',
  'Asr': 'العصر',
  'Maghrib': 'المغرب',
  'Isha': 'العشاء',
};
const _prayerEmoji = {
  'Fajr': '🌄',
  'Dhuhr': '☀️',
  'Asr': '🌤️',
  'Maghrib': '🌅',
  'Isha': '🌙',
};

class ObPage5Notifications extends StatefulWidget {
  final VoidCallback onNext;
  const ObPage5Notifications({super.key, required this.onNext});

  @override
  State<ObPage5Notifications> createState() => _ObPage5NotificationsState();
}

class _ObPage5NotificationsState extends State<ObPage5Notifications>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;

  // Local selection state — prayer name → sound key
  final Map<String, String> _selections = {
    'Fajr': 'Full Adhan',
    'Dhuhr': 'Full Adhan',
    'Asr': 'Full Adhan',
    'Maghrib': 'Full Adhan',
    'Isha': 'Full Adhan',
  };

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _fadeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // Apply all selections to PrayerProvider and proceed
  Future<void> _applyAndContinue() async {
    HapticFeedback.mediumImpact();
    final provider = context.read<PrayerProvider>();
    for (final prayer in _prayers) {
      await provider.updateAdhanSound(prayer, _selections[prayer]!);
    }
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final accent = theme.primaryAccent;
    final bgTop = theme.backgroundTop;
    final bgBottom = theme.backgroundBottom;
    final cardColor = theme.containerColor;
    final isSmall = MediaQuery.of(context).size.height < 680;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgTop, bgBottom],
        ),
      ),
      child: SafeArea(
        top: false,
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(20, isSmall ? 16 : 24, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.1),
                        border:
                            Border.all(color: accent.withValues(alpha: 0.25)),
                      ),
                      child: Icon(Icons.notifications_rounded,
                          color: accent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prayer Alerts',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: isSmall ? 18 : 21,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Choose how each prayer notifies you.',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Sound legend
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SoundLegend(accent: accent, cardColor: cardColor),
              ),

              const SizedBox(height: 16),

              // Prayer rows
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _prayers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final prayer = _prayers[i];
                    return _PrayerNotifRow(
                      prayer: prayer,
                      arabicName: _prayerArabic[prayer]!,
                      emoji: _prayerEmoji[prayer]!,
                      selectedSound: _selections[prayer]!,
                      accent: accent,
                      cardColor: cardColor,
                      onChanged: (sound) {
                        HapticFeedback.lightImpact();
                        setState(() => _selections[prayer] = sound);
                      },
                    );
                  },
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 10, 20, bottomPad + 16),
                child: _ObNotifGlowButton(
                  accent: accent,
                  onTap: _applyAndContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sound Legend ───
class _SoundLegend extends StatelessWidget {
  final Color accent;
  final Color cardColor;
  const _SoundLegend({required this.accent, required this.cardColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.07)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _soundOptions.map((opt) {
          return Row(
            children: [
              Icon(opt.icon, size: 13, color: accent.withValues(alpha: 0.7)),
              const SizedBox(width: 5),
              Text(
                opt.label,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Per-Prayer Notification Row ───
class _PrayerNotifRow extends StatelessWidget {
  final String prayer;
  final String arabicName;
  final String emoji;
  final String selectedSound;
  final Color accent;
  final Color cardColor;
  final ValueChanged<String> onChanged;

  const _PrayerNotifRow({
    required this.prayer,
    required this.arabicName,
    required this.emoji,
    required this.selectedSound,
    required this.accent,
    required this.cardColor,
    required this.onChanged,
  });

  Color _soundColor(String key, Color accent) {
    switch (key) {
      case 'Full Adhan':
        return accent;
      case 'Chime':
        return const Color(0xFFFBBF24);
      case 'Silent':
        return const Color(0xFF64748B);
      default:
        return accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sColor = _soundColor(selectedSound, accent);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          // Prayer name row
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prayer,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    Text(
                      arabicName,
                      style: TextStyle(
                        fontFamily: 'HafsFont',
                        fontSize: 11,
                        color: sColor.withValues(alpha: 0.7),
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
              // Current selection badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: sColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_iconForSound(selectedSound), size: 11, color: sColor),
                    const SizedBox(width: 4),
                    Text(
                      selectedSound,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: sColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Sound selector chips
          Row(
            children: _soundOptions.map((opt) {
              final isActive = selectedSound == opt.key;
              final c = _soundColor(opt.key, accent);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => onChanged(opt.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 36,
                      decoration: BoxDecoration(
                        color: isActive
                            ? c.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive
                              ? c.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.06),
                          width: isActive ? 1.2 : 0.8,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(opt.icon,
                              size: 13,
                              color: isActive
                                  ? c
                                  : Colors.white.withValues(alpha: 0.2)),
                          const SizedBox(height: 1),
                          Text(
                            opt.label == 'Full Adhan' ? 'Adhan' : opt.label,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 9,
                              fontWeight:
                                  isActive ? FontWeight.w700 : FontWeight.w400,
                              color: isActive
                                  ? c
                                  : Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _iconForSound(String key) {
    switch (key) {
      case 'Full Adhan':
        return Icons.volume_up_rounded;
      case 'Chime':
        return Icons.notifications_active_rounded;
      default:
        return Icons.notifications_off_rounded;
    }
  }
}

// ─── CTA Button ───
class _ObNotifGlowButton extends StatelessWidget {
  final Color accent;
  final VoidCallback onTap;
  const _ObNotifGlowButton({required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent, accent.withValues(alpha: 0.75)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.38),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Save & Continue',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_rounded,
                size: 18, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
