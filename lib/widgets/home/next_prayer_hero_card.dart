import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/prayer_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/jira_theme.dart';

class NextPrayerHeroCard extends StatefulWidget {
  const NextPrayerHeroCard({super.key});

  @override
  State<NextPrayerHeroCard> createState() => _NextPrayerHeroCardState();
}

class _NextPrayerHeroCardState extends State<NextPrayerHeroCard> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatPrayerTime(String prayerName, String timeStr) {
    try {
      final clean = timeStr.trim().toUpperCase();
      if (clean.contains('AM') || clean.contains('PM')) {
        return clean;
      }
      final parts = clean.split(':');
      var hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final displayMin = minute.toString().padLeft(2, '0');

      bool isPM = false;
      if (hour >= 12) {
        isPM = true;
      } else {
        if (prayerName == 'Fajr' || prayerName == 'Sunrise') {
          isPM = false;
        } else if (prayerName == 'Dhuhr') {
          isPM = true;
        } else if (prayerName == 'Asr' || prayerName == 'Maghrib' || prayerName == 'Isha') {
          isPM = true;
        }
      }

      var displayHour = hour;
      if (hour > 12) {
        displayHour = hour - 12;
      } else if (hour == 0) {
        displayHour = 12;
      }

      final period = isPM ? 'PM' : 'AM';
      return '$displayHour:$displayMin $period';
    } catch (_) {
      return timeStr;
    }
  }

  String _getPrayerTime(PrayerProvider provider, String prayerName) {
    if (provider.todayPrayerTimes == null) return '04:32 PM';
    switch (prayerName) {
      case 'Fajr':
        return _formatPrayerTime('Fajr', provider.todayPrayerTimes!.fajr);
      case 'Sunrise':
        return _formatPrayerTime('Sunrise', provider.todayPrayerTimes!.sunrise);
      case 'Dhuhr':
        return _formatPrayerTime('Dhuhr', provider.todayPrayerTimes!.dhuhr);
      case 'Asr':
        return _formatPrayerTime('Asr', provider.todayPrayerTimes!.asr);
      case 'Maghrib':
        return _formatPrayerTime('Maghrib', provider.todayPrayerTimes!.maghrib);
      case 'Isha':
        return _formatPrayerTime('Isha', provider.todayPrayerTimes!.isha);
      default:
        return '04:32 PM';
    }
  }

  String _getFormattedCountdown(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return 'in ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final surfaceColor = isDark ? JiraTheme.darkSurface : JiraTheme.lightSurface;
    final containerColor = isDark ? JiraTheme.darkContainer : JiraTheme.lightContainer;
    final borderColor = isDark ? JiraTheme.darkBorderSubtle : JiraTheme.lightBorderSubtle;

    return Consumer<PrayerProvider>(
      builder: (context, provider, child) {
        final nextPrayer = provider.nextPrayerName.isNotEmpty ? provider.nextPrayerName : 'Asr';
        final nextTimeStr = _getPrayerTime(provider, nextPrayer);
        final duration = provider.timeToNextPrayer;
        final countdownStr = _getFormattedCountdown(duration);

        return Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              if (isDark)
                BoxShadow(
                  color: JiraTheme.primaryBlue.withValues(alpha: 0.04),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Stack(
            children: [
              // Celestial Orbital Rings Graphic
              Positioned(
                right: -10,
                top: -10,
                bottom: -10,
                width: 190,
                child: CustomPaint(
                  painter: _CelestialOrbitsPainter(
                    isDark: isDark,
                    orbitColor: isDark
                        ? const Color(0xFF262C36).withValues(alpha: 0.4)
                        : const Color(0xFFE2E8F0).withValues(alpha: 0.7),
                    glowColor: JiraTheme.primaryBlue,
                  ),
                ),
              ),

              // Content Layout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Caption + Countdown Badge Pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'NEXT PRAYER',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            color: themeProvider.textSecondary.withValues(alpha: 0.9),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: containerColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: borderColor,
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF60A5FA),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                countdownStr,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: themeProvider.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Main Prayer Details (Name + Time)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          nextPrayer.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            height: 1.05,
                            color: themeProvider.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nextTimeStr,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: themeProvider.textSecondary.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CelestialOrbitsPainter extends CustomPainter {
  final bool isDark;
  final Color orbitColor;
  final Color glowColor;

  _CelestialOrbitsPainter({
    required this.isDark,
    required this.orbitColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.58, size.height * 0.52);

    final linePaint = Paint()
      ..color = orbitColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Outer Orbit 1
    canvas.drawCircle(center, 78, linePaint);

    // Clean subtle dashed or solid geometric orbital arcs
    final arcPaint = Paint()
      ..color = orbitColor.withValues(alpha: isDark ? 0.35 : 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Subtle third concentric ring for depth
    canvas.drawCircle(center, 46, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _CelestialOrbitsPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.orbitColor != orbitColor ||
        oldDelegate.glowColor != glowColor;
  }
}
