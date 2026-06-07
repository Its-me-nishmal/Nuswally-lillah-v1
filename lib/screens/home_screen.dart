import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/prayer_provider.dart';
import '../providers/quran_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/journal_provider.dart';
import '../models/quran_model.dart';
import 'haddad_screen.dart';
import 'tasbeeh_screen.dart';
import 'settings_screen.dart';
import 'progress_screen.dart';
import 'location_selection_screen.dart';
import 'audio_quran_screen.dart';
import 'notification_settings_screen.dart';
import 'qibla_screen.dart';
import 'surah_detail_screen.dart';
import '../services/notification_service.dart';
import '../models/prayer_time_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showSplash = true;
  int _currentTabIndex = 0;
  bool _isSearchingQuran = false;
  String _quranSearchQuery = '';
  final TextEditingController _quranSearchController = TextEditingController();

  @override
  void dispose() {
    _quranSearchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _startSplashTimer();
    
    // Check if the prayer provider has finished its async initialization.
    final provider = context.read<PrayerProvider>();
    if (provider.isInitialized) {
      _checkLocation();
    } else {
      late void Function() initializationListener;
      initializationListener = () {
        if (provider.isInitialized) {
          provider.removeListener(initializationListener);
          _checkLocation();
        }
      };
      provider.addListener(initializationListener);
    }
    
    // Request notification and exact alarm permissions after UI renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.requestPermissions();
    });
  }

  void _checkLocation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<PrayerProvider>();
      if (!provider.hasLocationSet && !provider.hasShownLocationSelection) {
        provider.markLocationAsAsked();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const LocationSelectionScreen(),
          ),
        );
      }
    });
  }

  void _startSplashTimer() {
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: themeProvider.backgroundBottom,
      extendBody: true,
      body: Stack(
        children: [
          // Background Gradient and Pattern
          Container(
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
          ),
          // Subtle Islamic geometric overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: Image.asset(
                'assets/images/islamic_bg.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Main Scrollable Content
          SafeArea(
            child: Column(
              children: [
                _buildNewAppBar(context),
                Expanded(
                  child: _buildActiveTabBody(context),
                ),
              ],
            ),
          ),
          // Pinned Slim Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _NewBottomNavigationBar(
              currentIndex: _currentTabIndex,
              onTabSelected: (index) {
                setState(() {
                  _currentTabIndex = index;
                  _isSearchingQuran = false;
                  _quranSearchQuery = '';
                  _quranSearchController.clear();
                });
              },
            ),
          ),
          if (_showSplash)
            _PrayerSplashOverlay(
              onDismiss: () {
                setState(() => _showSplash = false);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActiveTabBody(BuildContext context) {
    switch (_currentTabIndex) {
      case 0:
        final themeProvider = context.read<ThemeProvider>();
        return RefreshIndicator(
          onRefresh: () async {
            // Trigger location reload or calculation
            context.read<PrayerProvider>().todayPrayerTimes;
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: themeProvider.primaryAccent,
          backgroundColor: themeProvider.containerColor,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: const [
              SizedBox(height: 12),
              _NewUpcomingPrayerBanner(),
              SizedBox(height: 28),
              _NewDailyScheduleSection(),
              SizedBox(height: 100), // Standard bottom spacing for slim bar
            ],
          ),
        );
      case 1:
        return _QuranTabBody(searchQuery: _quranSearchQuery);
      case 2:
        return const _QiblaTabBody();
      default:
        return const SizedBox();
    }
  }

  Widget _buildNewAppBar(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    if (_currentTabIndex == 1) {
      // Holy Quran App Bar Mode
      if (_isSearchingQuran) {
        return Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: themeProvider.containerColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: themeProvider.primaryAccent.withValues(alpha: 0.15)),
                  ),
                  child: TextField(
                    controller: _quranSearchController,
                    autofocus: true,
                    onChanged: (v) {
                      setState(() {
                        _quranSearchQuery = v;
                      });
                    },
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search surah name or number...',
                      hintStyle: GoogleFonts.outfit(
                        color: const Color(0xFF94A3B8).withValues(alpha: 0.4),
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(Icons.search_rounded, color: themeProvider.primaryAccent, size: 18),
                      suffixIcon: _quranSearchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _quranSearchController.clear();
                                setState(() {
                                  _quranSearchQuery = '';
                                });
                              },
                              child: Icon(Icons.close_rounded, color: themeProvider.primaryAccent, size: 16),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  _quranSearchController.clear();
                  setState(() {
                    _isSearchingQuran = false;
                    _quranSearchQuery = '';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.primaryAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'HOLY QURAN',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            Row(
              children: [
                _buildThemeToggleButton(themeProvider),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSearchingQuran = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      size: 20,
                      color: Color(0xFFE2E8F0),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_currentTabIndex == 2) {
      // Qibla Finder App Bar Mode
      return Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'QIBLA FINDER',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            Row(
              children: [
                _buildThemeToggleButton(themeProvider),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      size: 20,
                      color: Color(0xFFE2E8F0),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Default Home App Bar Mode
    return Selector<PrayerProvider, String>(
      selector: (_, provider) => provider.selectedLocation != null
          ? '${provider.selectedLocation!.name}, ID'
          : 'Select Location',
      builder: (context, locationName, child) {
        return Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Location Selector
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LocationSelectionScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        locationName,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _buildThemeToggleButton(themeProvider),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProgressJournalScreen()),
                      );
                      HapticFeedback.lightImpact();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.bar_chart_rounded,
                        size: 20,
                        color: themeProvider.primaryAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        size: 20,
                        color: Color(0xFFE2E8F0),
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

  Widget _buildThemeToggleButton(ThemeProvider themeProvider) {
    return GestureDetector(
      onTap: () {
        themeProvider.toggleTheme();
        HapticFeedback.mediumImpact();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          shape: BoxShape.circle,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => RotationTransition(
            turns: anim,
            child: ScaleTransition(scale: anim, child: child),
          ),
          child: Icon(
            themeProvider.themeStyle == AppThemeStyle.teal 
                ? Icons.wb_sunny_rounded 
                : Icons.nights_stay_rounded,
            key: ValueKey(themeProvider.themeStyle),
            size: 20,
            color: themeProvider.primaryAccent,
          ),
        ),
      ),
    );
  }
}

class _NewUpcomingPrayerBanner extends StatelessWidget {
  const _NewUpcomingPrayerBanner();

  String _getPrayerTime(PrayerProvider provider, String prayerName) {
    if (provider.todayPrayerTimes == null) return '--:--';
    switch (prayerName) {
      case 'Fajr':
        return _formatPrayerTime('Fajr', provider.todayPrayerTimes!.fajr);
      case 'Sunrise':
        return _formatPrayerTime('Sunrise', provider.todayPrayerTimes!.sunrise);
      case 'Dhuhr':
        return _formatPrayerTime('Dhuhr', provider.todayPrayerTimes!.dhuhr);
      case 'Asr':
        return _formatPrayerTime('Asr', provider.todayPrayerTimes!.asr);
      case 'Maghrib':
        return _formatPrayerTime('Maghrib', provider.todayPrayerTimes!.maghrib);
      case 'Isha':
        return _formatPrayerTime('Isha', provider.todayPrayerTimes!.isha);
      default:
        return '--:--';
    }
  }

  @override
  Widget build(BuildContext context) {
    final quranProvider = Provider.of<QuranProvider>(context);
    final isQuranPlaying = quranProvider.playerState?.playing == true;

    return Consumer<PrayerProvider>(
      builder: (context, provider, child) {
        if (!provider.hasLocationSet || provider.todayPrayerTimes == null) {
          return const SizedBox();
        }

        final nextPrayer = provider.nextPrayerName;
        final nextTimeStr = _getPrayerTime(provider, nextPrayer);
        final isAlertPlaying = provider.isAlertSoundPlaying;
        final showWarningBanner = provider.showUpcomingAlertBanner;
        final isMuted = provider.temporarilyMutedAlerts.contains(nextPrayer);
        final adhanSound = provider.adhanNotificationSounds[nextPrayer] ?? 'Default Alert';

        final min = provider.upcomingAlertMinutesRemaining;
        final sec = provider.upcomingAlertSecondsRemaining;

        // Custom state styles based on alarms/warning states
        final themeProvider = context.watch<ThemeProvider>();
        Color leftBorderColor = themeProvider.primaryAccent;
        Color backgroundColor = themeProvider.containerColor;
        Widget trailingWidget;
        String titleText = 'Upcoming Prayer';
        String subtitleText = '$nextPrayer at $nextTimeStr';

        if (isAlertPlaying) {
          leftBorderColor = Colors.redAccent;
          backgroundColor = const Color(0xFF2D0F14);
          titleText = '$nextPrayer ALARM ACTIVE 🔔';
          subtitleText = 'Press Stop to silence the alert';
          trailingWidget = IconButton(
            onPressed: () {
              provider.stopAlertSound();
              HapticFeedback.mediumImpact();
            },
            icon: const Icon(Icons.stop_circle_rounded, color: Colors.white, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else if (showWarningBanner && adhanSound != 'Silent') {
          leftBorderColor = isMuted ? const Color(0xFF64748B) : Colors.orangeAccent;
          backgroundColor = isMuted ? const Color(0xFF1E293B) : const Color(0xFF2D220F);
          titleText = isMuted ? '$nextPrayer ALERT MUTED' : 'UPCOMING $nextPrayer ALERT';
          subtitleText = isMuted
              ? 'Alarm will be skipped'
              : 'Triggers in ${min}m ${sec.toString().padLeft(2, '0')}s';
          trailingWidget = TextButton(
            onPressed: () {
              provider.toggleTemporaryMute(nextPrayer);
              HapticFeedback.mediumImpact();
            },
            style: TextButton.styleFrom(
              backgroundColor: isMuted ? Colors.white.withValues(alpha: 0.05) : Colors.orangeAccent.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              isMuted ? 'UNMUTE' : 'MUTE',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isMuted ? const Color(0xFF94A3B8) : Colors.orangeAccent,
              ),
            ),
          );
        } else {
          // Standard Upcoming Prayer View (Matching Design)
          final duration = provider.timeToNextPrayer;
          final hours = duration.inHours;
          final minutes = duration.inMinutes.remainder(60);
          final countdownBadgeText = hours > 0
              ? 'IN ${hours}H ${minutes}M'
              : 'IN ${minutes}M';

          trailingWidget = Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: themeProvider.primaryAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              countdownBadgeText,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: themeProvider.backgroundBottom,
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border(
              left: BorderSide(
                color: leftBorderColor,
                width: 4,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Notification Bell Icon Container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: leftBorderColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAlertPlaying 
                      ? Icons.notifications_active_rounded 
                      : Icons.notifications_none_rounded,
                  color: leftBorderColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              // Upcoming Prayer Text Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleText,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitleText,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isQuranPlaying && !isMuted && !isAlertPlaying && showWarningBanner) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Quran audio will pause automatically',
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailingWidget,
            ],
          ),
        );
      },
    );
  }
}

class _NewBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const _NewBottomNavigationBar({
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.backgroundBottom,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                context: context,
                icon: Icons.home_filled,
                label: 'HOME',
                isActive: currentIndex == 0,
                onTap: () => onTabSelected(0),
              ),
              _buildBottomNavItem(
                context: context,
                icon: Icons.menu_book_rounded,
                label: 'QURAN',
                isActive: currentIndex == 1,
                onTap: () => onTabSelected(1),
              ),
              _buildBottomNavItem(
                context: context,
                icon: Icons.explore_outlined,
                label: 'QIBLA',
                isActive: currentIndex == 2,
                onTap: () => onTabSelected(2),
              ),
              _buildBottomNavItem(
                context: context,
                icon: Icons.grid_view_rounded,
                label: 'ALL',
                isActive: false,
                onTap: () => _showAllFeaturesSheet(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final themeProvider = context.watch<ThemeProvider>();
    final activeColor = themeProvider.primaryAccent;
    final inactiveColor = const Color(0xFF94A3B8).withValues(alpha: 0.6);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Highlight box if active
            isActive
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      color: activeColor,
                      size: 22,
                    ),
                  )
                : Icon(
                    icon,
                    color: inactiveColor,
                    size: 22,
                  ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isActive ? activeColor : inactiveColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllFeaturesSheet(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          decoration: BoxDecoration(
            color: themeProvider.containerColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag indicator
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Islamic Toolkit',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              // 2 rows of 4 items grid layout using Column/Row
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGridItem(
                        context: context,
                        icon: Icons.headset_rounded,
                        label: 'Audio Quran',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AudioQuranScreen()));
                        },
                      ),
                      _buildGridItem(
                        context: context,
                        icon: Icons.fingerprint_rounded,
                        label: 'Tasbih',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const TasbeehScreen()));
                        },
                      ),
                      _buildGridItem(
                        context: context,
                        icon: Icons.article_outlined,
                        label: 'Haddad',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const HaddadScreen()));
                        },
                      ),
                      _buildGridItem(
                        context: context,
                        icon: Icons.notifications_active_outlined,
                        label: 'Alarms Setup',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGridItem(
                        context: context,
                        icon: Icons.location_on_outlined,
                        label: 'Select Location',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationSelectionScreen()));
                        },
                      ),
                      _buildGridItem(
                        context: context,
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                        },
                      ),
                      _buildGridItem(
                        context: context,
                        icon: Icons.people_outline_rounded,
                        label: 'Ummah',
                        onTap: () {
                          Navigator.pop(context);
                          _showUmmahDialog(context);
                        },
                      ),
                      _buildGridItem(
                        context: context,
                        icon: Icons.info_outline_rounded,
                        label: 'About App',
                        onTap: () {
                          Navigator.pop(context);
                          _showAboutDialog(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final themeProvider = context.watch<ThemeProvider>();
    final activeColor = themeProvider.primaryAccent;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: activeColor.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: activeColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE2E8F0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUmmahDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final activeColor = themeProvider.primaryAccent;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: themeProvider.containerColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.people_alt_rounded,
                  color: activeColor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Ummah Community',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Connecting Muslims globally. This community and chat feature is currently in design/development and will be available in the next major update!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeColor,
                    foregroundColor: themeProvider.backgroundBottom,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    'Looking Forward to it!',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final activeColor = themeProvider.primaryAccent;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: themeProvider.containerColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  color: activeColor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Nuswally Lillah',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'A premium, privacy-first companion app for offline Quran reading, translations, audio playback, Dhikr/Tasbeeh counting, litanies, and highly customizable iqamah offset alarms.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeColor,
                    foregroundColor: themeProvider.backgroundBottom,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    'JazakAllah Khair',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SnakePathPainter extends CustomPainter {
  final int itemCount;
  final double rowHeight;
  final double baseX;
  final double amplitude;
  final Color dotColor;

  _SnakePathPainter({
    required this.itemCount,
    required this.rowHeight,
    required this.baseX,
    required this.amplitude,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double startY = -12.0;
    final double endY = itemCount * rowHeight - rowHeight / 2 + 20.0;
    final double stepY = 6.0; 
    
    for (double y = startY; y <= endY; y += stepY) {
      final double t = (y - rowHeight / 2) / rowHeight;
      final double x = baseX + amplitude * math.sin(t * math.pi / 2);
      final double ratio = (y - startY) / (endY - startY);
      
      final Paint paint = Paint()
        ..color = dotColor.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 2.0, paint);
      
      if (ratio > 0.0 && ratio < 1.0) {
        final Paint glowPaint = Paint()
          ..color = dotColor.withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(Offset(x, y), 4.0, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SnakePathPainter oldDelegate) => false;
}

class _TimelineRowItem {
  final String id;
  final String name;
  final String time;
  final IconData icon;
  final bool isPrayer;
  final bool isCompleted;
  final bool isCurrent;
  final int minutesFromMidnight;
  final String habitId;

  _TimelineRowItem({
    required this.id,
    required this.name,
    required this.time,
    required this.icon,
    required this.isPrayer,
    required this.isCompleted,
    required this.isCurrent,
    required this.minutesFromMidnight,
    required this.habitId,
  });
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

class _NewDailyScheduleSection extends StatelessWidget {
  const _NewDailyScheduleSection();

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('dd MMM').format(DateTime.now());
    final themeProvider = context.watch<ThemeProvider>();
    final journalProvider = context.watch<JournalProvider>();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Selector<PrayerProvider, (PrayerTime?, String)>(
      selector: (_, provider) => (provider.todayPrayerTimes, provider.highlightedPrayerName),
      builder: (context, data, child) {
        final todayTimes = data.$1;
        final highlightedName = data.$2;
        if (todayTimes == null) return const SizedBox();

        // 1. Core Prayers
        final List<_TimelineRowItem> listItems = [
          _TimelineRowItem(
            id: 'Fajr',
            name: 'Fajr',
            time: _formatPrayerTime('Fajr', todayTimes.fajr),
            icon: Icons.wb_twilight_outlined,
            isPrayer: true,
            isCompleted: journalProvider.isPrayerCompleted(todayStr, 'Fajr'),
            isCurrent: highlightedName == 'Fajr',
            minutesFromMidnight: _parseTimeToMinutes(_formatPrayerTime('Fajr', todayTimes.fajr)),
            habitId: '',
          ),
          _TimelineRowItem(
            id: 'Dhuhr',
            name: 'Dhuhr',
            time: _formatPrayerTime('Dhuhr', todayTimes.dhuhr),
            icon: Icons.wb_sunny_rounded,
            isPrayer: true,
            isCompleted: journalProvider.isPrayerCompleted(todayStr, 'Dhuhr'),
            isCurrent: highlightedName == 'Dhuhr',
            minutesFromMidnight: _parseTimeToMinutes(_formatPrayerTime('Dhuhr', todayTimes.dhuhr)),
            habitId: '',
          ),
          _TimelineRowItem(
            id: 'Asr',
            name: 'Asr',
            time: _formatPrayerTime('Asr', todayTimes.asr),
            icon: Icons.wb_cloudy_outlined,
            isPrayer: true,
            isCompleted: journalProvider.isPrayerCompleted(todayStr, 'Asr'),
            isCurrent: highlightedName == 'Asr',
            minutesFromMidnight: _parseTimeToMinutes(_formatPrayerTime('Asr', todayTimes.asr)),
            habitId: '',
          ),
          _TimelineRowItem(
            id: 'Maghrib',
            name: 'Maghrib',
            time: _formatPrayerTime('Maghrib', todayTimes.maghrib),
            icon: Icons.nights_stay_outlined,
            isPrayer: true,
            isCompleted: journalProvider.isPrayerCompleted(todayStr, 'Maghrib'),
            isCurrent: highlightedName == 'Maghrib',
            minutesFromMidnight: _parseTimeToMinutes(_formatPrayerTime('Maghrib', todayTimes.maghrib)),
            habitId: '',
          ),
          _TimelineRowItem(
            id: 'Isha',
            name: 'Isha',
            time: _formatPrayerTime('Isha', todayTimes.isha),
            icon: Icons.nightlight_round_outlined,
            isPrayer: true,
            isCompleted: journalProvider.isPrayerCompleted(todayStr, 'Isha'),
            isCurrent: highlightedName == 'Isha',
            minutesFromMidnight: _parseTimeToMinutes(_formatPrayerTime('Isha', todayTimes.isha)),
            habitId: '',
          ),
        ];

        // 2. Add visible habits chronologically
        for (final habit in journalProvider.habits) {
          if (habit.showOnHomeTimeline) {
            listItems.add(_TimelineRowItem(
              id: habit.id,
              name: habit.title,
              time: _format24hTo12h(habit.time),
              icon: Icons.checklist_rounded,
              isPrayer: false,
              isCompleted: journalProvider.isHabitCompleted(habit.id, todayStr),
              isCurrent: false,
              minutesFromMidnight: _parseTimeToMinutes(habit.time),
              habitId: habit.id,
            ));
          }
        }

        // 3. Sort chronologically
        listItems.sort((a, b) => a.minutesFromMidnight.compareTo(b.minutesFromMidnight));

        const double rowHeight = 100.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DAILY SCHEDULE',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.primaryAccent.withValues(alpha: 0.8),
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'Today, $formattedDate',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SnakePathPainter(
                      itemCount: listItems.length,
                      rowHeight: rowHeight,
                      baseX: 30.0,
                      amplitude: 22.0,
                      dotColor: themeProvider.primaryAccent,
                    ),
                  ),
                ),
                Column(
                  children: List.generate(listItems.length, (index) {
                    final item = listItems[index];
                    
                    const double baseX = 30.0;
                    const double amplitude = 22.0;
                    final double nodeCenterX = baseX + amplitude * math.sin(index * math.pi / 2);
                    
                    return SizedBox(
                      height: rowHeight,
                      child: Stack(
                        children: [
                          Positioned(
                            left: nodeCenterX - 14.0,
                            top: (rowHeight - 84.0) / 2 + (84.0 / 2) - 14.0,
                            child: _buildNodeIndicator(context, item.isCurrent, item.isCompleted),
                          ),
                          Positioned(
                            left: nodeCenterX + 24.0,
                            right: 0,
                            top: (rowHeight - 84.0) / 2,
                            height: 84.0,
                            child: _PrayerScheduleRow(
                              item: item,
                              isCurrent: item.isCurrent,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const _NewFooter(),
          ],
        );
      },
    );
  }

  Widget _buildNodeIndicator(BuildContext context, bool isCurrent, bool isCompleted) {
    final themeProvider = context.watch<ThemeProvider>();
    final activeColor = themeProvider.primaryAccent;

    if (isCompleted) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: activeColor,
          boxShadow: [
            BoxShadow(
              color: activeColor.withValues(alpha: 0.3),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.check_rounded,
            color: themeProvider.backgroundBottom,
            size: 14,
            weight: 900,
          ),
        ),
      );
    }

    if (isCurrent) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: activeColor.withValues(alpha: 0.15),
          border: Border.all(color: activeColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: activeColor.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activeColor,
            ),
          ),
        ),
      );
    } else {
      return Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: themeProvider.containerColor,
            border: Border.all(
              color: activeColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      );
    }
  }
}

class _PrayerScheduleRow extends StatelessWidget {
  final _TimelineRowItem item;
  final bool isCurrent;

  const _PrayerScheduleRow({
    required this.item,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PrayerProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final journalProvider = context.watch<JournalProvider>();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    final hasIqamah = item.isPrayer && item.name != 'Sunrise';
    final activeColor = themeProvider.primaryAccent;
    final glassBackground = isCurrent 
        ? themeProvider.continueReadingBg.withValues(alpha: 0.25) 
        : themeProvider.containerColor;

    return Selector<PrayerProvider, (int, String, String)>(
      selector: (_, prov) => (
        hasIqamah ? (prov.iqamahOffsets[item.name] ?? 20) : 0,
        hasIqamah ? (prov.iqamahNotificationSounds[item.name] ?? 'Default Alert') : '',
        hasIqamah ? (prov.adhanNotificationSounds[item.name] ?? 'Default Alert') : '',
      ),
      builder: (context, data, child) {
        final iqamahOffset = data.$1;
        final iqamahSound = data.$2;
        final adhanSound = data.$3;

        return Container(
          decoration: BoxDecoration(
            color: glassBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCurrent 
                  ? activeColor.withValues(alpha: 0.6) 
                  : Colors.white.withValues(alpha: 0.04),
              width: isCurrent ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Interactive Checkbox / Tick
                        GestureDetector(
                          onTap: () {
                            if (!item.isCompleted) {
                              final now = DateTime.now();
                              final currentMinutes = now.hour * 60 + now.minute;
                              if (currentMinutes < item.minutesFromMidnight) {
                                HapticFeedback.vibrate();
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.lock_clock_rounded, color: themeProvider.primaryAccent, size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            "Cannot complete ${item.name} before its scheduled time (${item.time})",
                                            style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: themeProvider.containerColor,
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: themeProvider.primaryAccent.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                            }

                            if (item.isPrayer) {
                              journalProvider.togglePrayerCompletion(todayStr, item.name);
                            } else {
                              journalProvider.toggleHabitCompletion(item.habitId, todayStr);
                            }
                            HapticFeedback.mediumImpact();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: item.isCompleted ? activeColor : Colors.transparent,
                              border: Border.all(
                                color: item.isCompleted ? activeColor : Colors.white.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            child: item.isCompleted
                                ? Icon(
                                    Icons.check_rounded,
                                    color: themeProvider.backgroundBottom,
                                    size: 14,
                                    weight: 900,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          item.icon,
                          color: isCurrent ? activeColor : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.name,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                color: Colors.white,
                                decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                decorationColor: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(height: 2),
                             Text(
                               item.time,
                               style: GoogleFonts.outfit(
                                 fontSize: 12,
                                 fontWeight: FontWeight.bold,
                                 color: isCurrent ? activeColor : const Color(0xFF94A3B8),
                               ),
                             ),
                          ],
                        ),
                      ],
                    ),
                    
                    // Right actions: Prayer notifications or Habit pill
                    if (item.isPrayer) ...[
                      Row(
                        children: [
                          if (hasIqamah) ...[
                            GestureDetector(
                              onTap: () => _showIqamahSettingsSheet(context, provider, item.name),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: activeColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: activeColor.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      iqamahSound == 'Silent'
                                          ? Icons.notifications_off_outlined
                                          : Icons.notifications_active_rounded,
                                      size: 10,
                                      color: activeColor.withValues(alpha: 0.8),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '+${iqamahOffset}m',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: activeColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
                              ),
                              child: Icon(
                                adhanSound == 'Silent'
                                    ? Icons.volume_off_outlined
                                    : (isCurrent ? Icons.volume_up_rounded : Icons.notifications_none_rounded),
                                size: 18,
                                color: adhanSound == 'Silent'
                                    ? const Color(0xFF94A3B8).withValues(alpha: 0.3)
                                    : activeColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ] else ...[
                      // Small habit indicator badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: activeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'HABIT',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: activeColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isCurrent)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        topRight: Radius.circular(18),
                      ),
                    ),
                    child: Text(
                      'NOW',
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF030D0F),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showIqamahSettingsSheet(BuildContext context, PrayerProvider provider, String prayerName) {
    int currentOffset = provider.iqamahOffsets[prayerName] ?? 20;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final adhanTime = _getAdhanTimeForPrayer(provider, prayerName);
            final calculatedIqamah = provider.getIqamahTime(prayerName, adhanTime);

            return Container(
              padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
              decoration: const BoxDecoration(
                color: Color(0xFF0C2529),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Iqamah Settings',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2DD4BF),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Set offset minutes after Adhan for $prayerName',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Real-time Preview Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Adhan Time',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatPrayerTime(prayerName, adhanTime),
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: const Color(0xFF2DD4BF).withValues(alpha: 0.4),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Iqamah Time',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: const Color(0xFF2DD4BF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatPrayerTime(prayerName, calculatedIqamah),
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2DD4BF),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Offset Minutes',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2DD4BF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$currentOffset min',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2DD4BF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: currentOffset.toDouble(),
                    min: 0,
                    max: 60,
                    divisions: 12, // multiples of 5
                    activeColor: const Color(0xFF2DD4BF),
                    inactiveColor: Colors.white.withValues(alpha: 0.05),
                    onChanged: (val) {
                      setModalState(() {
                        currentOffset = val.toInt();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [5, 10, 15, 20, 25, 30].map((preset) {
                        final isSelected = currentOffset == preset;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('$preset min'),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  currentOffset = preset;
                                });
                              }
                            },
                            selectedColor: const Color(0xFF2DD4BF),
                            backgroundColor: Colors.white.withValues(alpha: 0.03),
                            labelStyle: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? const Color(0xFF030D0F) : Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        provider.updateIqamahOffset(prayerName, currentOffset);
                        Navigator.pop(context);
                        HapticFeedback.lightImpact();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2DD4BF),
                        foregroundColor: const Color(0xFF030D0F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Save Iqamah Time',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
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

  String _getAdhanTimeForPrayer(PrayerProvider provider, String prayerName) {
    if (provider.todayPrayerTimes == null) return '00:00';
    switch (prayerName) {
      case 'Fajr':
        return provider.todayPrayerTimes!.fajr;
      case 'Dhuhr':
        return provider.todayPrayerTimes!.dhuhr;
      case 'Asr':
        return provider.todayPrayerTimes!.asr;
      case 'Maghrib':
        return provider.todayPrayerTimes!.maghrib;
      case 'Isha':
        return provider.todayPrayerTimes!.isha;
      default:
        return '00:00';
    }
  }
}

class _NewFooter extends StatelessWidget {
  const _NewFooter();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 1,
                width: 24,
                color: Colors.white.withValues(alpha: 0.05),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'NUSWALLY LILLAH',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.primaryAccent.withValues(alpha: 0.4),
                    letterSpacing: 3,
                  ),
                ),
              ),
              Container(
                height: 1,
                width: 24,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'by Nishmal Vadakara',
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.15),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerSplashOverlay extends StatelessWidget {
  final VoidCallback onDismiss;
  const _PrayerSplashOverlay({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.9),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bismillah',
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Beginning with the name of Allah',
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IslamicStarPainter extends CustomPainter {
  final Color strokeColor;
  final Color fillColor;

  _IslamicStarPainter({
    required this.strokeColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = math.min(w, h) / 2;
    final double innerR = r * 0.73;

    final Paint fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final Paint strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path path = Path();
    for (int i = 0; i < 8; i++) {
      final double angle1 = i * math.pi / 4;
      final double x1 = cx + r * math.cos(angle1);
      final double y1 = cy + r * math.sin(angle1);

      final double angle2 = angle1 + math.pi / 8;
      final double x2 = cx + innerR * math.cos(angle2);
      final double y2 = cy + innerR * math.sin(angle2);

      if (i == 0) {
        path.moveTo(x1, y1);
      } else {
        path.lineTo(x1, y1);
      }
      path.lineTo(x2, y2);
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _IslamicStarPainter oldDelegate) => false;
}

class _VerticalDottedLinePainter extends CustomPainter {
  final Color color;
  _VerticalDottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final double dashHeight = 4.0;
    final double dashGap = 4.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalDottedLinePainter oldDelegate) => false;
}

// ----------------------------------------------------
// Unified Quran Tab Body (Matching Home Styling)
// ----------------------------------------------------
class _QuranTabBody extends StatefulWidget {
  final String searchQuery;
  const _QuranTabBody({this.searchQuery = ''});

  @override
  State<_QuranTabBody> createState() => _QuranTabBodyState();
}

class _QuranTabBodyState extends State<_QuranTabBody> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      if (!mounted) return;
      context.read<QuranProvider>().fetchSurahs();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Surah> _filtered(List<Surah> surahs) {
    if (widget.searchQuery.isEmpty) return surahs;
    final q = widget.searchQuery.toLowerCase();
    return surahs.where((s) =>
      s.englishName.toLowerCase().contains(q) ||
      s.number.toString().contains(q) ||
      s.englishNameTranslation.toLowerCase().contains(q)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Column(
      children: [
        _buildTabBar(context, themeProvider),
        Expanded(
          child: Consumer<QuranProvider>(
            builder: (context, provider, child) {
              if (provider.isLoadingSurahs) {
                return Center(child: CircularProgressIndicator(color: themeProvider.primaryAccent));
              }
              if (provider.surahs.isEmpty) {
                return _buildErrorView(context, provider, themeProvider);
              }

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildSurahList(context, provider, _filtered(provider.surahs), themeProvider),
                  _buildBookmarksList(context, provider, themeProvider),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TabBar(
        controller: _tabController,
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
        labelColor: themeProvider.primaryAccent,
        unselectedLabelColor: const Color(0xFF94A3B8).withValues(alpha: 0.6),
        indicatorColor: themeProvider.primaryAccent,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'All Surahs'),
          Tab(text: 'Bookmarks'),
        ],
      ),
    );
  }

  Widget _buildSurahList(BuildContext context, QuranProvider provider, List<Surah> surahs, ThemeProvider themeProvider) {
    if (surahs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: themeProvider.primaryAccent.withValues(alpha: 0.15)),
            const SizedBox(height: 12),
            Text(
              'No results found',
              style: GoogleFonts.outfit(fontSize: 16, color: const Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 100), // padding to clear bottom bar
      itemCount: surahs.length,
      physics: const BouncingScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildSurahCard(context, surahs[index], provider, themeProvider),
    );
  }

  Widget _buildBookmarksList(BuildContext context, QuranProvider provider, ThemeProvider themeProvider) {
    final bookmarked = provider.surahs
        .where((s) => provider.isBookmarked(s.number))
        .toList();

    if (bookmarked.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border_rounded, size: 56, color: themeProvider.primaryAccent.withValues(alpha: 0.15)),
            const SizedBox(height: 12),
            Text(
              'No bookmarks yet',
              style: GoogleFonts.outfit(fontSize: 16, color: const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap ♥ on any Surah to save it',
              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8).withValues(alpha: 0.6)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 100), // padding to clear bottom bar
      itemCount: bookmarked.length,
      physics: const BouncingScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildSurahCard(context, bookmarked[index], provider, themeProvider),
    );
  }

  Widget _buildSurahCard(BuildContext context, Surah surah, QuranProvider provider, ThemeProvider themeProvider) {
    final isBookmarked = provider.isBookmarked(surah.number);
    final isLastRead = provider.lastReadSurahNumber == surah.number;

    final activeColor = themeProvider.primaryAccent;
    final normalColor = const Color(0xFF94A3B8);

    return GestureDetector(
      onTap: () {
        provider.saveLastRead(surah.number, surah.englishName, 0);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SurahDetailScreen(surah: surah)),
        );
        HapticFeedback.lightImpact();
      },
      child: Stack(
        children: [
          Positioned(
            top: 0,
            bottom: 0,
            left: 36, 
            child: CustomPaint(
              painter: _VerticalDottedLinePainter(
                color: activeColor.withValues(alpha: 0.15),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLastRead
                    ? [
                        themeProvider.continueReadingBg.withValues(alpha: 0.35),
                        themeProvider.containerColor.withValues(alpha: 0.95),
                      ]
                    : [
                        themeProvider.containerColor,
                        themeProvider.backgroundBottom.withValues(alpha: 0.95),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isLastRead
                    ? activeColor.withValues(alpha: 0.6)
                    : isBookmarked
                        ? activeColor.withValues(alpha: 0.25)
                        : activeColor.withValues(alpha: 0.05),
                width: isLastRead ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                CustomPaint(
                  size: const Size(40, 40),
                  painter: _IslamicStarPainter(
                    strokeColor: activeColor.withValues(alpha: isLastRead ? 0.8 : 0.4),
                    fillColor: activeColor.withValues(alpha: isLastRead ? 0.15 : 0.06),
                  ),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Text(
                        surah.number.toString(),
                        style: GoogleFonts.jetBrainsMono(
                          color: activeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            surah.englishName,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (isLastRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: activeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: activeColor.withValues(alpha: 0.3), width: 0.5),
                              ),
                              child: Text(
                                'LAST READ',
                                style: GoogleFonts.outfit(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  color: activeColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${surah.revelationType} • ${surah.numberOfAyahs} Verses',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: normalColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    provider.toggleBookmark(surah.number);
                    HapticFeedback.mediumImpact();
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      key: ValueKey(isBookmarked),
                      color: isBookmarked ? activeColor : normalColor.withValues(alpha: 0.2),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: activeColor.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    surah.name,
                    style: TextStyle(
                      fontFamily: 'HafsFont',
                      fontSize: 20,
                      color: activeColor,
                      shadows: [
                        Shadow(
                          color: activeColor.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, QuranProvider provider, ThemeProvider themeProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 64, color: themeProvider.primaryAccent.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'Connection Error',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: themeProvider.primaryAccent),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your internet and try again.',
            style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => provider.fetchSurahs(),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              'Retry',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.primaryAccent,
              foregroundColor: themeProvider.backgroundBottom,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// Unified Qibla Tab Body (Matching Home Styling)
// ----------------------------------------------------
class _QiblaTabBody extends StatefulWidget {
  const _QiblaTabBody();

  @override
  State<_QiblaTabBody> createState() => _QiblaTabBodyState();
}

class _QiblaTabBodyState extends State<_QiblaTabBody> with SingleTickerProviderStateMixin {
  double _heading = 45.0;
  final double _qiblaBearing = 292.0; // Perfect Qibla bearing
  
  late AnimationController _pulseController;
  bool _hasSignaledAlignment = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  double get _relativeAngle {
    return (_qiblaBearing - _heading) % 360;
  }

  bool get _isAligned {
    final diff = (_heading - _qiblaBearing).abs();
    return diff < 4.0 || diff > 356.0;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _heading = (_heading + details.delta.dx * 0.4) % 360;
      if (_isAligned) {
        if (!_hasSignaledAlignment) {
          HapticFeedback.heavyImpact();
          _hasSignaledAlignment = true;
        } else {
          HapticFeedback.selectionClick();
        }
      } else {
        _hasSignaledAlignment = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prayerProvider = Provider.of<PrayerProvider>(context);
    final locationName = prayerProvider.selectedLocation?.name ?? 'Kozhikode';
    final districtName = prayerProvider.selectedLocation?.district ?? 'Kerala';
    
    final activeColor = const Color(0xFF2DD4BF);
    final isAligned = _isAligned;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Location indicator card
            _buildLocationCard(locationName, districtName),
            const SizedBox(height: 24),
            
            // Alignment Badge
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isAligned
                  ? Container(
                      key: const ValueKey('aligned'),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: activeColor, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.gps_fixed_rounded, color: activeColor, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'PERFECTLY ALIGNED',
                            style: GoogleFonts.jetBrainsMono(
                              color: activeColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      key: const ValueKey('aligning'),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.explore_outlined, color: Colors.white.withValues(alpha: 0.4), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'ROTATE COMPASS TO ALIGN',
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            
            const SizedBox(height: 32),

            // Immersive compass rose
            GestureDetector(
              onPanUpdate: _onPanUpdate,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ambient aura
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = 1.0 + (_pulseController.value * 0.05);
                      return Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: isAligned
                                  ? activeColor.withValues(alpha: 0.12 * scale)
                                  : activeColor.withValues(alpha: 0.01),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  // Compass background ring
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0C2529).withValues(alpha: 0.8),
                      border: Border.all(
                        color: isAligned 
                            ? activeColor.withValues(alpha: 0.4) 
                            : Colors.white.withValues(alpha: 0.05),
                        width: 2,
                      ),
                    ),
                  ),

                  // The Rotating Compass Dial
                  Transform.rotate(
                    angle: -_heading * math.pi / 180,
                    child: SizedBox(
                      width: 240,
                      height: 240,
                      child: CustomPaint(
                        painter: CompassPainter(
                          qiblaAngle: _qiblaBearing,
                          accentColor: activeColor,
                        ),
                      ),
                    ),
                  ),

                  // Fixed Kaaba pointer needle (pointing up)
                  Transform.rotate(
                    angle: _relativeAngle * math.pi / 180,
                    child: SizedBox(
                      width: 240,
                      height: 240,
                      child: CustomPaint(
                        painter: NeedlePainter(accentColor: activeColor),
                      ),
                    ),
                  ),

                  // Center Kaaba silhouette indicator
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAligned ? activeColor : const Color(0xFF030D0F),
                      border: Border.all(
                        color: isAligned ? Colors.transparent : activeColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        if (isAligned)
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.4),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                      ],
                    ),
                    child: Icon(
                      Icons.mosque,
                      color: isAligned ? const Color(0xFF030D0F) : activeColor,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 36),

            // Bearing and distance metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMetricCard(
                  title: 'BEARING',
                  value: '${_heading.toInt()}° NW',
                  subValue: 'Qibla: ${_qiblaBearing.toInt()}°',
                  accentColor: activeColor,
                ),
                _buildMetricCard(
                  title: 'DISTANCE',
                  value: '3,950 km',
                  subValue: 'To Makkah',
                  accentColor: activeColor,
                ),
              ],
            ),
            
            const SizedBox(height: 24),

            // Tips card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0C2529),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: activeColor.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: activeColor.withValues(alpha: 0.6), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hold your device flat and keep away from metal objects or magnetic fields for maximum accuracy.',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF94A3B8),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 120), // Clearance for bottom navigation bar
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(String location, String district) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0C2529),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2DD4BF).withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_rounded, color: Color(0xFF2DD4BF), size: 16),
              const SizedBox(width: 8),
              Text(
                '$location, $district',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            setState(() {
              _heading = _qiblaBearing;
            });
            HapticFeedback.heavyImpact();
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0C2529),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2DD4BF).withValues(alpha: 0.1)),
            ),
            child: const Icon(
              Icons.autorenew_rounded,
              color: Color(0xFF2DD4BF),
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subValue,
    required Color accentColor,
  }) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C2529),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.3),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subValue,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: accentColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
