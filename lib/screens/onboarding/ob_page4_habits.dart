import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/journal_provider.dart';
import '../../providers/theme_provider.dart';

// ─────────────────────────────────────────
// Preset habit data
// ─────────────────────────────────────────
class _PresetHabit {
  final String id;
  final String title;
  final String time;
  final String emoji;
  final String subtitle;
  bool selected;

  _PresetHabit({
    required this.id,
    required this.title,
    required this.time,
    required this.emoji,
    required this.subtitle,
    this.selected = false,
  });
}

class ObPage4Habits extends StatefulWidget {
  final VoidCallback onNext;
  const ObPage4Habits({super.key, required this.onNext});

  @override
  State<ObPage4Habits> createState() => _ObPage4HabitsState();
}

class _ObPage4HabitsState extends State<ObPage4Habits>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;

  final List<_PresetHabit> _presets = [
    _PresetHabit(
      id: 'ob_h1',
      title: 'Morning Adhkar',
      time: '06:00',
      emoji: '🌅',
      subtitle: 'Start your day with remembrance',
      selected: true,
    ),
    _PresetHabit(
      id: 'ob_h2',
      title: 'Evening Adhkar',
      time: '18:00',
      emoji: '🌇',
      subtitle: 'Evening remembrance before sunset',
      selected: false,
    ),
    _PresetHabit(
      id: 'ob_h3',
      title: 'Read Surah Mulk',
      time: '21:30',
      emoji: '📖',
      subtitle: 'Protection before sleeping',
      selected: true,
    ),
    _PresetHabit(
      id: 'ob_h4',
      title: '12 Sunnah Rakahs',
      time: '12:30',
      emoji: '🙏',
      subtitle: 'Daily Sunnah prayers',
      selected: false,
    ),
    _PresetHabit(
      id: 'ob_h5',
      title: 'Tahajjud Prayer',
      time: '03:30',
      emoji: '🌙',
      subtitle: 'The night prayer',
      selected: false,
    ),
    _PresetHabit(
      id: 'ob_h6',
      title: 'Quran Recitation',
      time: '08:00',
      emoji: '📿',
      subtitle: 'Daily Quran reading session',
      selected: false,
    ),
    _PresetHabit(
      id: 'ob_h7',
      title: 'Dhikr After Prayer',
      time: '06:30',
      emoji: '❤️',
      subtitle: 'Tasbih 33×33×33',
      selected: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _fadeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  int get _selectedCount => _presets.where((p) => p.selected).length;

  Future<void> _buildMyDay() async {
    HapticFeedback.mediumImpact();
    final journalProvider = context.read<JournalProvider>();

    // Delete existing default habits
    final existingIds = journalProvider.habits.map((h) => h.id).toList();
    for (final id in existingIds) {
      await journalProvider.deleteHabit(id);
    }

    // Add selected habits
    for (final preset in _presets.where((p) => p.selected)) {
      await journalProvider.addHabit(
        '${preset.emoji} ${preset.title}',
        preset.time,
      );
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.1),
                        border: Border.all(color: accent.withValues(alpha: 0.25)),
                      ),
                      child: Icon(Icons.auto_awesome_rounded, color: accent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Build Your Daily Rhythm',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: isSmall ? 17 : 21,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Select habits to track alongside your prayers.',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.4),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Selection count badge
                    if (_selectedCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accent.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          '$_selectedCount',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Habit list
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _presets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final p = _presets[i];
                    return _HabitPresetCard(
                      preset: p,
                      accent: accent,
                      cardColor: cardColor,
                      onToggle: () {
                        HapticFeedback.lightImpact();
                        setState(() => p.selected = !p.selected);
                      },
                    );
                  },
                ),
              ),

              // Buttons
              Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 10, 20, bottomPad + 16),
                child: _ObHabitGlowButton(
                  label: _selectedCount == 0
                      ? 'Continue Without Habits'
                      : 'Build My Day  ($_selectedCount selected)',
                  accent: accent,
                  isSecondary: _selectedCount == 0,
                  onTap: _buildMyDay,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitPresetCard extends StatelessWidget {
  final _PresetHabit preset;
  final Color accent;
  final Color cardColor;
  final VoidCallback onToggle;

  const _HabitPresetCard({
    required this.preset,
    required this.accent,
    required this.cardColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: preset.selected ? accent.withValues(alpha: 0.08) : cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: preset.selected ? accent.withValues(alpha: 0.4) : accent.withValues(alpha: 0.06),
            width: preset.selected ? 1.5 : 1,
          ),
          boxShadow: preset.selected
              ? [BoxShadow(color: accent.withValues(alpha: 0.12), blurRadius: 10)]
              : [],
        ),
        child: Row(
          children: [
            // Emoji container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: preset.selected ? 0.12 : 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accent.withValues(alpha: preset.selected ? 0.2 : 0.06),
                ),
              ),
              child: Center(
                child: Text(preset.emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.title,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: preset.selected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 11,
                          color: accent.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                        preset.time,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: accent.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '·  ${preset.subtitle}',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Toggle indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: preset.selected ? accent : Colors.transparent,
                border: Border.all(
                  color: preset.selected ? accent : Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: preset.selected
                    ? [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 8)]
                    : [],
              ),
              child: preset.selected
                  ? const Icon(Icons.check_rounded, color: Colors.black, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ObHabitGlowButton extends StatelessWidget {
  final String label;
  final Color accent;
  final VoidCallback onTap;
  final bool isSecondary;

  const _ObHabitGlowButton({
    required this.label,
    required this.accent,
    required this.onTap,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 58,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: !isSecondary
              ? LinearGradient(
                  colors: [accent, accent.withValues(alpha: 0.75)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isSecondary ? Colors.white.withValues(alpha: 0.04) : null,
          borderRadius: BorderRadius.circular(30),
          border: isSecondary
              ? Border.all(color: Colors.white.withValues(alpha: 0.08))
              : null,
          boxShadow: !isSecondary
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isSecondary ? Colors.white.withValues(alpha: 0.4) : Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: isSecondary ? Colors.white.withValues(alpha: 0.3) : Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}
