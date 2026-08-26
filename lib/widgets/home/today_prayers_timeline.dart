import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/prayer_time_model.dart';
import '../../providers/journal_provider.dart';
import '../../providers/prayer_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/jira_theme.dart';
import '../heartbeat_tap.dart';

/// Single unified grouped card for daily 5 prayers, replacing fragmented box cards.
class TodayPrayersTimeline extends StatelessWidget {
  const TodayPrayersTimeline({super.key});

  String _formatPrayerTime(String prayerName, String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final min = int.parse(parts[1]);
      final displayMin = min.toString().padLeft(2, '0');

      var isPM = false;
      if (prayerName == 'Sunrise' || prayerName == 'Fajr') {
        isPM = false;
      } else {
        // Dhuhr, Asr, Maghrib, Isha are all PM (unless Dhuhr is 11:xx AM)
        if (prayerName == 'Dhuhr' && hour == 11) {
          isPM = false;
        } else {
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final journalProvider = context.watch<JournalProvider>();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isDark = themeProvider.isDarkMode;
    final surfaceColor = isDark ? JiraTheme.darkSurface : JiraTheme.lightSurface;
    final borderColor = isDark ? JiraTheme.darkBorderSubtle : JiraTheme.lightBorderSubtle;

    return Selector<PrayerProvider, (PrayerTime?, String, String, bool)>(
      selector: (_, provider) => (
        provider.todayPrayerTimes,
        provider.nextPrayerName,
        provider.activePrayerName,
        provider.isPrayerActive,
      ),
      builder: (context, data, child) {
        final todayTimes = data.$1;
        final nextName = data.$2;
        final activeName = data.$3;
        final isPrayerActive = data.$4;

        final prayers = [
          _PrayerRowData(
            id: 'Fajr',
            name: 'Fajr',
            time: todayTimes != null ? _formatPrayerTime('Fajr', todayTimes.fajr) : '05:08 AM',
            isCompleted: journalProvider.isPrayerCompleted(todayStr, 'Fajr'),
            isOngoing: isPrayerActive && activeName == 'Fajr',
            isNext: !isPrayerActive && nextName == 'Fajr',
          ),
          _PrayerRowData(
            id: 'Dhuhr',
            name: 'Dhuhr',
            time: todayTimes != null ? _formatPrayerTime('Dhuhr', todayTimes.dhuhr) : '12:28 PM',
            isCompleted: journalProvider.isPrayerCompleted(todayStr, 'Dhuhr'),
            isOngoing: isPrayerActive && activeName == 'Dhuhr',
            isNext: !isPrayerActive && nextName == 'Dhuhr',
          ),
          _PrayerRowData(
            id: 'Asr',
            name: 'Asr',
            time: todayTimes != null ? _formatPrayerTime('Asr', todayTimes.asr) : '04:32 PM',
            isCompleted: journalProvider.isPrayerCompleted(todayStr, 'Asr'),
            isOngoing: isPrayerActive && activeName == 'Asr',
            isNext: !isPrayerActive && nextName == 'Asr',
          ),
          _PrayerRowData(
            id: 'Maghrib',
            name: 'Maghrib',
            time: todayTimes != null ? _formatPrayerTime('Maghrib', todayTimes.maghrib) : '06:44 PM',
            isCompleted: journalProvider.isPrayerCompleted(todayStr, 'Maghrib'),
            isOngoing: isPrayerActive && activeName == 'Maghrib',
            isNext: !isPrayerActive && nextName == 'Maghrib',
          ),
          _PrayerRowData(
            id: 'Isha',
            name: 'Isha',
            time: todayTimes != null ? _formatPrayerTime('Isha', todayTimes.isha) : '08:02 PM',
            isCompleted: journalProvider.isPrayerCompleted(todayStr, 'Isha'),
            isOngoing: isPrayerActive && activeName == 'Isha',
            isNext: !isPrayerActive && nextName == 'Isha',
          ),
        ];

        int completedCount = prayers.where((p) => p.isCompleted).length;
        double progress = (completedCount / 5.0).clamp(0.0, 1.0);
        final percentText = '${(progress * 100).toInt()}%';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row: TODAY'S PRAYERS + Progress percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "TODAY'S PRAYERS",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: themeProvider.textSecondary.withValues(alpha: 0.9),
                  ),
                ),
                Text(
                  percentText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: JiraTheme.secondaryGreen,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Linear Progress Indicator
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3.0,
                backgroundColor: themeProvider.borderColor.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(JiraTheme.secondaryGreen),
              ),
            ),
            const SizedBox(height: 14),

            // Unified Grouped Prayers Card
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: borderColor,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  children: List.generate(prayers.length, (index) {
                    final item = prayers[index];
                    final isLast = index == prayers.length - 1;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PrayerRowItem(
                          data: item,
                          onToggleCompleted: () {
                            HapticFeedback.selectionClick();
                            journalProvider.togglePrayerCompletion(todayStr, item.id);
                          },
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            thickness: 0.6,
                            indent: 52,
                            endIndent: 16,
                            color: borderColor.withValues(alpha: 0.35),
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PrayerRowData {
  final String id;
  final String name;
  final String time;
  final bool isCompleted;
  final bool isOngoing;
  final bool isNext;

  _PrayerRowData({
    required this.id,
    required this.name,
    required this.time,
    required this.isCompleted,
    required this.isOngoing,
    required this.isNext,
  });
}

class _PrayerRowItem extends StatelessWidget {
  final _PrayerRowData data;
  final VoidCallback onToggleCompleted;

  const _PrayerRowItem({
    required this.data,
    required this.onToggleCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return HeartbeatTap(
      onTap: onToggleCompleted,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: data.isOngoing
              ? JiraTheme.primaryBlue.withValues(alpha: isDark ? 0.08 : 0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            // Left Status Node (Tappable completion toggle)
            _buildStatusNode(isDark),
            const SizedBox(width: 14),

            // Prayer Name + Optional "NOW" Badge
            Expanded(
              child: Row(
                children: [
                  Text(
                    data.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: (data.isOngoing || data.isNext) ? FontWeight.w600 : FontWeight.w500,
                      color: data.isCompleted
                          ? (isDark ? const Color(0xFFD0D7DE) : const Color(0xFF1E293B))
                          : themeProvider.textPrimary,
                    ),
                  ),
                  if (data.isOngoing) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                      decoration: BoxDecoration(
                        color: JiraTheme.primaryBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: JiraTheme.primaryBlue.withValues(alpha: 0.35),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        'NOW',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: JiraTheme.primaryBlue,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Prayer Time
            Text(
              data.time,
              style: GoogleFonts.plusJakartaSans(
                fontSize: (data.isOngoing || data.isNext) ? 14 : 13.5,
                fontWeight: (data.isOngoing || data.isNext) ? FontWeight.w600 : FontWeight.w400,
                color: (data.isOngoing || data.isNext)
                    ? themeProvider.textPrimary
                    : themeProvider.textSecondary.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusNode(bool isDark) {
    if (data.isCompleted) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: JiraTheme.secondaryGreen,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.check_rounded,
            size: 13,
            color: Colors.white,
          ),
        ),
      );
    }

    if (data.isOngoing) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: JiraTheme.primaryBlue.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: JiraTheme.primaryBlue,
            width: 1.2,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.access_time_filled_rounded,
            size: 11,
            color: JiraTheme.primaryBlue,
          ),
        ),
      );
    }

    // Normal / Upcoming state
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: data.isNext
              ? JiraTheme.primaryBlue.withValues(alpha: 0.6)
              : (isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE)),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Container(
          width: 4.5,
          height: 4.5,
          decoration: BoxDecoration(
            color: data.isNext
                ? JiraTheme.primaryBlue
                : (isDark ? const Color(0xFF484F58) : const Color(0xFF8B949E)),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
