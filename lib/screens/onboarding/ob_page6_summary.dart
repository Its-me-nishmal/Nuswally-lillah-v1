import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/prayer_provider.dart';
import '../../widgets/heartbeat_tap.dart';
import '../home_screen.dart';
import '../../theme/app_colors.dart';

class ObPage6Summary extends StatelessWidget {
  const ObPage6Summary({super.key});

  Future<void> _enterApp(BuildContext context) async {
    HapticFeedback.selectionClick();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
    } catch (_) {}

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watchTheme();
    final prayer = context.watch<PrayerProvider>();
    final locName = prayer.selectedLocation?.name ?? 'Kozhikode, Kerala';

    return Scaffold(
      backgroundColor: context.pageTop,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
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
                            color: context.cardTop,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.accent,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: context.accent.withValues(alpha: 0.35),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.check_rounded,
                              color: context.accent,
                              size: 42,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 2. Bismillah Calligraphy
                        Text(
                          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                          style: TextStyle(
                            fontFamily: 'HafsFont',
                            fontSize: 22,
                            color: context.accent,
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
                            color: context.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'May your daily prayers bring peace, focus,\nand divine barakah.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: context.textSecondary,
                            height: 1.45,
                          ),
                        ),

                        const Spacer(flex: 3),

                        // 4. Personalized Configuration Recap Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: context.cardTop,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: context.cardBorder),
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
                                  color: context.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 14),

                              _buildSummaryRow(
                                context: context,
                                icon: Icons.location_on_rounded,
                                iconColor: context.accent,
                                title: locName,
                                subtitle: 'Kerala Samastha Standard (18°)',
                                badge: 'ACTIVE ZONE',
                                badgeColor: context.accent,
                              ),

                              Divider(color: context.cardBorder, height: 20),

                              _buildSummaryRow(
                                context: context,
                                icon: Icons.notifications_active_rounded,
                                iconColor: context.accent,
                                title: 'Precise Solar Adhans',
                                subtitle: '5 Daily Prayers Configured',
                                badge: 'ENABLED',
                                badgeColor: context.accent,
                              ),

                              Divider(color: context.cardBorder, height: 20),

                              _buildSummaryRow(
                                context: context,
                                icon: Icons.auto_stories_rounded,
                                iconColor: context.gold,
                                title: 'Awraad & Habits',
                                subtitle: 'Morning & Evening Adhkaar',
                                badge: 'READY',
                                badgeColor: context.accent,
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
                              color: context.accent,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: context.accent.withValues(alpha: 0.4),
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
                                const Icon(
                                  Icons.mosque_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          'Tap anytime to open your daily dashboard',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: context.textMuted,
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required BuildContext context,
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
            color: context.cardBottom,
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
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: context.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            badge,
            style: GoogleFonts.outfit(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: badgeColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
