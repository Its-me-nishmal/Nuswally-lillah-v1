import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/prayer_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/jira_theme.dart';

/// Compact, modern Next Prayer Hero Card that avoids taking up excessive screen space.
class NextPrayerHeroCard extends StatefulWidget {
  const NextPrayerHeroCard({super.key});

  @override
  State<NextPrayerHeroCard> createState() => _NextPrayerHeroCardState();
}

class _NextPrayerHeroCardState extends State<NextPrayerHeroCard> {
  Timer? _localTimer;

  @override
  void initState() {
    super.initState();
    _localTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _localTimer?.cancel();
    super.dispose();
  }

  String _formatTo12Hour(String prayerName, String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length < 2) return timeStr;
      var hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      var isPM = false;
      if (prayerName == 'Sunrise' || prayerName == 'Fajr') {
        isPM = false;
      } else if (prayerName == 'Dhuhr') {
        isPM = hour == 11 ? false : true;
      } else {
        // Asr, Maghrib, Isha
        isPM = true;
      }

      var displayHour = hour;
      if (displayHour > 12) {
        displayHour -= 12;
      } else if (displayHour == 0) {
        displayHour = 12;
      }

      final minuteStr = minute.toString().padLeft(2, '0');
      final period = isPM ? 'PM' : 'AM';
      return '$displayHour:$minuteStr $period';
    } catch (_) {
      return timeStr;
    }
  }

  String _getPrayerTime(PrayerProvider provider, String prayerName) {
    final times = provider.todayPrayerTimes;
    if (times == null) return '--:--';
    switch (prayerName) {
      case 'Fajr':
        return _formatTo12Hour(prayerName, times.fajr);
      case 'Sunrise':
        return _formatTo12Hour(prayerName, times.sunrise);
      case 'Dhuhr':
        return _formatTo12Hour(prayerName, times.dhuhr);
      case 'Asr':
        return _formatTo12Hour(prayerName, times.asr);
      case 'Maghrib':
        return _formatTo12Hour(prayerName, times.maghrib);
      case 'Isha':
        return _formatTo12Hour(prayerName, times.isha);
      default:
        return '--:--';
    }
  }

  String _getFormattedCountdown(Duration duration) {
    if (duration.isNegative) return '00h 00m 00s';
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row: NEXT PRAYER Tag + Countdown Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: themeProvider.primaryAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'NEXT PRAYER',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: themeProvider.textSecondary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      countdownStr,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: themeProvider.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Bottom Row: Prayer Name + Large Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    nextPrayer.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: themeProvider.textPrimary,
                    ),
                  ),
                  Text(
                    nextTimeStr,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.primaryAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
