import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/moulid_document.dart';
import '../providers/theme_provider.dart';
import '../services/json_asset_loader.dart';
import '../theme/app_colors.dart';
import '../theme/home_design.dart';
import '../widgets/heartbeat_tap.dart';

enum MoulidBottomBarMode { scroll, fontSize }

/// World-class Continuous Moulid & Awraad Recitation Reader
/// Faithfully designed to match the Holy Quran Continuous Mushaf experience:
/// - Emerald & Gold design system tokens & canvas
/// - Collapsible frosted top bar with live progress indicator
/// - 2-finger pinch-to-zoom dynamic font scaling
/// - Full-width bottom dock with Speed (0..5x) and Font Size slider controls
/// - Seamless full-width continuous reading flow with inline page separators
/// - Alternating subtle emerald/gold tints on poetic couplets
class MoulidReaderScreen extends StatefulWidget {
  final String assetPath;

  const MoulidReaderScreen({
    super.key,
    this.assetPath = 'assets/data/manqoos_moulid.json.gz',
  });

  @override
  State<MoulidReaderScreen> createState() => _MoulidReaderScreenState();
}

class _MoulidReaderScreenState extends State<MoulidReaderScreen> {
  static const double kTopBarHeight = 56.0;

  MoulidDocument? _document;
  bool _isLoading = true;
  double _fontSize = 28.0;
  String _fontFamily = 'HafsFont';
  bool _showSectionTitles = false;
  String _poetryLayout = 'auto'; // 'auto', 'dual', 'stacked'

  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _sectionKeys = {};

  MoulidBottomBarMode _bottomBarMode = MoulidBottomBarMode.scroll;

  // Auto-scroll state (0.0 to 5.0 speed)
  double _autoScrollSpeed = 0.0;
  Timer? _autoScrollTimer;

  // Progress tracking via ValueNotifier (zero-jank, isolated rebuild)
  final ValueNotifier<double> _readingProgress = ValueNotifier<double>(0.0);

  // Immersive collapsible top bar state
  bool _isTopBarCollapsed = false;
  double _lastScrollOffset = 0.0;
  double _accumulatedUpwardScroll = 0.0;
  double _accumulatedDownwardScroll = 0.0;

  // Two-Finger Pinch Zoom State
  double _basePinchFontSize = 28.0;
  bool _isPinching = false;
  double? _pinchFeedbackFontSize;
  Timer? _pinchFeedbackTimer;

  // Salawat counter for Qiyam
  int _salawatCount = 0;

  @override
  void initState() {
    super.initState();
    // Allow rotation (Portrait & Landscape) during active reading
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Enable immersive distraction-free reading
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _loadPreferences();
    _loadDocument();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Restore default orientation lock when exiting reader
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _autoScrollTimer?.cancel();
    _pinchFeedbackTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _readingProgress.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final delta = offset - _lastScrollOffset;
    _lastScrollOffset = offset;

    // Update progress
    if (maxScroll > 0) {
      _readingProgress.value = (offset / maxScroll).clamp(0.0, 1.0);
    }

    // Auto-scroll does not trigger top bar hiding to avoid distractions
    if (_autoScrollSpeed > 0) return;

    // Always reveal at the top of the Moulid
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
      // Scrolling Up: Intentional scroll (> 80px)
      _accumulatedUpwardScroll += delta.abs();
      _accumulatedDownwardScroll = 0;
      if (_accumulatedUpwardScroll > 80 && _isTopBarCollapsed) {
        setState(() => _isTopBarCollapsed = false);
      }
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _fontSize = prefs.getDouble('moulid_font_size') ?? 28.0;
      _fontFamily = prefs.getString('moulid_font_family') ?? 'HafsFont';
      _showSectionTitles = prefs.getBool('moulid_show_titles') ?? false;
      _poetryLayout = prefs.getString('moulid_poetry_layout') ?? 'auto';
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('moulid_font_size', _fontSize);
    await prefs.setString('moulid_font_family', _fontFamily);
    await prefs.setBool('moulid_show_titles', _showSectionTitles);
    await prefs.setString('moulid_poetry_layout', _poetryLayout);
  }

  /// Responsive logic determining if dual-column side-by-side or stacked layout is active
  bool _isDualColumnActive(double screenWidth, Orientation orientation) {
    if (_poetryLayout == 'dual') return true;
    if (_poetryLayout == 'stacked') return false;
    // 'auto' mode:
    // Wide screens / Landscape always have enough room for 2 columns:
    if (orientation == Orientation.landscape || screenWidth > 540) {
      return true;
    }
    // In portrait, if font size is standard (<= 24.5px), dual-column book view fits cleanly.
    // If the user increases font size (> 24.5px), seamlessly adapt to stacked full-width view!
    return _fontSize <= 24.5;
  }

  Future<void> _loadDocument() async {
    try {
      final decoded = await JsonAssetLoader.loadJsonObject(widget.assetPath);
      final doc = MoulidDocument.fromJson(decoded);

      for (final s in doc.sections) {
        _sectionKeys[s.id] = GlobalKey();
      }

      if (mounted) {
        setState(() {
          _document = doc;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToSection(int id) {
    final key = _sectionKeys[id];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _updateAutoScroll(double speed) {
    _autoScrollSpeed = speed;
    _autoScrollTimer?.cancel();
    if (speed > 0) {
      // Auto-scroll loop: smooth 30ms timer
      _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
        if (!_scrollController.hasClients) return;
        final max = _scrollController.position.maxScrollExtent;
        final current = _scrollController.position.pixels;
        if (current >= max) {
          _updateAutoScroll(0.0);
          return;
        }
        _scrollController.jumpTo(current + (speed * 0.8));
      });
    }
    setState(() {});
  }

  TextStyle _arabicStyle({
    required double size,
    FontWeight weight = FontWeight.normal,
    Color? color,
    double height = 2.2,
  }) {
    switch (_fontFamily) {
      case 'Amiri':
        return GoogleFonts.amiri(
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
        );
      case 'Scheherazade':
        return GoogleFonts.scheherazadeNew(
          fontSize: size + 2,
          fontWeight: weight,
          color: color,
          height: height,
        );
      case 'AdobeArabic':
        return TextStyle(
          fontFamily: 'AdobeArabic',
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
        );
      case 'HafsFont':
      default:
        return TextStyle(
          fontFamily: 'HafsFont',
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
        );
    }
  }

  // ─── Settings Bottom Sheet ───────────────────────────────────────

  void _showSettings(ThemeProvider tp, bool isMl) {
    HapticFeedback.selectionClick();
    final isDark = tp.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              decoration: BoxDecoration(
                color: isDark ? context.cardTop : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: context.cardBorder, width: 0.8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.textMuted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isMl ? 'വായനാ ക്രമീകരണങ്ങൾ' : 'Reader Settings',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                      HeartbeatTap(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark ? context.cardBottom : HomeDesign.inset(isDark),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.cardBorder, width: 0.8),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: context.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Font Size
                  Row(
                    children: [
                      Icon(Icons.format_size_rounded, size: 16, color: context.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        isMl ? 'അറബിക് വലിപ്പം' : 'Arabic Font Size',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: context.accentSoft,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.accentLine, width: 0.8),
                        ),
                        child: Text(
                          '${_fontSize.round()} px',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: context.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('A', style: GoogleFonts.inter(fontSize: 12, color: context.textMuted)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3.5,
                            activeTrackColor: context.accent,
                            inactiveTrackColor: context.hairline,
                            thumbColor: context.accent,
                            overlayColor: context.accent.withValues(alpha: 0.2),
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                          ),
                          child: Slider(
                            value: _fontSize,
                            min: 20.0,
                            max: 44.0,
                            divisions: 12,
                            onChanged: (val) {
                              setState(() => _fontSize = val);
                              setSheet(() {});
                              _savePreferences();
                            },
                          ),
                        ),
                      ),
                      Text(
                        'A',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Font Family
                  Row(
                    children: [
                      Icon(Icons.font_download_outlined, size: 16, color: context.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        isMl ? 'അറബിക് ഫോണ്ട്' : 'Arabic Font Typography',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _fontChip('HafsFont', 'Hafs (Quran)', tp, setSheet),
                      const SizedBox(width: 8),
                      _fontChip('AdobeArabic', 'Adobe', tp, setSheet),
                      const SizedBox(width: 8),
                      _fontChip('Amiri', 'Amiri', tp, setSheet),
                      const SizedBox(width: 8),
                      _fontChip('Scheherazade', 'Schehr.', tp, setSheet),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ── Poetry Layout Mode (Dual Column vs Large Text)
                  Row(
                    children: [
                      Icon(Icons.view_column_rounded, size: 16, color: context.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        isMl ? 'ബൈത്ത് ശൈലി' : 'Poetry Layout Style',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _layoutChip('auto', isMl ? 'ഓട്ടോ' : 'Auto', Icons.auto_awesome_rounded, tp, setSheet),
                      const SizedBox(width: 8),
                      _layoutChip('dual', isMl ? 'കിതാബ് (2 നിര)' : 'Book (2 Col)', Icons.view_column_rounded, tp, setSheet),
                      const SizedBox(width: 8),
                      _layoutChip('stacked', isMl ? 'വലിയ അക്ഷരം' : 'Large Text', Icons.view_agenda_rounded, tp, setSheet),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ── Show Section Titles Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? context.cardBottom : HomeDesign.inset(isDark),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.cardBorder, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.title_rounded, size: 16, color: context.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isMl ? 'ഫസൽ / ബൈത്ത് ശീർഷകങ്ങൾ' : 'Show Section Titles',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: _showSectionTitles,
                          activeTrackColor: context.accent,
                          onChanged: (val) {
                            setState(() => _showSectionTitles = val);
                            setSheet(() {});
                            _savePreferences();
                          },
                        ),
                      ],
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

  Widget _layoutChip(String key, String label, IconData icon, ThemeProvider tp, StateSetter setSheet) {
    final selected = _poetryLayout == key;
    final isDark = tp.isDarkMode;

    return Expanded(
      child: HeartbeatTap(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _poetryLayout = key);
          setSheet(() {});
          _savePreferences();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? context.accent : (isDark ? context.cardBottom : HomeDesign.inset(isDark)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? context.accent : context.cardBorder,
              width: selected ? 1.5 : 0.8,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.white : context.textSecondary,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : context.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fontChip(String key, String label, ThemeProvider tp, StateSetter setSheet) {
    final selected = _fontFamily == key;
    final isDark = tp.isDarkMode;

    return Expanded(
      child: HeartbeatTap(
        onTap: () {
          setState(() => _fontFamily = key);
          setSheet(() {});
          _savePreferences();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? context.accent : (isDark ? context.cardBottom : HomeDesign.inset(isDark)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? context.accent : context.cardBorder,
              width: selected ? 1.5 : 0.8,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : context.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Table of Contents ───────────────────────────────────────────

  void _showTableOfContents(ThemeProvider tp, bool isMl) {
    HapticFeedback.selectionClick();
    if (_document == null) return;
    final isDark = tp.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: isDark ? context.cardTop : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: context.cardBorder, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.textMuted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isMl ? 'ഉള്ളടക്കം' : 'Contents',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                  Text(
                    '${_document!.sections.length} ${isMl ? "ഭാഗങ്ങൾ" : "sections"}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: context.hairline),
              const SizedBox(height: 4),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _document!.sections.length,
                  separatorBuilder: (_, __) => Container(
                    height: 1,
                    color: context.hairline.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, idx) {
                    final section = _document!.sections[idx];
                    final isPoetry = section.type == MoulidSectionType.baith ||
                        section.type == MoulidSectionType.qiyam;

                    return HeartbeatTap(
                      onTap: () {
                        Navigator.pop(context);
                        _scrollToSection(section.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: context.accentSoft,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: context.accentLine, width: 0.8),
                              ),
                              child: Center(
                                child: Icon(
                                  isPoetry
                                      ? Icons.lyrics_outlined
                                      : section.type == MoulidSectionType.dua
                                          ? Icons.auto_awesome
                                          : Icons.menu_book_rounded,
                                  size: 15,
                                  color: context.accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isMl ? section.titleMalayalam : section.title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: context.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    section.titleArabic,
                                    style: TextStyle(
                                      fontFamily: 'AdobeArabic',
                                      fontSize: 13,
                                      color: context.textSecondary,
                                      height: 1.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textDirection: TextDirection.rtl,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: context.textMuted,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Main Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    context.watchTheme();
    final tp = context.watch<ThemeProvider>();
    final isMl = tp.isMalayalam;
    final isDark = tp.isDarkMode;

    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Canvas Background with subtle Emerald/Teal gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [context.pageTop, context.pageBottom],
                ),
              ),
            ),
          ),

          // 2. Faint Islamic geometric pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.035,
              child: Image.asset(
                'assets/images/islamic_bg.webp',
                repeat: ImageRepeat.repeat,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),

          // 3. Main Continuous Moulid Stream with Two-Finger Pinch-to-Zoom
          Positioned.fill(
            child: GestureDetector(
              onScaleStart: (details) {
                if (details.pointerCount >= 2) {
                  _isPinching = true;
                  _basePinchFontSize = _fontSize;
                }
              },
              onScaleUpdate: (details) {
                if (_isPinching && details.pointerCount >= 2) {
                  final targetSize = (_basePinchFontSize * details.scale).clamp(20.0, 44.0);
                  setState(() {
                    _pinchFeedbackFontSize = targetSize;
                    _fontSize = targetSize;
                  });
                  _pinchFeedbackTimer?.cancel();
                  _pinchFeedbackTimer = Timer(const Duration(milliseconds: 600), () {
                    if (mounted) {
                      setState(() => _pinchFeedbackFontSize = null);
                      _savePreferences();
                    }
                  });
                }
              },
              onScaleEnd: (_) => _isPinching = false,
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: context.accent))
                  : _document == null
                      ? Center(
                          child: Text(
                            isMl ? 'ഡോക്യുമെന്റ് ലോഡ് ചെയ്യാൻ കഴിഞ്ഞില്ല' : 'Could not load document',
                            style: GoogleFonts.inter(color: context.textMuted),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            0,
                            topInset + kTopBarHeight + 12,
                            0,
                            bottomInset + 86,
                          ),
                          itemCount: _document!.sections.length + 1,
                          itemBuilder: (context, index) {
                            // ─ Index 0: Hero Centerpiece Card
                            if (index == 0) {
                              return _buildHeroHeader(tp, isDark, isMl);
                            }

                            // ─ Section items
                            final section = _document!.sections[index - 1];
                            return _buildSectionItem(section, tp, isDark, isMl);
                          },
                        ),
            ),
          ),

          // 4. Live Pinch Zoom Feedback Indicator
          if (_pinchFeedbackFontSize != null)
            Positioned(
              top: topInset + kTopBarHeight + 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: (isDark ? context.cardTop : Colors.white).withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.cardBorderStrong),
                    boxShadow: [
                      BoxShadow(
                        color: context.cardShadow,
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    '${_pinchFeedbackFontSize!.round()} px',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: context.accent,
                    ),
                  ),
                ),
              ),
            ),

          // 5. Collapsible Frosted Top App Bar (Pinned with BackdropFilter Blur)
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
                        : (isDark ? context.cardTop : Colors.white).withValues(
                            alpha: isDark ? 0.88 : 0.92,
                          ),
                    border: Border(
                      bottom: BorderSide(
                        color: context.cardBorder.withValues(
                          alpha: _isTopBarCollapsed ? 0.0 : 0.6,
                        ),
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Back Button
                              HeartbeatTap(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  Navigator.of(context).pop();
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: (isDark ? context.cardBottom : HomeDesign.inset(isDark))
                                        .withValues(alpha: 0.90),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: context.cardBorder,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: 15,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                ),
                              ),

                              // Center Title & Author
                              Expanded(
                                child: AnimatedSlide(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeInOutCubic,
                                  offset: _isTopBarCollapsed ? const Offset(0, -0.3) : Offset.zero,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    opacity: _isTopBarCollapsed ? 0.0 : 1.0,
                                    child: IgnorePointer(
                                      ignoring: _isTopBarCollapsed,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                isMl
                                                    ? (_document?.titleMalayalam ?? 'മൗലിദ് / റാത്തീബ്')
                                                    : (_document?.title ?? 'LITANY').toUpperCase(),
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: context.textPrimary,
                                                  letterSpacing: 0.4,
                                                ),
                                              ),
                                              if (_document?.titleArabic != null && _document!.titleArabic.isNotEmpty) ...[
                                                const SizedBox(width: 6),
                                                Text(
                                                  '• ${_document!.titleArabic}',
                                                  style: TextStyle(
                                                    fontFamily: 'HafsFont',
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: HomeDesign.goldText(isDark),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            isMl
                                                ? (_document?.author ?? '')
                                                : (_document?.authorEn.isNotEmpty == true ? _document!.authorEn : (_document?.author ?? '')),
                                            style: GoogleFonts.inter(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w500,
                                              color: context.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Screen Rotation, Table of Contents & Settings Icons
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Manual 1-Tap Rotation Button (Switches Portrait <-> Landscape instantly)
                                  HeartbeatTap(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
                                      if (isLandscape) {
                                        SystemChrome.setPreferredOrientations([
                                          DeviceOrientation.portraitUp,
                                          DeviceOrientation.portraitDown,
                                        ]);
                                      } else {
                                        SystemChrome.setPreferredOrientations([
                                          DeviceOrientation.landscapeLeft,
                                          DeviceOrientation.landscapeRight,
                                        ]);
                                      }
                                      // Release lock after 1.5s so device accelerometer works freely
                                      Future.delayed(const Duration(milliseconds: 1500), () {
                                        if (mounted) {
                                          SystemChrome.setPreferredOrientations([
                                            DeviceOrientation.portraitUp,
                                            DeviceOrientation.portraitDown,
                                            DeviceOrientation.landscapeLeft,
                                            DeviceOrientation.landscapeRight,
                                          ]);
                                        }
                                      });
                                    },
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: (isDark ? context.cardBottom : HomeDesign.inset(isDark))
                                            .withValues(alpha: 0.90),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: context.cardBorder,
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.screen_rotation_rounded,
                                          size: 15,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  HeartbeatTap(
                                    onTap: () => _showTableOfContents(tp, isMl),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isDark ? context.cardBottom : HomeDesign.inset(isDark),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: context.cardBorder,
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.format_list_bulleted_rounded,
                                          size: 16,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  HeartbeatTap(
                                    onTap: () => _showSettings(tp, isMl),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isDark ? context.cardBottom : HomeDesign.inset(isDark),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: context.cardBorder,
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.tune_rounded,
                                          size: 16,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 6. Fixed Full-Width Frosted Bottom Control Bar (Speed & Font Size Slider + Progress on Top)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: (isDark ? context.cardTop : Colors.white).withValues(
                      alpha: isDark ? 0.92 : 0.95,
                    ),
                    border: Border(
                      top: BorderSide(
                        color: context.cardBorder.withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Reading Completion Progress Bar running across the top edge of bottom panel
                      ValueListenableBuilder<double>(
                        valueListenable: _readingProgress,
                        builder: (context, progress, _) {
                          return SizedBox(
                            height: 2.5,
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: context.hairline.withValues(alpha: 0.35),
                              valueColor: AlwaysStoppedAnimation<Color>(context.accent),
                            ),
                          );
                        },
                      ),

                      // Control Row
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          bottomInset > 0 ? bottomInset + 4 : 12,
                        ),
                        child: Row(
                          children: [
                            // Mode Switcher Capsule: [Speed / Font Size]
                            Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                color: isDark ? context.cardBottom : HomeDesign.inset(isDark),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: context.cardBorder, width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Speed Toggle
                                  HeartbeatTap(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _bottomBarMode = MoulidBottomBarMode.scroll);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: _bottomBarMode == MoulidBottomBarMode.scroll
                                            ? context.accentSoft
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.speed_rounded,
                                        size: 16,
                                        color: _bottomBarMode == MoulidBottomBarMode.scroll
                                            ? context.accent
                                            : context.textSecondary,
                                      ),
                                    ),
                                  ),
                                  // Font Size Toggle
                                  HeartbeatTap(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _bottomBarMode = MoulidBottomBarMode.fontSize);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: _bottomBarMode == MoulidBottomBarMode.fontSize
                                            ? context.accentSoft
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.format_size_rounded,
                                        size: 16,
                                        color: _bottomBarMode == MoulidBottomBarMode.fontSize
                                            ? context.accent
                                            : context.textSecondary,
                                      ),
                                    ),
                                  ),
                                  // Quick Poetry Layout Toggle [Auto ⚡ / Dual ☷ / Large ☰]
                                  HeartbeatTap(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        if (_poetryLayout == 'auto') {
                                          _poetryLayout = 'dual';
                                        } else if (_poetryLayout == 'dual') {
                                          _poetryLayout = 'stacked';
                                        } else {
                                          _poetryLayout = 'auto';
                                        }
                                      });
                                      _savePreferences();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: _poetryLayout != 'auto'
                                            ? context.accentSoft
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _poetryLayout == 'dual'
                                            ? Icons.view_column_rounded
                                            : _poetryLayout == 'stacked'
                                                ? Icons.view_agenda_rounded
                                                : Icons.auto_awesome_rounded,
                                        size: 16,
                                        color: _poetryLayout != 'auto'
                                            ? context.accent
                                            : context.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Mode Label & Value
                            SizedBox(
                              width: 48,
                              child: Text(
                                _bottomBarMode == MoulidBottomBarMode.scroll
                                    ? (_autoScrollSpeed == 0.0 ? 'OFF' : '${_autoScrollSpeed.toStringAsFixed(1)}x')
                                    : '${_fontSize.toInt()}px',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: _bottomBarMode == MoulidBottomBarMode.scroll
                                      ? (_autoScrollSpeed > 0 ? context.accent : context.textSecondary)
                                      : context.accent,
                                ),
                              ),
                            ),

                            // Smooth Slider (Speed 0..5 or Font Size 20..44)
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3.5,
                                  activeTrackColor: context.accent,
                                  inactiveTrackColor: context.hairline,
                                  thumbColor: context.accent,
                                  overlayColor: context.accent.withValues(alpha: 0.2),
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 13.0),
                                ),
                                child: _bottomBarMode == MoulidBottomBarMode.scroll
                                    ? Slider(
                                        value: _autoScrollSpeed.clamp(0.0, 5.0),
                                        min: 0.0,
                                        max: 5.0,
                                        divisions: 10,
                                        onChanged: (val) => _updateAutoScroll(val),
                                      )
                                    : Slider(
                                        value: _fontSize.clamp(20.0, 44.0),
                                        min: 20.0,
                                        max: 44.0,
                                        divisions: 12,
                                        onChanged: (val) {
                                          setState(() => _fontSize = val);
                                          _savePreferences();
                                        },
                                      ),
                              ),
                            ),

                            // Wide Tactile Stop Button (Much wider touch area during auto-scroll)
                            if (_bottomBarMode == MoulidBottomBarMode.scroll && _autoScrollSpeed > 0)
                              HeartbeatTap(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  _updateAutoScroll(0.0);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: context.danger.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: context.danger.withValues(alpha: 0.45),
                                      width: 0.9,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.stop_circle_rounded,
                                        size: 16,
                                        color: context.danger,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'STOP',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: context.danger,
                                          letterSpacing: 0.5,
                                        ),
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hero Header Card ────────────────────────────────────────────

  Widget _buildHeroHeader(ThemeProvider tp, bool isDark, bool isMl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, top: 4, left: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: isDark ? context.cardTop : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: context.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Metadata chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pillBadge((_document?.title.split(' ').first ?? 'LITANY').toUpperCase(), tp, isPrimary: true),
              const SizedBox(width: 8),
              _pillBadge('${_document?.sections.map((s) => s.page).whereType<int>().toSet().length ?? 1} PAGES', tp),
              const SizedBox(width: 8),
              _pillBadge('${_document!.sections.length} SECTIONS', tp),
            ],
          ),
          const SizedBox(height: 20),

          // Title Calligraphy
          Text(
            _document!.titleArabic,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'HafsFont',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: HomeDesign.goldText(isDark),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),

          // Centerpiece Bismillah
          Text(
            'بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيمِ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'HafsFont',
              fontSize: 23,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFE2E8F0) : context.accent,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'In the Name of Allah, the Most Gracious, the Most Merciful',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: context.textSecondary.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillBadge(String text, ThemeProvider tp, {bool isPrimary = false}) {
    final isDark = tp.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: isPrimary ? context.accentSoft : (isDark ? context.cardBottom : HomeDesign.inset(isDark)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPrimary ? context.accentLine : context.cardBorder,
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: isPrimary ? context.accent : context.textSecondary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  // ─── Section Item Builder ────────────────────────────────────────

  Widget _buildSectionItem(MoulidSection section, ThemeProvider tp, bool isDark, bool isMl) {
    final isQiyam = section.type == MoulidSectionType.qiyam;
    final isDua = section.type == MoulidSectionType.dua;

    Color accent;
    if (isQiyam) {
      accent = HomeDesign.gold;
    } else if (isDua) {
      accent = context.success;
    } else {
      accent = context.accent;
    }

    return Column(
      key: _sectionKeys[section.id],
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Section Separator (Matching Quran MushafContinuousView page divider)
        _buildSectionSeparator(section, tp, isDark, accent, isMl),

        // ── Refrain (for Baith / Qiyam) — Two Distinct Lines (Never Broken Continuously)
        if (section.refrain != null) ...[
          Builder(
            builder: (context) {
              final raw = section.refrain!;
              final parts = raw.contains('۝')
                  ? raw.split('۝').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
                  : raw.contains('\n')
                      ? raw.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
                      : [raw];

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: accent.withValues(alpha: isDark ? 0.08 : 0.05),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int pIdx = 0; pIdx < parts.length; pIdx++) ...[
                      if (pIdx > 0) const SizedBox(height: 5),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: _buildRichArabicText(
                          text: parts[pIdx],
                          fontSize: _fontSize + 1,
                          weight: FontWeight.w700,
                          accentColor: accent,
                          textAlign: TextAlign.center,
                          context: context,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          Container(height: 1, color: context.hairline),
        ],

        // ── Couplets (Poetry) — Responsive Dual-Column or Staggered Stacked
        if (section.couplets.isNotEmpty) ...[
          Builder(
            builder: (context) {
              final size = MediaQuery.of(context).size;
              final orientation = MediaQuery.of(context).orientation;
              final isDual = _isDualColumnActive(size.width, orientation);

              return Column(
                children: List.generate(section.couplets.length, (i) {
                  final couplet = section.couplets[i];
                  final isOdd = i.isOdd;

                  final oddBg = isDark
                      ? context.accent.withValues(alpha: 0.06)
                      : context.accent.withValues(alpha: 0.035);
                  final evenBg = isDark
                      ? HomeDesign.gold.withValues(alpha: 0.05)
                      : HomeDesign.gold.withValues(alpha: 0.03);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: double.infinity,
                        color: isOdd ? oddBg : evenBg,
                        padding: EdgeInsets.symmetric(
                          vertical: isDual ? 8 : 10,
                          horizontal: isDual ? 8 : 16,
                        ),
                        child: isDual
                            ? Directionality(
                                textDirection: TextDirection.rtl,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Right Column: First Hemistich (Sadr)
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.center,
                                          child: _buildRichArabicText(
                                            text: couplet.hemistich1,
                                            fontSize: _fontSize,
                                            weight: FontWeight.w600,
                                            textAlign: TextAlign.center,
                                            context: context,
                                            isDark: isDark,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Center Ornate Divider
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 3),
                                      child: SizedBox(
                                        height: 28,
                                        child: VerticalDivider(
                                          width: 1,
                                          thickness: 0.8,
                                          color: context.hairline.withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ),

                                    // Left Column: Second Hemistich (Ajjuz)
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.center,
                                          child: _buildRichArabicText(
                                            text: couplet.hemistich2,
                                            fontSize: _fontSize,
                                            weight: FontWeight.w600,
                                            textAlign: TextAlign.center,
                                            context: context,
                                            isDark: isDark,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Sadr: Aligned Right
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: _buildRichArabicText(
                                      text: couplet.hemistich1,
                                      fontSize: _fontSize,
                                      weight: FontWeight.w600,
                                      textAlign: TextAlign.right,
                                      context: context,
                                      isDark: isDark,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  // Ajjuz: Staggered with gold ✦ ornament
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Text(
                                          '✦',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: HomeDesign.goldText(isDark).withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildRichArabicText(
                                          text: couplet.hemistich2,
                                          fontSize: _fontSize,
                                          weight: FontWeight.w600,
                                          textAlign: TextAlign.left,
                                          context: context,
                                          isDark: isDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                      Container(height: 1, color: context.hairline),
                    ],
                  );
                }),
              );
            },
          ),
        ]

        // ── Prose Paragraphs & Adhkar — Hybrid Alignment (Center for short Dhikr / Right for long narrative)
        else
          ...section.paragraphs.map((paragraph) {
            final isShortDhikr = paragraph.length < 90 || section.type == MoulidSectionType.fathiha;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: _buildRichArabicText(
                      text: paragraph,
                      fontSize: _fontSize,
                      textAlign: isShortDhikr ? TextAlign.center : TextAlign.right,
                      context: context,
                      isDark: isDark,
                    ),
                  ),
                ),
                Container(height: 1, color: context.hairline),
              ],
            );
          }),

        // ── Qiyam Salawat Counter
        if (isQiyam) ...[
          const SizedBox(height: 16),
          Center(
            child: HeartbeatTap(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _salawatCount++);
                if (_salawatCount % 33 == 0) HapticFeedback.heavyImpact();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                decoration: BoxDecoration(
                  color: HomeDesign.gold.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: HomeDesign.gold.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app_rounded, size: 16, color: HomeDesign.gold),
                    const SizedBox(width: 8),
                    Text(
                      isMl ? 'സ്വലാത്ത് എണ്ണം: $_salawatCount' : 'Salawat: $_salawatCount',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: HomeDesign.goldText(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  // ─── Inline Section/Page Separator ───────────────────────────────

  Widget _buildSectionSeparator(
    MoulidSection section,
    ThemeProvider tp,
    bool isDark,
    Color accent,
    bool isMl,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Container(height: 1.0, color: context.hairline)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? context.cardTop : context.cardBottom,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.cardBorder, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        section.type == MoulidSectionType.baith ||
                                section.type == MoulidSectionType.qiyam
                            ? Icons.lyrics_outlined
                            : section.type == MoulidSectionType.dua
                                ? Icons.auto_awesome
                                : Icons.menu_book_rounded,
                        size: 13,
                        color: context.accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_sectionTypeLabel(section, isMl)}${section.page != null ? " • P. ${section.page}" : ""}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: context.accent,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(child: Container(height: 1.0, color: context.hairline)),
            ],
          ),

          // Optional Section Titles (Toggled from Settings)
          if (_showSectionTitles) ...[
            const SizedBox(height: 14),
            Text(
              section.titleArabic,
              style: TextStyle(
                fontFamily: 'HafsFont',
                fontSize: _fontSize * 0.78,
                fontWeight: FontWeight.bold,
                color: accent,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 3),
            Text(
              isMl ? section.titleMalayalam : section.title,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: context.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  String _sectionTypeLabel(MoulidSection section, bool isMl) {
    switch (section.type) {
      case MoulidSectionType.prose:
        return isMl ? 'ഫസൽ' : 'FASL';
      case MoulidSectionType.baith:
        return isMl ? 'ബൈത്ത്' : 'BAITH';
      case MoulidSectionType.qiyam:
        return isMl ? 'ക്വിയാം' : 'QIYAM';
      case MoulidSectionType.dua:
        return isMl ? 'ദുആ' : 'DUA';
      case MoulidSectionType.fathiha:
        return isMl ? 'ഫാത്തിഹ' : 'FATHIHA';
    }
  }

  // ─── Rich Arabic Text with Highlighted Counts & Verse Symbols ─────

  Widget _buildRichArabicText({
    required String text,
    required double fontSize,
    required TextAlign textAlign,
    required BuildContext context,
    required bool isDark,
    FontWeight weight = FontWeight.normal,
    Color? accentColor,
  }) {
    // Matches count tokens like (٣), (٧), (٢٥), (٤), (١٠), (3), (25), etc. and verse marks ۝
    final regex = RegExp(r'(\([٠-٩0-9]+\)|۝)');
    final matches = regex.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: _arabicStyle(
          size: fontSize,
          weight: weight,
          color: accentColor ?? context.textPrimary,
          height: 2.2,
        ),
        textAlign: textAlign,
        textDirection: TextDirection.rtl,
      );
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final m in matches) {
      if (m.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, m.start),
            style: _arabicStyle(
              size: fontSize,
              weight: weight,
              color: accentColor ?? context.textPrimary,
              height: 2.2,
            ),
          ),
        );
      }

      final matchedText = m.group(0)!;
      if (matchedText == '۝') {
        spans.add(
          TextSpan(
            text: ' $matchedText ',
            style: TextStyle(
              fontFamily: 'HafsFont',
              fontSize: fontSize * 0.9,
              fontWeight: FontWeight.bold,
              color: HomeDesign.goldText(isDark),
              height: 2.2,
            ),
          ),
        );
      } else {
        // Highlighted Repetition Count Badge in warm amber gold (e.g. (٣), (٧), (٢٥))
        spans.add(
          TextSpan(
            text: ' $matchedText ',
            style: TextStyle(
              fontFamily: 'HafsFont',
              fontSize: fontSize * 0.92,
              fontWeight: FontWeight.w800,
              color: HomeDesign.goldText(isDark),
              height: 2.2,
            ),
          ),
        );
      }
      lastEnd = m.end;
    }

    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: _arabicStyle(
            size: fontSize,
            weight: weight,
            color: accentColor ?? context.textPrimary,
            height: 2.2,
          ),
        ),
      );
    }

    return RichText(
      textAlign: textAlign,
      textDirection: TextDirection.rtl,
      text: TextSpan(children: spans),
    );
  }
}
