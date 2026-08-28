import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/prayer_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/home_design.dart';
import '../../utils/hijri_date.dart';
import '../heartbeat_tap.dart';
import '../../screens/location_selection_screen.dart';
import '../../screens/notification_settings_screen.dart';
import '../../screens/settings_screen.dart';

class HomeTopHeader extends StatelessWidget {
  const HomeTopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Selector<PrayerProvider, String>(
      selector: (_, provider) => provider.selectedLocation != null
          ? provider.selectedLocation!.name
          : 'Kozhikode, India',
      builder: (context, locationName, child) {
        final displayLoc = locationName.contains(',')
            ? locationName
            : '$locationName, India';

        return Container(
          height: 68.0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Location selector: gold-ringed pin + city + Hijri date.
              Expanded(
                child: HeartbeatTap(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LocationSelectionScreen(),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: themeProvider.primaryAccent.withValues(
                            alpha: isDark ? 0.14 : 0.10,
                          ),
                          border: Border.all(
                            color: HomeDesign.goldLine(isDark),
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.location_on_rounded,
                            size: 20,
                            color: themeProvider.primaryAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    displayLoc,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      color: themeProvider.textPrimary,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: HomeDesign.goldText(isDark),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              HijriDate.today(
                                offsetDays: themeProvider.hijriOffsetDays,
                              ).formatted,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: themeProvider.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Dark/light toggle, azan notifications, settings.
              _HeaderIconButton(
                icon: isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                iconColor: HomeDesign.gold,
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.read<ThemeProvider>().toggleDarkMode();
                },
              ),
              const SizedBox(width: 8),
              Consumer<PrayerProvider>(
                builder: (context, prayerProvider, _) {
                  final isAzanOn = prayerProvider.azanNotificationsEnabled;
                  return _HeaderIconButton(
                    icon: isAzanOn
                        ? Icons.notifications_rounded
                        : Icons.notifications_none_rounded,
                    iconColor: HomeDesign.gold,
                    showDot: isAzanOn,
                    dotColor: themeProvider.primaryAccent,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const NotificationSettingsScreen(),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                icon: Icons.tune_rounded,
                iconColor: themeProvider.textPrimary,
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool showDot;
  final Color? dotColor;

  const _HeaderIconButton({
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.showDot = false,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return HeartbeatTap(
      onTap: onTap,
      child: Container(
        // 44dp keeps the button at the platform minimum touch target.
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: HomeDesign.iconButtonFill(isDark),
          border: Border.all(color: HomeDesign.goldLine(isDark), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: HomeDesign.shadow(isDark),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 19, color: iconColor),
            if (showDot)
              Positioned(
                top: 9,
                right: 9,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
