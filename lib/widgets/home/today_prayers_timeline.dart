import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/prayer_time_model.dart';
import '../../providers/journal_provider.dart';
import '../../providers/prayer_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/home_design.dart';
import '../../utils/prayer_time_format.dart';
import '../heartbeat_tap.dart';

/// Today's five prayers as one grouped card: a per-prayer identity icon on the
/// left, the time on the right, and a tappable completion check at the end.
class TodayPrayersTimeline extends StatelessWidget {
  const TodayPrayersTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final journalProvider = context.watch<JournalProvider>();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isDark = themeProvider.isDarkMode;

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

        String timeFor(String name, String? raw) =>
            raw == null ? '--:--' : formatPrayerTime(name, raw);

        final prayers = <_PrayerRowData>[
          for (final entry in <(String, String?)>[
            ('Fajr', todayTimes?.fajr),
            ('Dhuhr', todayTimes?.dhuhr),
            ('Asr', todayTimes?.asr),
            ('Maghrib', todayTimes?.maghrib),
            ('Isha', todayTimes?.isha),
          ])
            _PrayerRowData(
              id: entry.$1,
              name: entry.$1,
              time: timeFor(entry.$1, entry.$2),
              isCompleted: journalProvider.isPrayerCompleted(
                todayStr,
                entry.$1,
              ),
              isOngoing: isPrayerActive && activeName == entry.$1,
              isNext: !isPrayerActive && nextName == entry.$1,
            ),
        ];

        final completedCount = prayers.where((p) => p.isCompleted).length;
        // A count reads faster than a percentage for five items.
        final countText = '$completedCount/${prayers.length}';

        return Container(
          decoration: BoxDecoration(
            gradient: HomeDesign.cardGradient(isDark),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: HomeDesign.goldLine(isDark), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: HomeDesign.shadow(isDark),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: section label + completion percentage.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "TODAY'S PRAYERS",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: HomeDesign.goldText(isDark),
                      ),
                    ),
                    Text(
                      countText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: HomeDesign.goldText(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Node rail — one node per prayer, filled as they are marked.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ProgressRail(prayers: prayers),
              ),
              const SizedBox(height: 4),

              // Prayer rows.
              ...List.generate(prayers.length, (index) {
                final item = prayers[index];
                final isLast = index == prayers.length - 1;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PrayerRowItem(
                      data: item,
                      onToggleCompleted: () {
                        HapticFeedback.selectionClick();
                        journalProvider.togglePrayerCompletion(
                          todayStr,
                          item.id,
                        );
                      },
                    ),
                    if (!isLast)
                      Padding(
                        padding: const EdgeInsets.only(left: 64, right: 16),
                        child: Container(
                          height: 1.0,
                          color: HomeDesign.divider(isDark),
                        ),
                      ),
                  ],
                );
              }),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }
}

/// Horizontal rail of prayer nodes joined by segments.
class _ProgressRail extends StatelessWidget {
  final List<_PrayerRowData> prayers;

  const _ProgressRail({required this.prayers});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final accent = themeProvider.primaryAccent;
    final idle = HomeDesign.railIdle(isDark);

    final children = <Widget>[];
    for (var i = 0; i < prayers.length; i++) {
      if (i > 0) {
        // A segment is lit only when both of its endpoints are done.
        final lit = prayers[i - 1].isCompleted && prayers[i].isCompleted;
        children.add(
          Expanded(child: Container(height: 2, color: lit ? accent : idle)),
        );
      }
      final done = prayers[i].isCompleted;
      children.add(
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? accent : Colors.transparent,
            border: Border.all(
              color: done
                  ? accent
                  : (prayers[i].isNext || prayers[i].isOngoing
                        ? accent.withValues(alpha: 0.6)
                        : idle),
              width: 1.6,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 10,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
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

  const _PrayerRowItem({required this.data, required this.onToggleCompleted});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final tint = HomeDesign.prayerTint(data.name);
    final emphasised = data.isOngoing || data.isNext;

    return Semantics(
      button: true,
      selected: data.isCompleted,
      label: '${data.name} at ${data.time}',
      hint: data.isCompleted ? 'Marked as prayed' : 'Mark as prayed',
      child: HeartbeatTap(
        onTap: onToggleCompleted,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: data.isOngoing
              ? themeProvider.primaryAccent.withValues(
                  alpha: isDark ? 0.07 : 0.05,
                )
              : Colors.transparent,
          child: Row(
            children: [
              // Per-prayer identity icon.
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tint.withValues(alpha: isDark ? 0.13 : 0.11),
                  border: Border.all(
                    color: tint.withValues(alpha: isDark ? 0.24 : 0.28),
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: Icon(
                    HomeDesign.prayerIcon(data.name),
                    size: 19,
                    color: tint,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name + optional NOW badge.
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        data.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: emphasised
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: themeProvider.textPrimary,
                        ),
                      ),
                    ),
                    if (data.isOngoing) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: themeProvider.primaryAccent.withValues(
                            alpha: 0.13,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: themeProvider.primaryAccent.withValues(
                              alpha: 0.4,
                            ),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          'NOW',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: themeProvider.accentText,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Time.
              Text(
                data.time,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: emphasised ? FontWeight.w700 : FontWeight.w500,
                  color: emphasised
                      ? themeProvider.accentText
                      : themeProvider.textSecondary,
                ),
              ),
              const SizedBox(width: 12),

              // Completion check.
              _CompletionCheck(data: data),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionCheck extends StatelessWidget {
  final _PrayerRowData data;

  const _CompletionCheck({required this.data});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    if (data.isCompleted) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: HomeDesign.checkGreen(isDark),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.check_rounded, size: 17, color: Colors.white),
        ),
      );
    }

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
        border: Border.all(
          color: data.isOngoing || data.isNext
              ? themeProvider.primaryAccent.withValues(alpha: 0.55)
              : HomeDesign.divider(isDark),
          width: 1.4,
        ),
      ),
      child: data.isOngoing
          ? Center(
              child: Icon(
                Icons.access_time_rounded,
                size: 14,
                color: themeProvider.primaryAccent,
              ),
            )
          : null,
    );
  }
}
