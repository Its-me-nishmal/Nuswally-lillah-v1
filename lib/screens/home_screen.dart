import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/prayer_provider.dart';
import '../providers/theme_provider.dart';
import 'settings_screen.dart';
import 'location_selection_screen.dart';
import 'library_tab_body.dart';
import 'media_tab_body.dart';
import 'quran_tab_body.dart';
import '../services/notification_service.dart';
import '../widgets/heartbeat_tap.dart';
import '../widgets/home/home_top_header.dart';
import '../widgets/home/next_prayer_hero_card.dart';
import '../widgets/home/quick_actions_dock.dart';
import '../widgets/home/today_prayers_timeline.dart';
import '../widgets/home/obsidian_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;
  bool _isSearchingQuran = false;
  String _quranSearchQuery = '';
  final TextEditingController _quranSearchController = TextEditingController();

  bool _isSearchingLibrary = false;
  String _librarySearchQuery = '';
  final TextEditingController _librarySearchController =
      TextEditingController();

  bool _handleHardwareKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.audioVolumeDown ||
          key == LogicalKeyboardKey.audioVolumeUp ||
          key == LogicalKeyboardKey.audioVolumeMute ||
          key == LogicalKeyboardKey.mediaStop ||
          key == LogicalKeyboardKey.mediaPause) {
        NotificationService.silenceAllAlarmsAndAzan();
      }
    }
    return false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    _quranSearchController.dispose();
    _librarySearchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
    // Schedule local daily prayer notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prayerProvider = context.read<PrayerProvider>();
      if (prayerProvider.todayPrayerTimes != null) {
        NotificationService.schedulePrayerNotifications(
          prayerTimes: [prayerProvider.todayPrayerTimes!],
        );
        NotificationService.scheduleDaily6AMUpdateCheck();
      }
    });

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

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final topInset = MediaQuery.paddingOf(context).top;
    const topHeaderHeight = 56.0;

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
          // Islamic geometric overlay - clearly visible elegant watermark
          Positioned.fill(
            child: Opacity(
              opacity: 0.035,
              child: Image.asset(
                'assets/images/islamic_bg.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Main Scrollable Content Body with Top Clearance for Fixed Bar
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                top: _currentTabIndex == 3 ? topInset : topInset + topHeaderHeight,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final fadeAnim = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOutCubic,
                  );
                  final slideAnim = Tween<Offset>(
                    begin: const Offset(0, 0.02),
                    end: Offset.zero,
                  ).animate(fadeAnim);

                  return FadeTransition(
                    opacity: fadeAnim,
                    child: SlideTransition(
                      position: slideAnim,
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentTabIndex),
                  child: _buildActiveTabBody(context),
                ),
              ),
            ),
          ),
          // Fixed Frosted Top App Bar (Pinned with Blur)
          if (_currentTabIndex != 3)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: EdgeInsets.only(top: topInset),
                    decoration: BoxDecoration(
                      color: themeProvider.backgroundTop.withValues(
                        alpha: isDark ? 0.85 : 0.90,
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: themeProvider.borderColor.withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                    ),
                    child: _buildNewAppBar(context),
                  ),
                ),
              ),
            ),
          // Full-Width Frosted Bottom Navigation Bar (Attached with SafeArea)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ObsidianBottomNav(
              currentIndex: _currentTabIndex,
              onTabSelected: (index) {
                setState(() {
                  _currentTabIndex = index;
                  _isSearchingQuran = false;
                  _quranSearchQuery = '';
                  _quranSearchController.clear();
                  _isSearchingLibrary = false;
                  _librarySearchQuery = '';
                  _librarySearchController.clear();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabBody(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 12),
              const NextPrayerHeroCard(),
              const SizedBox(height: 18),
              QuickActionsDock(
                onNavigateTab: (tabIndex) {
                  setState(() {
                    _currentTabIndex = tabIndex;
                    _isSearchingQuran = false;
                    _quranSearchQuery = '';
                    _quranSearchController.clear();
                    _isSearchingLibrary = false;
                    _librarySearchQuery = '';
                    _librarySearchController.clear();
                  });
                },
              ),
              const SizedBox(height: 24),
              const TodayPrayersTimeline(),
              SizedBox(
                height: 80 + bottomInset,
              ), // Bottom clearance for full-width attached bar
            ],
          ),
        );
      case 1:
        return QuranTabBody(searchQuery: _quranSearchQuery);
      case 2:
        return LibraryTabBody(searchQuery: _librarySearchQuery);
      case 3:
        return const MediaTabBody();
      default:
        return const SizedBox();
    }
  }

  Widget _buildNewAppBar(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    if (_currentTabIndex == 3) {
      return const SizedBox.shrink(key: ValueKey('media_app_bar_empty'));
    }

    if (_currentTabIndex == 1) {
      // Holy Quran App Bar Mode
      if (_isSearchingQuran) {
        return Container(
          key: const ValueKey('quran_search_bar'),
          height: 56.0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: themeProvider.containerColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: themeProvider.borderColor),
                  ),
                  child: TextField(
                    controller: _quranSearchController,
                    autofocus: true,
                    onChanged: (v) {
                      setState(() {
                        _quranSearchQuery = v;
                      });
                    },
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      color: themeProvider.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search surah name or number...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: themeProvider.textMuted,
                        fontSize: 12.5,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: themeProvider.primaryAccent,
                        size: 18,
                      ),
                      suffixIcon: _quranSearchQuery.isNotEmpty
                          ? HeartbeatTap(
                              onTap: () {
                                _quranSearchController.clear();
                                setState(() {
                                  _quranSearchQuery = '';
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: themeProvider.primaryAccent,
                                  size: 16,
                                ),
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              HeartbeatTap(
                onTap: () {
                  _quranSearchController.clear();
                  setState(() {
                    _isSearchingQuran = false;
                    _quranSearchQuery = '';
                  });
                },
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: themeProvider.containerColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: themeProvider.borderColor),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.primaryAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        key: const ValueKey('quran_title_bar'),
        height: 56.0,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'HOLY QURAN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: themeProvider.textPrimary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: themeProvider.primaryAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                HeartbeatTap(
                  onTap: () {
                    setState(() {
                      _isSearchingQuran = true;
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: themeProvider.surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: themeProvider.borderColor,
                        width: 1.0,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: themeProvider.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                HeartbeatTap(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  ),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: themeProvider.surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: themeProvider.borderColor,
                        width: 1.0,
                      ),
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
    }

    if (_currentTabIndex == 2) {
      // Library App Bar Mode
      if (_isSearchingLibrary) {
        return Container(
          key: const ValueKey('library_search_bar'),
          height: 56.0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: themeProvider.containerColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: themeProvider.borderColor),
                  ),
                  child: TextField(
                    controller: _librarySearchController,
                    autofocus: true,
                    onChanged: (v) {
                      setState(() {
                        _librarySearchQuery = v;
                      });
                    },
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      color: themeProvider.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search duas, adhkaar, 99 names...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: themeProvider.textMuted,
                        fontSize: 12.5,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: themeProvider.primaryAccent,
                        size: 18,
                      ),
                      suffixIcon: _librarySearchQuery.isNotEmpty
                          ? HeartbeatTap(
                              onTap: () {
                                _librarySearchController.clear();
                                setState(() {
                                  _librarySearchQuery = '';
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: themeProvider.primaryAccent,
                                  size: 16,
                                ),
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              HeartbeatTap(
                onTap: () {
                  _librarySearchController.clear();
                  setState(() {
                    _isSearchingLibrary = false;
                    _librarySearchQuery = '';
                  });
                },
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: themeProvider.containerColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: themeProvider.borderColor),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.primaryAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        key: const ValueKey('library_title_bar'),
        height: 56.0,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ISLAMIC LIBRARY',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: themeProvider.textPrimary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: themeProvider.primaryAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                HeartbeatTap(
                  onTap: () {
                    setState(() {
                      _isSearchingLibrary = true;
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: themeProvider.surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: themeProvider.borderColor,
                        width: 1.0,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: themeProvider.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                HeartbeatTap(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  ),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: themeProvider.surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: themeProvider.borderColor,
                        width: 1.0,
                      ),
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
    }

    // Default Home App Bar Mode
    return const HomeTopHeader();
  }
}
