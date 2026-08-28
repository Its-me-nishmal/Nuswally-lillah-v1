import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/quran_model.dart';
import '../providers/quran_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/heartbeat_tap.dart';
import '../widgets/quran/surah_detail_top_bar.dart';
import '../widgets/quran/mushaf_continuous_view.dart';
import '../widgets/quran/ayah_study_list_view.dart';
import '../theme/app_colors.dart';

enum BottomBarMode { scroll, fontSize }

class SurahDetailScreen extends StatefulWidget {
  final Surah surah;
  final int initialAyahIndex;

  const SurahDetailScreen({
    super.key,
    required this.surah,
    this.initialAyahIndex = 0,
  });

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final ScrollController _studyScrollController = ScrollController();
  final ScrollController _mushafScrollController = ScrollController();
  QuranViewMode _viewMode = QuranViewMode.mushaf;
  BottomBarMode _bottomBarMode = BottomBarMode.scroll;

  // Immersive Scroll State & Deliberate Delta Accumulator
  bool _isTopBarCollapsed = false;
  double _lastScrollOffset = 0.0;
  double _accumulatedUpwardScroll = 0.0;
  double _accumulatedDownwardScroll = 0.0;

  ScrollController get _activeScrollController =>
      _viewMode == QuranViewMode.mushaf
      ? _mushafScrollController
      : _studyScrollController;

  // Auto-scroll State
  double _autoScrollSpeed = 0.0; // 0.0 to 5.0 (0.0 is OFF)
  Timer? _autoScrollTimer;

  // Two-Finger Pinch Zoom State (Performance Optimized)
  double _basePinchFontSize = 28.0;
  bool _isPinching = false;
  double? _pinchFeedbackFontSize;
  Timer? _pinchFeedbackTimer;

  @override
  void initState() {
    super.initState();
    // Hide system status bar during Quran reading for distraction-free immersion
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _studyScrollController.addListener(_onScroll);
    _mushafScrollController.addListener(_onScroll);

    Future.microtask(() {
      if (!mounted) return;
      final provider = context.read<QuranProvider>();
      setState(() {
        _viewMode = provider.readingViewMode == 'list'
            ? QuranViewMode.list
            : QuranViewMode.mushaf;
      });
      provider.fetchSurahDetails(
        widget.surah.number,
        initialIndex: widget.initialAyahIndex,
      );
      provider.saveLastRead(
        widget.surah.number,
        widget.surah.englishName,
        widget.initialAyahIndex,
      );
    });
  }

  void _onScroll() {
    if (!_activeScrollController.hasClients) return;
    final offset = _activeScrollController.offset;
    final delta = offset - _lastScrollOffset;
    _lastScrollOffset = offset;

    // Always reveal at the top of the Surah
    if (offset < 30) {
      if (_isTopBarCollapsed) {
        setState(() => _isTopBarCollapsed = false);
      }
      _accumulatedUpwardScroll = 0;
      _accumulatedDownwardScroll = 0;
      return;
    }

    if (delta > 0) {
      // Scrolling Down
      _accumulatedDownwardScroll += delta;
      _accumulatedUpwardScroll = 0;
      if (_accumulatedDownwardScroll > 30 && !_isTopBarCollapsed) {
        setState(() => _isTopBarCollapsed = true);
      }
    } else if (delta < 0) {
      // Scrolling Up: Require intentional deliberate scroll (> 80px), ignoring micro-jitters
      _accumulatedUpwardScroll += delta.abs();
      _accumulatedDownwardScroll = 0;
      if (_accumulatedUpwardScroll > 80 && _isTopBarCollapsed) {
        setState(() => _isTopBarCollapsed = false);
      }
    }
  }

  @override
  void dispose() {
    // Restore default system UI mode on exit
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _studyScrollController.removeListener(_onScroll);
    _mushafScrollController.removeListener(_onScroll);
    _autoScrollTimer?.cancel();
    _pinchFeedbackTimer?.cancel();
    _studyScrollController.dispose();
    _mushafScrollController.dispose();
    super.dispose();
  }

  void _updateAutoScroll(double newSpeed) {
    setState(() {
      _autoScrollSpeed = newSpeed;
      if (newSpeed > 0) {
        _isTopBarCollapsed =
            true; // Auto-collapse top bar on auto-scroll start for immersion
      }
    });

    _autoScrollTimer?.cancel();
    if (_autoScrollSpeed > 0) {
      _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 20), (
        timer,
      ) {
        if (!mounted || _autoScrollSpeed <= 0) {
          timer.cancel();
          return;
        }

        final controller = _activeScrollController;
        if (controller.hasClients) {
          final max = controller.position.maxScrollExtent;
          final current = controller.position.pixels;
          if (current >= max) {
            setState(() {
              _autoScrollSpeed = 0.0;
              _isTopBarCollapsed = false;
            });
            timer.cancel();
            return;
          }
          final next = (current + (_autoScrollSpeed * 0.45)).clamp(0.0, max);
          controller.jumpTo(next);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watchTheme();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const double kTopBarHeight = 56.0;

    final Surah activeSurah = widget.surah;

    return Scaffold(
      backgroundColor: themeProvider.backgroundTop,
      body: Stack(
        children: [
          // Background Gradient & Islamic Pattern
          Positioned.fill(
            child: Container(
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
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.035,
              child: Image.asset(
                'assets/images/islamic_bg.png',
                repeat: ImageRepeat.repeat,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),

          // Main Quran Reading Content (Ayah List or Continuous Mushaf)
          Positioned.fill(
            child: Consumer<QuranProvider>(
              builder: (context, provider, child) {
                return GestureDetector(
                  onScaleStart: (details) {
                    if (details.pointerCount >= 2) {
                      _isPinching = true;
                      _basePinchFontSize = provider.fontSize;
                    }
                  },
                  onScaleUpdate: (details) {
                    if (_isPinching && details.pointerCount >= 2) {
                      final targetSize = (_basePinchFontSize * details.scale)
                          .clamp(20.0, 44.0);
                      setState(() {
                        _pinchFeedbackFontSize = targetSize;
                      });
                      _pinchFeedbackTimer?.cancel();
                      _pinchFeedbackTimer = Timer(
                        const Duration(milliseconds: 600),
                        () {
                          if (mounted) {
                            setState(() {
                              _pinchFeedbackFontSize = null;
                            });
                          }
                        },
                      );
                      provider.updateFontSize(targetSize);
                    }
                  },
                  onScaleEnd: (details) {
                    _isPinching = false;
                  },
                  child: provider.isLoadingAyahs
                      ? Center(
                          child: CircularProgressIndicator(
                            color: themeProvider.primaryAccent,
                          ),
                        )
                      : provider.ayahs.isEmpty
                      ? _buildErrorView(context, provider)
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _viewMode == QuranViewMode.mushaf
                              ? MushafContinuousView(
                                  key: ValueKey('mushaf_${activeSurah.number}'),
                                  surah: activeSurah,
                                  scrollController: _mushafScrollController,
                                )
                              : AyahStudyListView(
                                  key: ValueKey('list_${activeSurah.number}'),
                                  surah: activeSurah,
                                  scrollController: _studyScrollController,
                                ),
                        ),
                );
              },
            ),
          ),

          // Collapsible Frosted Top App Bar (Pinned 56px with Blur)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topInset + kTopBarHeight,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _isTopBarCollapsed ? 0.0 : 20,
                  sigmaY: _isTopBarCollapsed ? 0.0 : 20,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.only(top: topInset),
                  decoration: BoxDecoration(
                    color: _isTopBarCollapsed
                        ? Colors.transparent
                        : themeProvider.backgroundTop.withValues(
                            alpha: isDark ? 0.85 : 0.90,
                          ),
                    border: Border(
                      bottom: BorderSide(
                        color: themeProvider.borderColor.withValues(
                          alpha: _isTopBarCollapsed ? 0.0 : 0.35,
                        ),
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: SurahDetailTopBar(
                    surah: activeSurah,
                    viewMode: _viewMode,
                    isCollapsed: _isTopBarCollapsed,
                    onViewModeChanged: (mode) {
                      setState(() {
                        _viewMode = mode;
                      });
                      context.read<QuranProvider>().updateReadingViewMode(
                        mode == QuranViewMode.mushaf ? 'mushaf' : 'list',
                      );
                    },
                    onOpenSettings: () {},
                  ),
                ),
              ),
            ),
          ),

          // Fixed Full-Width Bottom Control Bar with Safe Area Blur
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    bottomInset > 0 ? bottomInset + 4 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? context.pageTop : Colors.white).withValues(
                      alpha: isDark ? 0.92 : 0.95,
                    ),
                    border: Border(
                      top: BorderSide(
                        color: themeProvider.borderColor.withValues(
                          alpha: 0.35,
                        ),
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: Consumer<QuranProvider>(
                    builder: (context, provider, child) {
                      final isScrollMode =
                          _bottomBarMode == BottomBarMode.scroll;
                      return Row(
                        children: [
                          // 1. Mode Switcher Capsule: [Speed / Font Size]
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? context.cardTop
                                  : context.cardBottom,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: themeProvider.borderColor.withValues(
                                  alpha: 0.5,
                                ),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Speed Icon Toggle
                                HeartbeatTap(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _bottomBarMode = BottomBarMode.scroll;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isScrollMode
                                          ? themeProvider.primaryAccent
                                                .withValues(
                                                  alpha: isDark ? 0.18 : 0.15,
                                                )
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.speed_rounded,
                                      size: 16,
                                      color: isScrollMode
                                          ? themeProvider.primaryAccent
                                          : themeProvider.textSecondary,
                                    ),
                                  ),
                                ),
                                // Font Size Icon Toggle
                                HeartbeatTap(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _bottomBarMode = BottomBarMode.fontSize;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: !isScrollMode
                                          ? themeProvider.primaryAccent
                                                .withValues(
                                                  alpha: isDark ? 0.18 : 0.15,
                                                )
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.format_size_rounded,
                                      size: 16,
                                      color: !isScrollMode
                                          ? themeProvider.primaryAccent
                                          : themeProvider.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // 2. Active Mode Label & Value
                          SizedBox(
                            width: 48,
                            child: Text(
                              isScrollMode
                                  ? (_autoScrollSpeed == 0
                                        ? 'OFF'
                                        : '${_autoScrollSpeed.toStringAsFixed(1)}x')
                                  : '${provider.fontSize.toInt()}px',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isScrollMode
                                    ? (_autoScrollSpeed > 0
                                          ? themeProvider.primaryAccent
                                          : themeProvider.textSecondary)
                                    : themeProvider.primaryAccent,
                              ),
                            ),
                          ),

                          // 3. Smooth Slider (Speed 0..5 or Font Size 20..44)
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3.5,
                                activeTrackColor: themeProvider.primaryAccent,
                                inactiveTrackColor: isDark
                                    ? context.hairline
                                    : context.cardBorder,
                                thumbColor: themeProvider.primaryAccent,
                                overlayColor: themeProvider.primaryAccent
                                    .withValues(alpha: 0.2),
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6.5,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 13.0,
                                ),
                              ),
                              child: isScrollMode
                                  ? Slider(
                                      value: _autoScrollSpeed.clamp(0.0, 5.0),
                                      min: 0.0,
                                      max: 5.0,
                                      divisions: 10,
                                      onChanged: (val) {
                                        _updateAutoScroll(val);
                                      },
                                    )
                                  : Slider(
                                      value: provider.fontSize.clamp(
                                        20.0,
                                        44.0,
                                      ),
                                      min: 20.0,
                                      max: 44.0,
                                      divisions: 12,
                                      onChanged: (val) {
                                        provider.updateFontSize(val);
                                      },
                                    ),
                            ),
                          ),

                          // 4. Quick Reset / Stop to 0 (for scroll mode)
                          if (isScrollMode && _autoScrollSpeed > 0)
                            HeartbeatTap(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _updateAutoScroll(0.0);
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 17,
                                  color: themeProvider.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Floating Font Size HUD Feedback Badge (Pinch visualizer)
          if (_pinchFeedbackFontSize != null)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: (context.cardTop).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: themeProvider.primaryAccent.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.45 : 0.1,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.format_size_rounded,
                      size: 20,
                      color: themeProvider.primaryAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_pinchFeedbackFontSize!.toInt()} px',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: themeProvider.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, QuranProvider provider) {
    final tp = context.watch<ThemeProvider>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: tp.textMuted),
          const SizedBox(height: 12),
          Text(
            'Failed to load verses',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: tp.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.fetchSurahDetails(widget.surah.number),
            style: ElevatedButton.styleFrom(
              backgroundColor: tp.primaryAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
