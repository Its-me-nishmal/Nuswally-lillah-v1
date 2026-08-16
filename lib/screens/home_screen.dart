import 'dart:async';
import 'package:flutter/material.dart';
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
import '../theme/jira_theme.dart';
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
  final TextEditingController _librarySearchController = TextEditingController();

  @override
  void dispose() {
    _quranSearchController.dispose();
    _librarySearchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

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
              opacity: 0.01,
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
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.15),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _buildNewAppBar(context),
                ),
                Expanded(
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
              ],
            ),
          ),
          // Floating Glassmorphic Bottom Navigation Bar
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
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
              const SizedBox(height: 6),
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
              const SizedBox(height: 110), // Standard bottom spacing for slim bar
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
        return Padding(
          key: const ValueKey('quran_search_bar'),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: themeProvider.containerColor,
                    borderRadius: BorderRadius.circular(8),
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
                    style: GoogleFonts.outfit(fontSize: 14, color: themeProvider.textPrimary),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search surah name or number...',
                      hintStyle: GoogleFonts.outfit(
                        color: themeProvider.textMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(Icons.search_rounded, color: themeProvider.primaryAccent, size: 18),
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
                                child: Icon(Icons.close_rounded, color: themeProvider.primaryAccent, size: 16),
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              HeartbeatTap(
                onTap: () {
                  _quranSearchController.clear();
                  setState(() {
                    _isSearchingQuran = false;
                    _quranSearchQuery = '';
                  });
                },
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: themeProvider.containerColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: themeProvider.borderColor),
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
        key: const ValueKey('quran_title_bar'),
        padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'HOLY QURAN',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: themeProvider.textPrimary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF60A5FA),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF60A5FA),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
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
                    width: 38,
                    height: 38,
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
                        size: 19,
                        color: themeProvider.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                HeartbeatTap(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  ),
                  child: Container(
                    width: 38,
                    height: 38,
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
    }

    if (_currentTabIndex == 2) {
      // Library App Bar Mode
      if (_isSearchingLibrary) {
        return Padding(
          key: const ValueKey('library_search_bar'),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: themeProvider.containerColor,
                    borderRadius: BorderRadius.circular(8),
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
                    style: GoogleFonts.outfit(fontSize: 14, color: themeProvider.textPrimary),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search duas, adhkaar, 99 names...',
                      hintStyle: GoogleFonts.outfit(
                        color: themeProvider.textMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, color: JiraTheme.secondaryGreen, size: 18),
                      suffixIcon: _librarySearchQuery.isNotEmpty
                          ? HeartbeatTap(
                              onTap: () {
                                _librarySearchController.clear();
                                setState(() {
                                  _librarySearchQuery = '';
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.close_rounded, color: JiraTheme.secondaryGreen, size: 16),
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              HeartbeatTap(
                onTap: () {
                  _librarySearchController.clear();
                  setState(() {
                    _isSearchingLibrary = false;
                    _librarySearchQuery = '';
                  });
                },
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: themeProvider.containerColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: themeProvider.borderColor),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: JiraTheme.secondaryGreen,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Padding(
        key: const ValueKey('library_title_bar'),
        padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ISLAMIC LIBRARY',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: themeProvider.textPrimary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: JiraTheme.secondaryGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: JiraTheme.secondaryGreen,
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
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
                    width: 38,
                    height: 38,
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
                        size: 19,
                        color: themeProvider.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                HeartbeatTap(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  ),
                  child: Container(
                    width: 38,
                    height: 38,
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
    }

    // Default Home App Bar Mode
    return const HomeTopHeader();
  }
}
