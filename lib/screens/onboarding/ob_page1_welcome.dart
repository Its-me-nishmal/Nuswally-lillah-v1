import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/jira_theme.dart';
import '../../widgets/heartbeat_tap.dart';

class ObPage1Welcome extends StatelessWidget {
  final VoidCallback onNext;

  const ObPage1Welcome({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
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

                        // 1. Centerpiece Glowing Mosque Emblem
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B22),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF30363D), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: JiraTheme.primaryBlue.withValues(alpha: 0.35),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.mosque_rounded,
                              color: Color(0xFF93C5FD),
                              size: 38,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 2. Sacred Arabic Brand Calligraphy
                        const Text(
                          'نُصَلِّي لِلَّهِ',
                          style: TextStyle(
                            fontFamily: 'HafsFont',
                            fontSize: 32,
                            fontWeight: FontWeight.normal,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // 3. English Brand Title
                        Text(
                          'NUSWALLY LILLAH',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.5,
                            color: const Color(0xFFF0F6FC),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // 4. Tagline
                        Text(
                          'Your Daily Sanctuary for Prayer, Quran &\nRemembrance',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF8B949E),
                            height: 1.45,
                          ),
                        ),

                        const Spacer(flex: 3),

                        // 5. 3 High-Craft Feature Cards
                        _buildFeatureCard(
                          icon: Icons.access_time_rounded,
                          iconColor: JiraTheme.secondaryGreen,
                          title: 'Precise Prayer Timings',
                          subtitle: 'Verified Adhan & Silent Mosque Timings',
                        ),
                        const SizedBox(height: 10),
                        _buildFeatureCard(
                          icon: Icons.menu_book_rounded,
                          iconColor: JiraTheme.primaryBlue,
                          title: 'Complete Holy Quran',
                          subtitle: 'Full 114 Surahs, Word-by-Word & Tajweed',
                        ),
                        const SizedBox(height: 10),
                        _buildFeatureCard(
                          icon: Icons.shield_outlined,
                          iconColor: const Color(0xFFFB923C),
                          title: 'Authentic Awraad & Duas',
                          subtitle: '500+ Verified Supplications & Daily Wird',
                        ),

                        const Spacer(flex: 3),

                        // 6. Bottom Action Button
                        HeartbeatTap(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onNext();
                          },
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
                                  'BEGIN JOURNEY',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Subtitle
                        Text(
                          'Takes less than 1 minute to setup',
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
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1F242C),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF0F6FC),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF8B949E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
