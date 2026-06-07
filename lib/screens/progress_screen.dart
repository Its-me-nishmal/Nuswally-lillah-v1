import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/prayer_provider.dart';

class ProgressJournalScreen extends StatefulWidget {
  const ProgressJournalScreen({super.key});

  @override
  State<ProgressJournalScreen> createState() => _ProgressJournalScreenState();
}

class _ProgressJournalScreenState extends State<ProgressJournalScreen> {
  void _showAddHabitSheet(BuildContext context) {
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final titleController = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 6, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeColor = themeProvider.primaryAccent;
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              decoration: BoxDecoration(
                color: themeProvider.containerColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'New Daily Habit',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'e.g. Read Surah Yaseen 📖',
                      hintStyle: GoogleFonts.outfit(color: Colors.grey[500]),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target Time:',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          backgroundColor: activeColor.withValues(alpha: 0.1),
                          foregroundColor: activeColor,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: ColorScheme.dark(
                                    primary: activeColor,
                                    surface: themeProvider.containerColor,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setModalState(() {
                              selectedTime = picked;
                            });
                          }
                        },
                        icon: const Icon(Icons.access_time_filled_rounded, size: 16),
                        label: Text(
                          _format24hTo12h('${selectedTime.hour}:${selectedTime.minute}'),
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        final title = titleController.text.trim();
                        if (title.isNotEmpty) {
                          final hourStr = selectedTime.hour.toString().padLeft(2, '0');
                          final minStr = selectedTime.minute.toString().padLeft(2, '0');
                          journalProvider.addHabit(title, '$hourStr:$minStr');
                          Navigator.pop(context);
                          HapticFeedback.heavyImpact();
                        } else {
                          HapticFeedback.vibrate();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        foregroundColor: themeProvider.backgroundBottom,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'CREATE HABIT',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final journal = context.watch<JournalProvider>();
    final primaryColor = themeProvider.primaryAccent;
    final bgColor = themeProvider.backgroundBottom;

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final completedCount = journal.getCompletedCountForDate(todayStr);

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              themeProvider.backgroundTop,
              themeProvider.backgroundBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, primaryColor),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 8),
                    _buildStatsBanner(context, completedCount, themeProvider),
                    const SizedBox(height: 28),
                    _buildSectionHeader('PRAYER JOURNAL HISTORY', primaryColor),
                    const SizedBox(height: 12),
                    _buildHistoryList(context, journal, themeProvider),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader('DAILY HABITS', primaryColor),
                        GestureDetector(
                          onTap: () => _showAddHabitSheet(context),
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline_rounded, size: 14, color: primaryColor),
                              const SizedBox(width: 4),
                              Text(
                                'Add Habit',
                                style: GoogleFonts.outfit(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildHabitsList(context, journal, themeProvider),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
              HapticFeedback.lightImpact();
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Journal & Progress',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label, Color primaryColor) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        color: primaryColor.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildStatsBanner(BuildContext context, int completedToday, ThemeProvider themeProvider) {
    final activeColor = themeProvider.primaryAccent;
    final percent = completedToday / 5.0;

    String quote = 'Spiritual consistency builds closeness to Allah. ✨';
    if (completedToday == 5) {
      quote = 'Ma Sha Allah! Beautifully completed all prayers today! 🎉';
    } else if (completedToday >= 3) {
      quote = 'Consistency is the key to spiritual success. Keep going! 💪';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: activeColor.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Prayers",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$completedToday / 5 Prayers Completed',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: activeColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  quote,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Ring Indicator
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 68,
                height: 68,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 6,
                  backgroundColor: activeColor.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                ),
              ),
              Text(
                '${(percent * 100).toInt()}%',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

  int _parseTimeToMinutes(String timeStr) {
    try {
      final clean = timeStr.trim().toUpperCase();
      if (clean.contains('AM') || clean.contains('PM')) {
        final isPM = clean.contains('PM');
        final parts = clean.replaceAll('AM', '').replaceAll('PM', '').trim().split(':');
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        if (isPM && hour != 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;
        return hour * 60 + minute;
      } else {
        final parts = clean.split(':');
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        return hour * 60 + minute;
      }
    } catch (e) {
      return 0;
    }
  }

  String _format24hTo12h(String time24h) {
    try {
      final parts = time24h.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final isPM = hour >= 12;
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final displayMin = minute.toString().padLeft(2, '0');
      final period = isPM ? 'PM' : 'AM';
      return '$displayHour:$displayMin $period';
    } catch (_) {
      return time24h;
    }
  }

  Widget _buildHistoryList(BuildContext context, JournalProvider journal, ThemeProvider theme) {
    final activeColor = theme.primaryAccent;
    final formatter = DateFormat('yyyy-MM-dd');
    final displayFormatter = DateFormat('EEE, dd MMM');

    // Show last 7 days
    final list = List.generate(7, (index) {
      return DateTime.now().subtract(Duration(days: index));
    });

    return Container(
      decoration: BoxDecoration(
        color: theme.containerColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: activeColor.withValues(alpha: 0.05)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.03), height: 1),
        itemBuilder: (context, idx) {
          final date = list[idx];
          final dateKey = formatter.format(date);
          final displayStr = idx == 0 ? 'Today' : (idx == 1 ? 'Yesterday' : displayFormatter.format(date));

          final isFajr = journal.isPrayerCompleted(dateKey, 'Fajr');
          final isDhuhr = journal.isPrayerCompleted(dateKey, 'Dhuhr');
          final isAsr = journal.isPrayerCompleted(dateKey, 'Asr');
          final isMaghrib = journal.isPrayerCompleted(dateKey, 'Maghrib');
          final isIsha = journal.isPrayerCompleted(dateKey, 'Isha');

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    displayStr,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: idx == 0 ? Colors.white : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHistoryTickNode(context, 'F', isFajr, dateKey, () => journal.togglePrayerCompletion(dateKey, 'Fajr'), theme),
                      _buildHistoryTickNode(context, 'D', isDhuhr, dateKey, () => journal.togglePrayerCompletion(dateKey, 'Dhuhr'), theme),
                      _buildHistoryTickNode(context, 'A', isAsr, dateKey, () => journal.togglePrayerCompletion(dateKey, 'Asr'), theme),
                      _buildHistoryTickNode(context, 'M', isMaghrib, dateKey, () => journal.togglePrayerCompletion(dateKey, 'Maghrib'), theme),
                      _buildHistoryTickNode(context, 'I', isIsha, dateKey, () => journal.togglePrayerCompletion(dateKey, 'Isha'), theme),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryTickNode(
    BuildContext context,
    String label,
    bool isCompleted,
    String dateKey,
    VoidCallback onTap,
    ThemeProvider theme,
  ) {
    final activeColor = theme.primaryAccent;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return GestureDetector(
      onTap: () {
        if (!isCompleted && dateKey == todayStr) {
          final now = DateTime.now();
          final currentMinutes = now.hour * 60 + now.minute;
          final prayerProvider = context.read<PrayerProvider>();
          final todayTimes = prayerProvider.todayPrayerTimes;

          if (todayTimes != null) {
            String timeStr = "00:00";
            String fullName = "";
            switch (label) {
              case 'F':
                timeStr = todayTimes.fajr;
                fullName = 'Fajr';
                break;
              case 'D':
                timeStr = todayTimes.dhuhr;
                fullName = 'Dhuhr';
                break;
              case 'A':
                timeStr = todayTimes.asr;
                fullName = 'Asr';
                break;
              case 'M':
                timeStr = todayTimes.maghrib;
                fullName = 'Maghrib';
                break;
              case 'I':
                timeStr = todayTimes.isha;
                fullName = 'Isha';
                break;
            }

            final targetMinutes = _parseTimeToMinutes(_formatPrayerTime(fullName, timeStr));
            if (currentMinutes < targetMinutes) {
              HapticFeedback.vibrate();
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.lock_clock_rounded, color: theme.primaryAccent, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Cannot complete $fullName before its scheduled time (${_formatPrayerTime(fullName, timeStr)})",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: theme.containerColor,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.primaryAccent.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
              return;
            }
          }
        }

        onTap();
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted ? activeColor : Colors.white.withValues(alpha: 0.03),
          border: Border.all(
            color: isCompleted ? activeColor : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: isCompleted
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isCompleted ? theme.backgroundBottom : Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHabitsList(BuildContext context, JournalProvider journal, ThemeProvider theme) {
    final activeColor = theme.primaryAccent;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (journal.habits.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: theme.containerColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activeColor.withValues(alpha: 0.05)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.checklist_rounded, size: 40, color: activeColor.withValues(alpha: 0.15)),
              const SizedBox(height: 8),
              Text(
                'No daily habits yet',
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _showAddHabitSheet(context),
                child: Text(
                  'Add Your First Habit',
                  style: GoogleFonts.outfit(color: activeColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: journal.habits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final habit = journal.habits[idx];
        final isCompleted = journal.isHabitCompleted(habit.id, todayStr);

        // Explicitly format to 12h with AM/PM
        final formattedTime = _format24hTo12h(habit.time);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.containerColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCompleted ? activeColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.04),
              width: isCompleted ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (!isCompleted) {
                    final now = DateTime.now();
                    final currentMinutes = now.hour * 60 + now.minute;
                    final targetMinutes = _parseTimeToMinutes(habit.time);
                    if (currentMinutes < targetMinutes) {
                      HapticFeedback.vibrate();
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.lock_clock_rounded, color: theme.primaryAccent, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Cannot complete ${habit.title} before its scheduled time ($formattedTime)",
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: theme.containerColor,
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: theme.primaryAccent.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                  }

                  journal.toggleHabitCompletion(habit.id, todayStr);
                  HapticFeedback.mediumImpact();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? activeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCompleted ? activeColor : Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: isCompleted
                      ? Icon(
                          Icons.check_rounded,
                          color: theme.backgroundBottom,
                          size: 16,
                          weight: 900,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 12, color: activeColor.withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Text(
                          formattedTime,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: activeColor.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            journal.toggleHabitTimelineVisibility(habit.id);
                            HapticFeedback.lightImpact();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: habit.showOnHomeTimeline
                                  ? activeColor.withValues(alpha: 0.1)
                                  : Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  habit.showOnHomeTimeline
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                  size: 10,
                                  color: habit.showOnHomeTimeline
                                      ? activeColor
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  habit.showOnHomeTimeline ? 'Timeline' : 'Hidden',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: habit.showOnHomeTimeline
                                        ? activeColor
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                onPressed: () {
                  journal.deleteHabit(habit.id);
                  HapticFeedback.mediumImpact();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
