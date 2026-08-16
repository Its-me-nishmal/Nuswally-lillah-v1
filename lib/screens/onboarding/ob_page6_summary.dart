import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/prayer_provider.dart';
import '../../theme/jira_theme.dart';
import '../../widgets/heartbeat_tap.dart';
import '../home_screen.dart';

class ObPage6Summary extends StatelessWidget {
  const ObPage6Summary({super.key});

  Future<void> _enterApp(BuildContext context) async {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (ctx, anim, _) => const HomeScreen(),
        transitionsBuilder: (ctx, anim, _, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final prayer = context.watch<PrayerProvider>();
    final locName = prayer.selectedLocation?.name ?? 'Kozhikode, Kerala';

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // 1. Celebratory Glowing Emerald Emblem
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  shape: BoxShape.circle,
                  border: Border.all(color: JiraTheme.secondaryGreen, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: JiraTheme.secondaryGreen.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    color: JiraTheme.secondaryGreen,
                    size: 42,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 2. Bismillah Calligraphy
              const Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                style: TextStyle(
                  fontFamily: 'HafsFont',
                  fontSize: 22,
                  color: Color(0xFF93C5FD),
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 10),

              // 3. Heading
              Text(
                'Your Sanctuary is Ready',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF0F6FC),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'May your daily prayers bring peace, focus,\nand divine barakah.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF8B949E),
                  height: 1.45,
                ),
              ),

              const Spacer(flex: 3),

              // 4. Personalized Configuration Recap Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SETUP SUMMARY',
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        color: const Color(0xFF8B949E),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildSummaryRow(
                      icon: Icons.location_on_rounded,
                      iconColor: JiraTheme.primaryBlue,
                      title: locName,
                      subtitle: 'Kerala Samastha Standard (18°)',
                      badge: 'ACTIVE ZONE',
                      badgeColor: JiraTheme.primaryBlue,
                    ),

                    const Divider(color: Color(0xFF30363D), height: 20),

                    _buildSummaryRow(
                      icon: Icons.notifications_active_rounded,
                      iconColor: JiraTheme.secondaryGreen,
                      title: 'Precise Solar Adhans',
                      subtitle: '5 Daily Prayers Configured',
                      badge: 'ENABLED',
                      badgeColor: JiraTheme.secondaryGreen,
                    ),

                    const Divider(color: Color(0xFF30363D), height: 20),

                    _buildSummaryRow(
                      icon: Icons.auto_stories_rounded,
                      iconColor: const Color(0xFFFB923C),
                      title: 'Awraad & Habits',
                      subtitle: 'Morning & Evening Adhkaar',
                      badge: 'READY',
                      badgeColor: const Color(0xFF93C5FD),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // 5. Bottom Enter Sanctuary Action
              HeartbeatTap(
                onTap: () => _enterApp(context),
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: JiraTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: JiraTheme.primaryBlue.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ENTER SANCTUARY',
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.mosque_rounded, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Tap anytime to open your daily dashboard',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: const Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1F242C),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF0F6FC),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF8B949E),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            badge,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }
}
