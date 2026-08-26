import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/adhkaar.dart';
import '../providers/theme_provider.dart';
import '../widgets/heartbeat_tap.dart';

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
    final isDark = tp.isDarkMode;
    final dua = widget.dua;
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const double kTopBarHeight = 56.0;

    return Scaffold(
      backgroundColor: tp.backgroundTop,
      body: Stack(
        children: [
          // Background Gradient & Subtle Pattern
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [tp.backgroundTop, tp.backgroundBottom],
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

          // Scrollable Detail Content
          Positioned.fill(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, topInset + kTopBarHeight + 12, 16, bottomInset + 100),
              children: [
                // Centerpiece Hero Arabic Recitation & Audio Card
                _buildHeroArabicCard(dua, tp, isDark),

                const SizedBox(height: 14),

                // Phonetic Transliteration Card
                if (dua.transli.isNotEmpty) ...[
                  _buildTransliterationCard(dua.transli, tp, isDark),
                  const SizedBox(height: 14),
                ],

                // Translation & Meaning Card
                if (dua.trans.isNotEmpty || dua.descEn.isNotEmpty) ...[
                  _buildTranslationCard(dua, tp, isDark),
                  const SizedBox(height: 14),
                ],

                // Hadith / Reference Card
                if (dua.ref.isNotEmpty)
                  _buildReferenceCard(dua.ref, tp, isDark),
              ],
            ),
          ),

          // Fixed Frosted 56px Top Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topInset + kTopBarHeight,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.only(top: topInset),
                  decoration: BoxDecoration(
                    color: tp.backgroundTop.withValues(alpha: isDark ? 0.85 : 0.90),
                    border: Border(
                      bottom: BorderSide(
                        color: tp.borderColor.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: Container(
                    height: 56.0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Back Button
                        HeartbeatTap(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: tp.surfaceColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: tp.borderColor, width: 0.8),
                            ),
                            child: Center(
                              child: Icon(Icons.arrow_back_ios_new_rounded, color: tp.textPrimary, size: 16),
                            ),
                          ),
                        ),

                        // Center Title
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'DUA FOCUS',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: tp.textPrimary,
                                letterSpacing: 0.8,
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

                        // Bookmark & Share buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HeartbeatTap(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _isBookmarked = !_isBookmarked);
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: tp.surfaceColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: tp.borderColor, width: 0.8),
                                ),
                                child: Center(
                                  child: Icon(
                                    _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                                    color: _isBookmarked ? tp.primaryAccent : tp.textSecondary,
                                    size: 17,
                                  ),
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
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: tp.surfaceColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: tp.borderColor, width: 0.8),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.share_outlined,
                                    color: tp.textSecondary,
                                    size: 17,
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
              ),
            ),
          ),

          // Floating Repetition Counter Dock
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset > 0 ? bottomInset + 10 : 18,
            child: Center(
              child: _buildFloatingCounterDock(tp, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroArabicCard(Dua dua, ThemeProvider tp, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tp.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tp.borderColor, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tp.primaryAccent.withValues(alpha: isDark ? 0.12 : 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: tp.primaryAccent.withValues(alpha: isDark ? 0.25 : 0.35),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.repeat_rounded, size: 13, color: tp.primaryAccent),
                    const SizedBox(width: 5),
                    Text(
                      'REPEAT $_targetCount TIMES',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: tp.primaryAccent,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                '#${dua.id.toString().padLeft(2, '0')}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tp.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Sacred Arabic Calligraphy
          Text(
            dua.dua,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'HafsFont',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFF0F6FC) : const Color(0xFF0F172A),
              height: 1.85,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 20),

          // Audio Player Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151D24) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF222D38) : const Color(0xFFE2E8F0),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                HeartbeatTap(
                  onTap: _togglePlay,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: tp.primaryAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: tp.primaryAccent.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isPlaying ? 'Playing Audio Recitation' : 'Listen Recitation',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: tp.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Authentic Arabic Phonation',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: tp.textSecondary,
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

  Widget _buildTransliterationCard(String transli, ThemeProvider tp, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tp.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tp.borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.record_voice_over_outlined, color: tp.primaryAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                'TRANSLITERATION',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: tp.primaryAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            transli,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: tp.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationCard(Dua dua, ThemeProvider tp, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tp.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tp.borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.translate_rounded, color: tp.primaryAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                'MEANING & TRANSLATION',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: tp.primaryAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            dua.trans.isNotEmpty ? dua.trans : dua.descEn,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: tp.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceCard(String ref, ThemeProvider tp, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tp.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tp.borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, color: tp.primaryAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                'HADITH / QURAN REFERENCE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: tp.primaryAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ref,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tp.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCounterDock(ThemeProvider tp, bool isDark) {
    final isDone = _count >= _targetCount;

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF0E1418) : Colors.white).withValues(
              alpha: isDark ? 0.92 : 0.95,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDone
                  ? tp.primaryAccent.withValues(alpha: 0.6)
                  : tp.borderColor.withValues(alpha: 0.6),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular Tap Counter Button
              HeartbeatTap(
                onTap: _incrementCount,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDone ? tp.primaryAccent : tp.primaryAccent.withValues(alpha: isDark ? 0.15 : 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDone ? tp.primaryAccent : tp.primaryAccent.withValues(alpha: isDark ? 0.3 : 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDone ? Icons.check_circle_rounded : Icons.touch_app_rounded,
                        size: 17,
                        color: isDone ? Colors.white : tp.primaryAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_count / $_targetCount',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDone ? Colors.white : tp.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Reset Icon Button
              HeartbeatTap(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _count = 0);
                },
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.refresh_rounded, size: 18, color: tp.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
