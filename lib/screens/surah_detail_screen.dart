import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/quran_model.dart';
import '../providers/quran_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/jira_theme.dart';
import '../widgets/quran/surah_detail_top_bar.dart';
import '../widgets/quran/mushaf_continuous_view.dart';
import '../widgets/quran/ayah_study_list_view.dart';
import '../widgets/quran/floating_quran_audio_dock.dart';
import '../widgets/quran/reciter_picker_sheet.dart';

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
  bool _hasInitialScrolled = false;
  bool _isCollapsed = true;
  bool _isUserDragging = false;
  int? _lastScrolledIndex;

  ScrollController get _activeScrollController =>
      _viewMode == QuranViewMode.mushaf ? _mushafScrollController : _studyScrollController;

  // Two-Finger Pinch Zoom State (Performance Optimized)
  double _basePinchFontSize = 30.0;
  bool _isPinching = false;
  double? _pinchFeedbackFontSize;
  Timer? _pinchFeedbackTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final provider = context.read<QuranProvider>();
      provider.fetchSurahDetails(widget.surah.number, initialIndex: widget.initialAyahIndex);
      provider.saveLastRead(widget.surah.number, widget.surah.englishName, widget.initialAyahIndex);
    });
  }

  @override
  void dispose() {
    _pinchFeedbackTimer?.cancel();
    _studyScrollController.dispose();
    _mushafScrollController.dispose();
    super.dispose();
  }

  void _showReadingSettings(BuildContext context, QuranProvider provider) {
    final tp = context.read<ThemeProvider>();
    final isDark = tp.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? JiraTheme.darkSurface : JiraTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: tp.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Reading & Audio Settings',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: tp.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Reciter (Qari) Selection
                  Text(
                    'Reciter (Qari)',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: tp.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      ReciterPickerSheet.show(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? JiraTheme.darkContainer : JiraTheme.lightContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tp.borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              provider.selectedQariObj.name,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: tp.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_right_rounded, color: tp.primaryAccent),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Font Size Slider
                  Text(
                    'Arabic Font Size: ${provider.fontSize.toInt()}px',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: tp.textSecondary,
                    ),
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: JiraTheme.primaryBlue,
                      inactiveTrackColor: JiraTheme.primaryBlue.withValues(alpha: 0.15),
                      thumbColor: JiraTheme.primaryBlue,
                      overlayColor: JiraTheme.primaryBlue.withValues(alpha: 0.15),
                    ),
                    child: Slider(
                      value: provider.fontSize,
                      min: 20,
                      max: 48,
                      onChanged: (value) {
                        provider.updateFontSize(value);
                        setModalState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _scrollToAyah(int index, int total, {bool instant = false}) {
    if (_viewMode == QuranViewMode.list) {
      final key = AyahStudyListView.ayahKeys[index];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          alignment: 0.22,
          duration: instant ? Duration.zero : const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        );
        return;
      }
    }

    try {
      final controller = _activeScrollController;
      if (!controller.hasClients || controller.positions.length != 1) return;
      final maxScroll = controller.position.maxScrollExtent;
      final viewportHeight = controller.position.viewportDimension;
      final ratio = total > 1 ? index / (total - 1) : 0.0;
      final target = (maxScroll * ratio - viewportHeight * 0.22).clamp(0.0, maxScroll);

      if (instant) {
        controller.jumpTo(target);
      } else {
        controller.animateTo(
          target,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: themeProvider.backgroundBottom,
      body: Stack(
        children: [
          // Background Gradient
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

          // Main Screen Content with Pinch-to-Zoom Gesture Detection
          SafeArea(
            child: Consumer<QuranProvider>(
              builder: (context, provider, child) {
                final activeSurah = (provider.currentViewingSurahNumber != null && provider.surahs.isNotEmpty)
                    ? provider.surahs.firstWhere(
                        (s) => s.number == provider.currentViewingSurahNumber,
                        orElse: () => widget.surah,
                      )
                    : widget.surah;

                // Auto-scroll on initial load if needed
                if (!provider.isLoadingAyahs && provider.ayahs.isNotEmpty && !_hasInitialScrolled) {
                  _hasInitialScrolled = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (widget.initialAyahIndex > 0) {
                      _scrollToAyah(widget.initialAyahIndex, provider.ayahs.length);
                    }
                  });
                }

                // Auto-scroll during audio playback (when active playing or highlighted index changes)
                final activeIndex = provider.currentPlayingIndex ?? provider.highlightedAyahIndex;
                if (activeIndex != null && activeIndex != _lastScrolledIndex) {
                  _lastScrolledIndex = activeIndex;
                  if (!_isUserDragging) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToAyah(activeIndex, provider.ayahs.length);
                    });
                  }
                }

                return Stack(
                  children: [
                    // 1. Two-Finger Pinch-to-Zoom & Scrollable Reading View
                    GestureDetector(
                      onScaleStart: (ScaleStartDetails details) {
                        // Strictly activate only when two or more fingers are on screen
                        if (details.pointerCount >= 2) {
                          _basePinchFontSize = provider.fontSize;
                          _isPinching = true;
                          setState(() {
                            _pinchFeedbackFontSize = _basePinchFontSize;
                          });
                        }
                      },
                      onScaleUpdate: (ScaleUpdateDetails details) {
                        if (details.pointerCount >= 2 && _isPinching) {
                          final newSize = (_basePinchFontSize * details.scale).clamp(20.0, 48.0);
                          // Throttle layout triggers to 0.75px step for maximum frame rate
                          if ((newSize - provider.fontSize).abs() >= 0.75) {
                            provider.updateFontSize(newSize);
                            setState(() {
                              _pinchFeedbackFontSize = newSize;
                            });
                          }
                        }
                      },
                      onScaleEnd: (ScaleEndDetails details) {
                        if (_isPinching) {
                          _isPinching = false;
                          HapticFeedback.selectionClick();
                          _pinchFeedbackTimer?.cancel();
                          _pinchFeedbackTimer = Timer(const Duration(milliseconds: 900), () {
                            if (mounted) {
                              setState(() {
                                _pinchFeedbackFontSize = null;
                              });
                            }
                          });
                        }
                      },
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollStartNotification && notification.dragDetails != null) {
                            _isUserDragging = true;
                          } else if (notification is ScrollEndNotification) {
                            _isUserDragging = false;
                            // When user finishes manual scrolling, smoothly snap back to current active Ayah if one is playing!
                            final playingIdx = provider.currentPlayingIndex;
                            if (playingIdx != null && provider.playerState?.playing == true) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _scrollToAyah(playingIdx, provider.ayahs.length);
                              });
                            }
                          } else if (notification is UserScrollNotification) {
                            if (notification.direction == ScrollDirection.reverse) {
                              final c = _activeScrollController;
                              if (!_isCollapsed && c.hasClients && c.positions.length == 1 && c.offset > 40) {
                                setState(() => _isCollapsed = true);
                              }
                            }
                          }
                          return false;
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
                      ),
                    ),

                    // 2. Floating Top Header & Mode Switcher
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SurahDetailTopBar(
                        surah: activeSurah,
                        viewMode: _viewMode,
                        isCollapsed: _isCollapsed,
                        onViewModeChanged: (mode) {
                          setState(() {
                            _viewMode = mode;
                          });
                        },
                        onOpenSettings: () => _showReadingSettings(context, provider),
                      ),
                    ),

                    // 3. Floating Font Size HUD Feedback Badge (Pinch visualizer)
                    if (_pinchFeedbackFontSize != null)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: (isDark ? JiraTheme.darkSurface : JiraTheme.lightSurface).withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: JiraTheme.primaryBlue.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.format_size_rounded,
                                size: 20,
                                color: JiraTheme.primaryBlue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_pinchFeedbackFontSize!.toInt()} px',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: themeProvider.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Floating Glassmorphic Audio Recitation Dock (Collapses to mini round icon)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: FloatingQuranAudioDock(
              surah: widget.surah,
              isCollapsed: _isCollapsed,
              onExpand: () {
                setState(() => _isCollapsed = false);
              },
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
            style: GoogleFonts.outfit(
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
