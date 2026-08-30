import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/prayer_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/home_design.dart';
import 'settings_screen.dart';
import 'location_selection_screen.dart';
import 'library_tab_body.dart';
import 'media_tab_body.dart';
import 'more_tab_body.dart';
import 'quran_tab_body.dart';
import '../services/notification_service.dart';
import '../widgets/heartbeat_tap.dart';
import '../widgets/home/home_top_header.dart';
import '../widgets/home/daily_ayah_card.dart';
import '../widgets/home/next_prayer_hero_card.dart';
import '../widgets/home/quick_actions_dock.dart';
import '../widgets/home/today_prayers_timeline.dart';
import '../widgets/home/obsidian_bottom_nav.dart';

/// Height of the pinned top bar, shared by every tab that shows one.
const double _kTopBarHeight = 68.0;

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

  void _selectTab(int index) {
    setState(() {
      _currentTabIndex = index;
      _resetSearchState();
    });
  }

  void _resetSearchState() {
    _isSearchingQuran = false;
    _quranSearchQuery = '';
    _quranSearchController.clear();
    _isSearchingLibrary = false;
    _librarySearchQuery = '';
    _librarySearchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final topInset = MediaQuery.paddingOf(context).top;
    final showTopBar = _currentTabIndex != 3;

    return Scaffold(
      backgroundColor: HomeDesign.pageBottom(isDark),
      extendBody: true,
      body: Stack(
        children: [
          // Deep emerald-black canvas.
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  HomeDesign.pageTop(isDark),
                  HomeDesign.pageBottom(isDark),
                ],
              ),
            ),
          ),
          // Islamic geometric watermark. `Image.asset`'s own opacity avoids
          // the saveLayer an Opacity widget would force every frame.
          Positioned.fill(
            child: Image.asset(
              'assets/images/islamic_bg.webp',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.035),
            ),
          ),
          // Scrollable body, cleared past the pinned top bar.
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                top: showTopBar ? topInset + _kTopBarHeight : topInset,
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
                    child: SlideTransition(position: slideAnim, child: child),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentTabIndex),
                  child: _buildActiveTabBody(context),
                ),
              ),
            ),
          ),
          // Pinned frosted top bar.
          if (showTopBar)
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
                      color: HomeDesign.pageTop(
                        isDark,
                      ).withValues(alpha: isDark ? 0.88 : 0.92),
                      border: Border(
                        bottom: BorderSide(
                          color: HomeDesign.goldLine(isDark),
                          width: 0.8,
                        ),
                      ),
                    ),
                    child: _buildTopBar(context),
                  ),
                ),
              ),
            ),
          // Full-width bottom navigation, attached to the bottom edge.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ObsidianBottomNav(
              currentIndex: _currentTabIndex,
              onTabSelected: _selectTab,
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
            await context.read<PrayerProvider>().refreshPrayerTimes();
          },
          color: themeProvider.primaryAccent,
          backgroundColor: themeProvider.surfaceColor,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 10),
              const NextPrayerHeroCard(),
              const SizedBox(height: 12),
              QuickActionsDock(onNavigateTab: _selectTab),
              const SizedBox(height: 14),
              const TodayPrayersTimeline(),
              const SizedBox(height: 14),
              const DailyAyahCard(),
              // Clearance for the attached bottom bar.
              SizedBox(height: 92 + bottomInset),
            ],
          ),
        );
      case 1:
        return QuranTabBody(searchQuery: _quranSearchQuery);
      case 2:
        return LibraryTabBody(searchQuery: _librarySearchQuery);
      case 3:
        return const MediaTabBody();
      case 4:
        return const MoreTabBody();
      default:
        return const SizedBox();
    }
  }

  Widget _buildTopBar(BuildContext context) {
    switch (_currentTabIndex) {
      case 1:
        return _buildTabBar(
          context,
          keyPrefix: 'quran',
          title: 'HOLY QURAN',
          hint: 'Search surah name or number...',
          controller: _quranSearchController,
          isSearching: _isSearchingQuran,
          query: _quranSearchQuery,
          onStartSearch: () => setState(() => _isSearchingQuran = true),
          onQueryChanged: (v) => setState(() => _quranSearchQuery = v),
          onClearQuery: () {
            _quranSearchController.clear();
            setState(() => _quranSearchQuery = '');
          },
          onCancelSearch: () {
            _quranSearchController.clear();
            setState(() {
              _isSearchingQuran = false;
              _quranSearchQuery = '';
            });
          },
        );
      case 2:
        return _buildTabBar(
          context,
          keyPrefix: 'library',
          title: 'ISLAMIC LIBRARY',
          hint: 'Search duas, adhkaar, 99 names...',
          controller: _librarySearchController,
          isSearching: _isSearchingLibrary,
          query: _librarySearchQuery,
          onStartSearch: () => setState(() => _isSearchingLibrary = true),
          onQueryChanged: (v) => setState(() => _librarySearchQuery = v),
          onClearQuery: () {
            _librarySearchController.clear();
            setState(() => _librarySearchQuery = '');
          },
          onCancelSearch: () {
            _librarySearchController.clear();
            setState(() {
              _isSearchingLibrary = false;
              _librarySearchQuery = '';
            });
          },
        );
      case 3:
        return const SizedBox.shrink(key: ValueKey('media_app_bar_empty'));
      case 4:
        return _buildTabBar(context, keyPrefix: 'more', title: 'MORE');
      default:
        return const HomeTopHeader();
    }
  }

  /// One implementation for the Quran, Library and More bars. Omit the search
  /// callbacks and the bar renders title-only.
  Widget _buildTabBar(
    BuildContext context, {
    required String keyPrefix,
    required String title,
    String hint = '',
    TextEditingController? controller,
    bool isSearching = false,
    String query = '',
    VoidCallback? onStartSearch,
    ValueChanged<String>? onQueryChanged,
    VoidCallback? onClearQuery,
    VoidCallback? onCancelSearch,
  }) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    if (isSearching && controller != null) {
      return Container(
        key: ValueKey('${keyPrefix}_search_bar'),
        height: _kTopBarHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: HomeDesign.cardTop(isDark),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HomeDesign.goldLine(isDark)),
                ),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  onChanged: onQueryChanged ?? (_) {},
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    color: themeProvider.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: hint,
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: themeProvider.textSecondary,
                      fontSize: 12.5,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: HomeDesign.gold,
                      size: 18,
                    ),
                    suffixIcon: query.isNotEmpty
                        ? HeartbeatTap(
                            onTap: onClearQuery ?? () {},
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.close_rounded,
                                color: themeProvider.textSecondary,
                                size: 16,
                              ),
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            HeartbeatTap(
              onTap: onCancelSearch ?? () {},
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: HomeDesign.cardTop(isDark),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HomeDesign.goldLine(isDark)),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: HomeDesign.goldText(isDark),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      key: ValueKey('${keyPrefix}_title_bar'),
      height: _kTopBarHeight,
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
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: themeProvider.textPrimary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 7),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: HomeDesign.gold,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (onStartSearch != null) ...[
                _TopBarIconButton(
                  icon: Icons.search_rounded,
                  onTap: onStartSearch,
                ),
                const SizedBox(width: 8),
              ],
              _TopBarIconButton(
                icon: Icons.tune_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopBarIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return HeartbeatTap(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: HomeDesign.iconButtonFill(isDark),
          shape: BoxShape.circle,
          border: Border.all(color: HomeDesign.goldLine(isDark), width: 1.0),
        ),
        child: Center(
          child: Icon(icon, size: 19, color: themeProvider.textPrimary),
        ),
      ),
    );
  }
}
