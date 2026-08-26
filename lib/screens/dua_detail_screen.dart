import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/adhkaar.dart';
import '../providers/theme_provider.dart';
import '../theme/jira_theme.dart';
import '../widgets/heartbeat_tap.dart';
import '../widgets/jira_screen.dart';

class DuaDetailScreen extends StatefulWidget {
  final Dua dua;

  const DuaDetailScreen({super.key, required this.dua});

  @override
  State<DuaDetailScreen> createState() => _DuaDetailScreenState();
}

class _DuaDetailScreenState extends State<DuaDetailScreen> with SingleTickerProviderStateMixin {
  late int _count;
  late int _targetCount;
  bool _isPlaying = false;
  bool _isBookmarked = false;
  late AnimationController _waveformController;

  @override
  void initState() {
    super.initState();
    _count = 0;
    _targetCount = int.tryParse(RegExp(r'\d+').firstMatch(widget.dua.hint)?.group(0) ?? '') ?? 1;
    if (_targetCount <= 0) _targetCount = 1;

    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveformController.dispose();
    super.dispose();
  }

  void _incrementCount() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_count < _targetCount) {
        _count++;
      } else {
        _count = 0; // reset on full completion
      }
    });
  }

  void _togglePlay() {
    HapticFeedback.selectionClick();
    setState(() {
      _isPlaying = !_isPlaying;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isPlaying ? 'Playing recitation audio...' : 'Audio paused'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final dua = widget.dua;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return JiraScreen(
      child: Stack(
        children: [
          Column(
            children: [
              // 1. Top App Bar
              _buildTopAppBar(context, tp),

              // 2. Scrollable Detail Content
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const SizedBox(height: 8),

                    // Centerpiece Hero Arabic Recitation & Audio Card
                    _buildHeroArabicCard(dua, tp),

                    const SizedBox(height: 14),

                    // Phonetic Transliteration Card
                    if (dua.transli.isNotEmpty) ...[
                      _buildTransliterationCard(dua.transli, tp),
                      const SizedBox(height: 14),
                    ],

                    SizedBox(height: 90 + bottomInset), // Bottom clearance for floating counter
                  ],
                ),
              ),
            ],
          ),

          // 3. Floating Repetition Counter Dock
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset > 0 ? bottomInset + 12 : 20,
            child: Center(
              child: _buildFloatingCounterDock(tp),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Top App Bar
  Widget _buildTopAppBar(BuildContext context, ThemeProvider tp) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Circular back button
          HeartbeatTap(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tp.surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(color: tp.borderColor),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: tp.textPrimary,
                size: 18,
              ),
            ),
          ),

          // Center: Title + Glowing Blue Orb
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DUA FOCUS',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: tp.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: tp.primaryAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: tp.primaryAccent.withValues(alpha: 0.8),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Right: Bookmark & Share buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HeartbeatTap(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isBookmarked = !_isBookmarked);
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tp.surfaceColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: tp.borderColor),
                  ),
                  child: Icon(
                    _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: _isBookmarked ? tp.primaryAccent : tp.textSecondary,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              HeartbeatTap(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Clipboard.setData(ClipboardData(text: '${widget.dua.dua}\n\n${widget.dua.transli}'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dua copied to clipboard'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tp.surfaceColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: tp.borderColor),
                  ),
                  child: Icon(
                    Icons.share_outlined,
                    color: tp.textSecondary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Hero Centerpiece Card (Arabic Recitation & Audio Bar)
  Widget _buildHeroArabicCard(Dua dua, ThemeProvider tp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tp.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tp.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Repetition Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: JiraTheme.secondaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: JiraTheme.secondaryGreen.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.repeat_rounded,
                      size: 13,
                      color: JiraTheme.secondaryGreen,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'REPEAT $_targetCount TIMES',
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: JiraTheme.secondaryGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Dua Reference Number
              Text(
                '#${dua.id.toString().padLeft(2, '0')}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tp.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Sacred Arabic Calligraphy
          Text(
            dua.dua,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'HafsFont',
              fontSize: 24,
              fontWeight: FontWeight.normal,
              color: tp.textPrimary,
              height: 1.8,
            ),
          ),

          const SizedBox(height: 24),

          // Audio Player Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: tp.containerColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tp.borderColor, width: 0.8),
            ),
            child: Row(
              children: [
                // Circular Play/Pause button
                HeartbeatTap(
                  onTap: _togglePlay,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: tp.primaryAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: tp.primaryAccent.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Waveform bars
                Expanded(
                  child: SizedBox(
                    height: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(12, (index) {
                        final isHighlighted = index < 4 || _isPlaying;
                        final heights = [8.0, 16.0, 22.0, 14.0, 10.0, 18.0, 24.0, 12.0, 16.0, 20.0, 10.0, 6.0];
                        return AnimatedBuilder(
                          animation: _waveformController,
                          builder: (context, child) {
                            final factor = _isPlaying
                                ? (0.4 + 0.6 * ((index % 2 == 0) ? _waveformController.value : (1.0 - _waveformController.value)))
                                : 1.0;
                            return Container(
                              width: 3,
                              height: heights[index % heights.length] * factor,
                              decoration: BoxDecoration(
                                color: isHighlighted ? tp.primaryAccent : tp.textMuted.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Timestamp
                Text(
                  _isPlaying ? '0:05 / 0:12' : '0:00 / 0:12',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: tp.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Phonetic Transliteration Card
  Widget _buildTransliterationCard(String transliteration, ThemeProvider tp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tp.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tp.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRANSLITERATION',
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: tp.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            transliteration,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: tp.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Floating Repetition Counter Dock
  Widget _buildFloatingCounterDock(ThemeProvider tp) {
    final isCompleted = _count >= _targetCount;

    return HeartbeatTap(
      onTap: _incrementCount,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: tp.surfaceColor.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isCompleted ? JiraTheme.secondaryGreen : tp.borderColor,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isCompleted ? JiraTheme.secondaryGreen : Colors.black).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isCompleted ? 'COMPLETED' : 'TAP TO COUNT',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isCompleted ? JiraTheme.secondaryGreen : tp.textPrimary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isCompleted ? JiraTheme.secondaryGreen : tp.containerColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_count/$_targetCount',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isCompleted ? Colors.white : tp.primaryAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
