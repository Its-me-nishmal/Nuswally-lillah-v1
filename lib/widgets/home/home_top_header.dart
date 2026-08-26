import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/prayer_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/jira_theme.dart';
import '../heartbeat_tap.dart';
import '../theme_palette_sheet.dart';
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

        return Container(
          height: 56.0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Location Selector (Clean & Borderless)
              HeartbeatTap(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LocationSelectionScreen()),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: themeProvider.primaryAccent.withValues(alpha: isDark ? 0.12 : 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.my_location_rounded,
                          size: 15,
                          color: themeProvider.primaryAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayLoc,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: themeProvider.textPrimary,
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: themeProvider.textSecondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _getHijriDateString(),
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: themeProvider.textSecondary.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right Action Buttons (Theme + Notifications + Settings)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Theme Palette Switcher Button
                  HeartbeatTap(
                    onTap: () => ThemePaletteSheet.show(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.palette_outlined,
                          size: 18,
                          color: themeProvider.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Notifications Button
                  Consumer<PrayerProvider>(
                  builder: (context, prayerProvider, _) {
                    final isAzanOn = prayerProvider.azanNotificationsEnabled;

                    return HeartbeatTap(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
                        );
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor, width: 1.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              isAzanOn
                                  ? Icons.notifications_rounded
                                  : Icons.notifications_none_rounded,
                              size: 18,
                              color: themeProvider.textPrimary,
                            ),
                            if (isAzanOn)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 5.5,
                                  height: 5.5,
                                  decoration: BoxDecoration(
                                    color: themeProvider.primaryAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
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
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.tune_rounded,
                          size: 18,
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
