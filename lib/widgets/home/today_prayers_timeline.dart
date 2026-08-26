import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/prayer_time_model.dart';
import '../../providers/prayer_provider.dart';
import '../../providers/journal_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/jira_theme.dart';
import '../heartbeat_tap.dart';

class TodayPrayersTimeline extends StatelessWidget {
  const TodayPrayersTimeline({super.key});

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

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final journalProvider = context.watch<JournalProvider>();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Selector<PrayerProvider, (PrayerTime?, String)>(
      selector: (_, provider) => (provider.todayPrayerTimes, provider.highlightedPrayerName),
      builder: (context, data, child) {
        final todayTimes = data.$1;
        final highlightedName = data.$2.isNotEmpty ? data.$2 : 'Asr';

        final prayers = [
          _PrayerRowData(
            id: 'Fajr',
            name: 'Fajr',
            time: todayTimes != null ? _formatPrayerTime('Fajr', todayTimes.fajr) : '05:08 AM',
            isCompleted: journalProvider.isPrayerCompleted(todayStr, 'Fajr'),
            isCurrent: highlightedName == 'Fajr',
          ),
          _PrayerRowData(
            id: 'Dhuhr',
            name: 'Dhuhr',
            time: todayTimes != null ? _formatPrayerTime('Dhuhr', todayTimes.dhuhr) : '12:28 PM',
            isCompleted: journalProvider.isPrayerCompleted(todayStr, 'Dhuhr'),
            isCurrent: highlightedName == 'Dhuhr',
          ),
          _PrayerRowData(
            id: 'Asr',
            name: 'Asr',
            time: todayTimes != null ? _formatPrayerTime('Asr', todayTimes.asr) : '04:32 PM',
            isCompleted: journalProvider.isPrayerCompleted(todayStr, 'Asr'),
            isCurrent: highlightedName == 'Asr',
          ),
          _PrayerRowData(
            id: 'Maghrib',
            name: 'Maghrib',
            time: todayTimes != null ? _formatPrayerTime('Maghrib', todayTimes.maghrib) : '06:44 PM',
            isCompleted: journalProvider.isPrayerCompleted(todayStr, 'Maghrib'),
            isCurrent: highlightedName == 'Maghrib',
          ),
          _PrayerRowData(
            id: 'Isha',
            name: 'Isha',
            time: todayTimes != null ? _formatPrayerTime('Isha', todayTimes.isha) : '08:02 PM',
            isCompleted: journalProvider.isPrayerCompleted(todayStr, 'Isha'),
            isCurrent: highlightedName == 'Isha',
          ),
        ];

        int completedCount = prayers.where((p) => p.isCompleted).length;
        double progress = (completedCount / 5.0).clamp(0.0, 1.0);
        final percentText = '${(progress * 100).toInt()}%';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row: TODAY'S PRAYERS + 60%
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
                minHeight: 3.5,
                backgroundColor: themeProvider.borderColor.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(JiraTheme.secondaryGreen),
              ),
            ),
            const SizedBox(height: 16),

            // Timeline List of Prayer Rows
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: prayers.length,
              itemBuilder: (context, index) {
                final item = prayers[index];
                final isFirst = index == 0;
                final isLast = index == prayers.length - 1;

                return _PrayerTimelineRow(
                  data: item,
                  isFirst: isFirst,
                  isLast: isLast,
                  onToggleCompleted: () {
                    HapticFeedback.selectionClick();
                    journalProvider.togglePrayerCompletion(todayStr, item.id);
                  },
                );
              },
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
  final bool isCurrent;

  _PrayerRowData({
    required this.id,
    required this.name,
    required this.time,
    required this.isCompleted,
    required this.isCurrent,
  });
}

class _PrayerTimelineRow extends StatelessWidget {
  final _PrayerRowData data;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onToggleCompleted;

  const _PrayerTimelineRow({
    required this.data,
    required this.isFirst,
    required this.isLast,
    required this.onToggleCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final surfaceColor = isDark ? JiraTheme.darkSurface : JiraTheme.lightSurface;
    final containerColor = isDark ? JiraTheme.darkContainer : JiraTheme.lightContainer;
    final borderColor = isDark ? JiraTheme.darkBorder : JiraTheme.lightBorder;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Connected Timeline Track
          SizedBox(
            width: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Connecting Vertical Line
                Positioned(
                  top: isFirst ? 24 : 0,
                  bottom: isLast ? 24 : 0,
                  child: Container(
                    width: 1.5,
                    color: isDark
                        ? const Color(0xFF30363D).withValues(alpha: 0.6)
                        : const Color(0xFFD0D7DE),
                  ),
                ),

                // Node Indicator
                HeartbeatTap(
                  onTap: onToggleCompleted,
                  child: _buildNode(
                    isDark: isDark,
                    containerColor: containerColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right Prayer Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: HeartbeatTap(
                onTap: onToggleCompleted,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: data.isCurrent
                          ? (isDark ? JiraTheme.darkBorder.withValues(alpha: 0.9) : JiraTheme.primaryBlue)
                          : borderColor.withValues(alpha: isDark ? 0.6 : 0.9),
                      width: data.isCurrent ? 1.4 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                      if (data.isCurrent && isDark)
                        BoxShadow(
                          color: JiraTheme.primaryBlue.withValues(alpha: 0.05),
                          blurRadius: 12,
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Prayer Name + Optional "NOW" Badge
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            data.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: data.isCurrent ? FontWeight.w600 : FontWeight.w500,
                              color: themeProvider.textPrimary,
                            ),
                          ),
                          if (data.isCurrent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: containerColor,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: borderColor.withValues(alpha: 0.5),
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                'NOW',
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: themeProvider.textSecondary,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Prayer Time
                      Text(
                        data.time,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: data.isCurrent ? 14.5 : 13.5,
                          fontWeight: data.isCurrent ? FontWeight.w600 : FontWeight.w400,
                          color: data.isCurrent
                              ? themeProvider.textPrimary
                              : themeProvider.textSecondary.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNode({
    required bool isDark,
    required Color containerColor,
  }) {
    if (data.isCompleted) {
      // Completed Checked Node
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F291E) : const Color(0xFFDCFCE7),
          shape: BoxShape.circle,
          border: Border.all(
            color: JiraTheme.secondaryGreen.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.check_rounded,
            size: 16,
            color: JiraTheme.secondaryGreen,
          ),
        ),
      );
    }

    if (data.isCurrent) {
      // Active "NOW" Clean Modern Node (No harsh neon glow)
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0C2B59) : const Color(0xFFE0EDFE),
          shape: BoxShape.circle,
          border: Border.all(
            color: JiraTheme.primaryBlue.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.access_time_filled_rounded,
            size: 15,
            color: JiraTheme.primaryBlue,
          ),
        ),
      );
    }

    // Upcoming Node with center dot
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: containerColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? const Color(0xFF30363D).withValues(alpha: 0.6)
              : const Color(0xFFD0D7DE),
          width: 1.0,
        ),
      ),
      child: Center(
        child: Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF484F58) : const Color(0xFF8B949E),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
