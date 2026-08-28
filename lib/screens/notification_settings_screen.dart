import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/prayer_provider.dart';
import '../widgets/heartbeat_tap.dart';
import '../theme/app_colors.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  static const List<Map<String, dynamic>> _timingOptions = [
    {
      'minutes': 0,
      'title': 'Exact Azan Time',
      'subtitle': 'Triggers right when the Azan begins (0 min delay)',
      'icon': Icons.notifications_active_rounded,
    },
    {
      'minutes': 3,
      'title': '3 Minutes Before',
      'subtitle': 'Early reminder 3 minutes before Azan',
      'icon': Icons.timer_3_rounded,
    },
    {
      'minutes': 10,
      'title': '10 Minutes Before',
      'subtitle': 'Early reminder 10 minutes before Azan',
      'icon': Icons.timer_10_rounded,
    },
    {
      'minutes': 30,
      'title': '30 Minutes Before',
      'subtitle': 'Early reminder 30 minutes before Azan',
      'icon': Icons.hourglass_top_rounded,
    },
    {
      'minutes': 60,
      'title': '1 Hour Before',
      'subtitle': 'Early reminder 60 minutes before Azan',
      'icon': Icons.schedule_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    context.watchTheme();
    final provider = context.watch<PrayerProvider>();
    final isEnabled = provider.azanNotificationsEnabled;
    final selectedDelay = provider.preAzanReminderMinutes;

    return Scaffold(
      backgroundColor: context.pageTop,
      body: Stack(
        children: [
          // Ambient Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.pageTop,
                  context.cardBottom,
                  context.pageBottom,
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      HeartbeatTap(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: context.cardTop,
                            shape: BoxShape.circle,
                            border: Border.all(color: context.cardBorder),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.arrow_back_rounded,
                              size: 20,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isEnabled
                                  ? context.accent
                                  : context.textMuted,
                              shape: BoxShape.circle,
                              boxShadow: isEnabled
                                  ? [
                                      BoxShadow(
                                        color: context.accent.withValues(
                                          alpha: 0.8,
                                        ),
                                        blurRadius: 6,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AZAN NOTIFICATIONS',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 40), // Balance left back button
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      30 + MediaQuery.paddingOf(context).bottom,
                    ),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // 1. Hero Main Notification Toggle Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: context.cardTop,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isEnabled
                                ? context.accent.withValues(alpha: 0.6)
                                : context.cardBorder,
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isEnabled
                                  ? context.accent.withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.3),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isEnabled
                                    ? context.accent.withValues(alpha: 0.15)
                                    : context.cardBottom,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isEnabled
                                      ? context.accent.withValues(alpha: 0.5)
                                      : context.cardBorder,
                                ),
                              ),
                              child: Icon(
                                isEnabled
                                    ? Icons.notifications_active_rounded
                                    : Icons.notifications_off_outlined,
                                color: isEnabled
                                    ? context.accent
                                    : context.textSecondary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Daily Azan Alerts',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isEnabled
                                        ? 'Active for all 5 daily prayers'
                                        : 'Notifications are turned off',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: isEnabled,
                              onChanged: (val) {
                                HapticFeedback.selectionClick();
                                provider.toggleAzanNotifications(val);
                              },
                              activeThumbColor: context.accent,
                              activeTrackColor: context.accent.withValues(
                                alpha: 0.35,
                              ),
                              inactiveThumbColor: context.textSecondary,
                              inactiveTrackColor: context.cardBottom,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Sticky Lock Screen Prayer Bar Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: context.cardTop,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: provider.stickyNotificationEnabled
                                ? context.accent.withValues(alpha: 0.5)
                                : context.cardBorder,
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: provider.stickyNotificationEnabled
                                  ? context.accent.withValues(alpha: 0.10)
                                  : Colors.black.withValues(alpha: 0.3),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: provider.stickyNotificationEnabled
                                    ? context.accent.withValues(alpha: 0.15)
                                    : context.cardBottom,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: provider.stickyNotificationEnabled
                                      ? context.accent.withValues(alpha: 0.4)
                                      : context.cardBorder,
                                ),
                              ),
                              child: Icon(
                                Icons.pin_drop_rounded,
                                color: provider.stickyNotificationEnabled
                                    ? context.accent
                                    : context.textSecondary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lock Screen Prayer Bar',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Live ongoing countdown pinned to lock screen',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: provider.stickyNotificationEnabled,
                              onChanged: (val) {
                                HapticFeedback.selectionClick();
                                provider.setStickyNotificationEnabled(val);
                              },
                              activeThumbColor: context.accent,
                              activeTrackColor: context.accent.withValues(
                                alpha: 0.35,
                              ),
                              inactiveThumbColor: context.textSecondary,
                              inactiveTrackColor: context.cardBottom,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 2. Pre-Azan Timing / Delay Selection
                      Text(
                        'NOTIFICATION TIMING (ALL PRAYERS)',
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose when the reminder should sound relative to Azan time:',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.textMuted,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Timing Options List
                      ..._timingOptions.map((opt) {
                        final int mins = opt['minutes'];
                        final String title = opt['title'];
                        final String subtitle = opt['subtitle'];
                        final IconData icon = opt['icon'];
                        final bool isSelected =
                            isEnabled && selectedDelay == mins;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: HeartbeatTap(
                            onTap: () {
                              if (!isEnabled) {
                                provider.toggleAzanNotifications(true);
                              }
                              HapticFeedback.selectionClick();
                              provider.setPreAzanReminderMinutes(mins);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                // Accent-tinted selection, so it reads as
                                // "chosen" in light mode too.
                                color: isSelected
                                    ? context.accentSoft
                                    : context.cardTop,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? context.accent
                                      : context.cardBorder,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: context.accent.withValues(
                                            alpha: 0.18,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? context.accent.withValues(
                                              alpha: 0.2,
                                            )
                                          : context.cardBottom,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      icon,
                                      color: isSelected
                                          ? context.accent
                                          : context.textSecondary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: GoogleFonts.outfit(
                                            fontSize: 14.5,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : context.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          subtitle,
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            color: isSelected
                                                ? context.accent
                                                : context.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: context.accent,
                                      size: 22,
                                    )
                                  else
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: context.cardBorder,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 20),

                      // 3. Simple Summary Footer Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.cardTop.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: context.accent,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isEnabled
                                    ? (selectedDelay == 0
                                          ? 'Notifications are set to sound at exact Azan time for Fajr, Dhuhr, Asr, Maghrib, and Isha.'
                                          : 'Notifications are set to sound $selectedDelay minutes before every Azan.')
                                    : 'Enable Azan notifications above to receive prayer reminders.',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: context.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
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
