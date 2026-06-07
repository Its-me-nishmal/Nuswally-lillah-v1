import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/quran_provider.dart';
import '../providers/prayer_provider.dart';
import 'location_selection_screen.dart';
import 'notification_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryAccent;
    final bgColor = themeProvider.backgroundBottom;
    final cardColor = themeProvider.containerColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: BoxDecoration(color: bgColor),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, primaryColor),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const SizedBox(height: 8),
                    _buildSectionLabel(context, 'GENERAL', primaryColor),
                    const SizedBox(height: 12),
                    _buildLocationCard(context, primaryColor, cardColor),
                    const SizedBox(height: 24),
                    _buildSectionLabel(context, 'APPEARANCE', primaryColor),
                    const SizedBox(height: 12),
                    _buildThemeCard(context, primaryColor, cardColor, themeProvider),
                    const SizedBox(height: 24),
                    _buildSectionLabel(context, 'NOTIFICATIONS', primaryColor),
                    const SizedBox(height: 12),
                    _buildNotificationCard(context, primaryColor, cardColor),
                    const SizedBox(height: 24),
                    _buildSectionLabel(context, 'QURAN', primaryColor),
                    const SizedBox(height: 12),
                    _buildFontSizeCard(context, primaryColor, cardColor),
                    const SizedBox(height: 24),
                    _buildSectionLabel(context, 'ABOUT', primaryColor),
                    const SizedBox(height: 12),
                    _buildAboutCard(context, primaryColor, cardColor, themeProvider),
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
            'Settings',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label, Color primaryColor) {
    return Text(
      label,
      style: GoogleFonts.hankenGrotesk(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.5,
        color: primaryColor.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, Color primaryColor, Color cardColor) {
    final normalColor = const Color(0xFFD4E4FA);
    final prayerProvider = context.watch<PrayerProvider>();
    final locationName = prayerProvider.selectedLocation != null
        ? '${prayerProvider.selectedLocation!.name}, ${prayerProvider.selectedLocation!.district}'
        : 'Not Selected';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LocationSelectionScreen(),
          ),
        );
        HapticFeedback.lightImpact();
      },
      child: _buildCard(
        context,
        cardColor,
        primaryColor,
        child: Row(
          children: [
            Icon(Icons.location_on_outlined, color: primaryColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prayer Time Location',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locationName,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: normalColor.withValues(alpha: 0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, Color primaryColor, Color cardColor) {
    final normalColor = const Color(0xFFD4E4FA);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationSettingsScreen(),
          ),
        );
        HapticFeedback.lightImpact();
      },
      child: _buildCard(
        context,
        cardColor,
        primaryColor,
        child: Row(
          children: [
            Icon(
              Icons.notifications_active_outlined,
              color: primaryColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alerts & Sounds',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Customize Adhan & Iqamah notifications',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: normalColor.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: normalColor.withValues(alpha: 0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeCard(BuildContext context, Color primaryColor, Color cardColor) {
    final normalColor = const Color(0xFFD4E4FA);
    final quranProvider = context.watch<QuranProvider>();

    return _buildCard(
      context,
      cardColor,
      primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.format_size_rounded, color: primaryColor, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Arabic Font Size',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '${quranProvider.fontSize.toInt()}px',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ',
              style: TextStyle(
                fontFamily: 'HafsFont',
                fontSize: quranProvider.fontSize,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: quranProvider.fontSize,
            min: 20,
            max: 50,
            divisions: 15,
            activeColor: primaryColor,
            inactiveColor: primaryColor.withValues(alpha: 0.12),
            onChanged: (value) => quranProvider.updateFontSize(value),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Small',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 11,
                  color: normalColor.withValues(alpha: 0.3),
                ),
              ),
              Text(
                'Large',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 11,
                  color: normalColor.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context, Color primaryColor, Color cardColor, ThemeProvider themeProvider) {
    final normalColor = const Color(0xFFD4E4FA);

    return _buildCard(
      context,
      cardColor,
      primaryColor,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: themeProvider.continueReadingBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.mosque_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nuswally Lillah',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Version 1.0.0 (Release)',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 8),
          Text(
            'Nuswally Lillah (🕌 I pray for the sake of Allah) is a premium, offline-first Islamic companion app providing precise astronomical prayer notifications, custom Adhan & Iqamah alarms, Quran recitation tracker, and a digital Tasbeeh counter, crafted with a modern, high-contrast, and distraction-free design.',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w400,
              color: normalColor.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Icon(Icons.code_rounded, color: primaryColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Developer & Creator',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: normalColor.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nishmal Vadakara',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.2),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link_rounded, color: primaryColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'GitHub',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
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

  Widget _buildThemeCard(BuildContext context, Color primaryColor, Color cardColor, ThemeProvider themeProvider) {
    return _buildCard(
      context,
      cardColor,
      primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: primaryColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Color Theme',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      themeProvider.themeName,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: AppThemeStyle.values.map((style) {
              final isSelected = themeProvider.themeStyle == style;
              Color dotColor;
              switch (style) {
                case AppThemeStyle.teal:
                  dotColor = const Color(0xFF2DD4BF);
                  break;
                case AppThemeStyle.gold:
                  dotColor = const Color(0xFFF59E0B);
                  break;
                case AppThemeStyle.emerald:
                  dotColor = const Color(0xFF10B981);
                  break;
                case AppThemeStyle.purple:
                  dotColor = const Color(0xFFC084FC);
                  break;
                case AppThemeStyle.crimson:
                  dotColor = const Color(0xFFFB7185);
                  break;
                case AppThemeStyle.ocean:
                  dotColor = const Color(0xFF38BDF8);
                  break;
              }

              return GestureDetector(
                onTap: () {
                  themeProvider.setThemeStyle(style);
                  HapticFeedback.mediumImpact();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? dotColor.withValues(alpha: 0.15) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? dotColor : Colors.white.withValues(alpha: 0.1),
                      width: isSelected ? 2 : 1.5,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: dotColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.black,
                              size: 14,
                              weight: 900,
                            )
                          : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, Color cardColor, Color primaryColor, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: primaryColor.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}
