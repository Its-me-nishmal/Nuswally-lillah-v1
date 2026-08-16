import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/jira_theme.dart';
import '../../widgets/heartbeat_tap.dart';

class _PresetHabit {
  final String id;
  final String title;
  final String time;
  final IconData icon;
  final Color iconColor;
  final String subtitle;
  bool selected;

  _PresetHabit({
    required this.id,
    required this.title,
    required this.time,
    required this.icon,
    required this.iconColor,
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

class _ObPage4HabitsState extends State<ObPage4Habits> {
  final List<_PresetHabit> _presets = [
    _PresetHabit(
      id: 'ob_h1',
      title: 'Morning Adhkaar',
      time: '🌅 06:00 AM',
      icon: Icons.wb_sunny_outlined,
      iconColor: const Color(0xFF38BDF8),
      subtitle: 'Start your day with divine remembrance',
      selected: true,
    ),
    _PresetHabit(
      id: 'ob_h2',
      title: 'Evening Adhkaar',
      time: '🌇 06:00 PM',
      icon: Icons.nights_stay_outlined,
      iconColor: const Color(0xFFFB923C),
      subtitle: 'Evening protection before sunset',
      selected: true,
    ),
    _PresetHabit(
      id: 'ob_h3',
      title: 'Surah Al-Mulk Before Sleep',
      time: '🌙 09:30 PM',
      icon: Icons.menu_book_rounded,
      iconColor: JiraTheme.secondaryGreen,
      subtitle: 'Protection of the grave',
      selected: false,
    ),
    _PresetHabit(
      id: 'ob_h4',
      title: 'Surah Al-Kahf on Fridays',
      time: '🕌 Every Jumu\'ah',
      icon: Icons.mosque_outlined,
      iconColor: const Color(0xFFA855F7),
      subtitle: 'Illuminating light from Friday to Friday',
      selected: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // Title
              Text(
                'Build Your Daily Rhythm',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF0F6FC),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose the daily Islamic habits you want to track consistently.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFF8B949E),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              // Habits List
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _presets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final habit = _presets[index];
                    final isSelected = habit.selected;

                    return HeartbeatTap(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => habit.selected = !habit.selected);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? JiraTheme.primaryBlue : const Color(0xFF30363D),
                            width: isSelected ? 1.2 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: JiraTheme.primaryBlue.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F242C),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(habit.icon, color: habit.iconColor, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    habit.title,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFF0F6FC),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    habit.time,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF93C5FD),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? JiraTheme.primaryBlue : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? JiraTheme.primaryBlue : const Color(0xFF64748B),
                                  width: 1.5,
                                ),
                              ),
                              child: isSelected
                                  ? const Center(
                                      child: Icon(Icons.check, size: 14, color: Colors.white),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Action Dock
              Text(
                'You can easily customize times and add more habits later in Settings.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),

              HeartbeatTap(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onNext();
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: JiraTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: JiraTheme.primaryBlue.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'CONTINUE TO NOTIFICATIONS',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
