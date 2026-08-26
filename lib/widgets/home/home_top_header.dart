import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/prayer_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/jira_theme.dart';
import '../heartbeat_tap.dart';
import '../../screens/location_selection_screen.dart';
import '../../screens/notification_settings_screen.dart';
import '../../screens/settings_screen.dart';

class HomeTopHeader extends StatelessWidget {
  const HomeTopHeader({super.key});

  String _getHijriDateString() {
    final now = DateTime.now();
    final hijriMonths = [
      'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani',
      'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', 'Sha\'ban',
      'Ramadan', 'Shawwal', 'Dhu al-Qi\'dah', 'Dhu al-Hijjah'
    ];
    final refDate = DateTime(2026, 8, 2);
    final diffDays = now.difference(refDate).inDays;
    var day = 18 + diffDays;
    var monthIdx = 1;
    var year = 1448;

    while (day > 29) {
      day -= 29;
      monthIdx++;
      if (monthIdx >= 12) {
        monthIdx = 0;
        year++;
      }
    }

    return '$day ${hijriMonths[monthIdx]} $year AH';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final surfaceColor = isDark ? JiraTheme.darkSurface : JiraTheme.lightSurface;
    final borderColor = isDark ? JiraTheme.darkBorderSubtle : JiraTheme.lightBorderSubtle;

    return Selector<PrayerProvider, String>(
      selector: (_, provider) => provider.selectedLocation != null
          ? provider.selectedLocation!.name
          : 'Kozhikode, India',
      builder: (context, locationName, child) {
        final displayLoc = locationName.contains(',') ? locationName : '$locationName, India';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left Location Capsule
              HeartbeatTap(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LocationSelectionScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: borderColor, width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: themeProvider.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayLoc,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: themeProvider.textPrimary,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _getHijriDateString(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: themeProvider.textSecondary.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Right Action Buttons (Notification Bell + Settings Icon)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HeartbeatTap(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
                      );
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.notifications_none_rounded,
                          size: 19,
                          color: themeProvider.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  HeartbeatTap(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.tune_rounded,
                          size: 19,
                          color: themeProvider.textPrimary,
                        ),
                      ),
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
