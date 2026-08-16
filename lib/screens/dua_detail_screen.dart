import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/adhkaar.dart';
import '../theme/jira_theme.dart';
import '../widgets/heartbeat_tap.dart';

class DuaDetailScreen extends StatefulWidget {
  final Dua dua;

  const DuaDetailScreen({super.key, required this.dua});

  @override
  State<DuaDetailScreen> createState() => _DuaDetailScreenState();
}

class _DuaDetailScreenState extends State<DuaDetailScreen> with SingleTickerProviderStateMixin {
  int _count = 0;
  int _targetCount = 3;
  bool _isPlaying = false;
  bool _isBookmarked = false;
  late AnimationController _waveformController;

  @override
  void initState() {
    super.initState();
    // Parse target repetition count from hint if available
    final hintDigits = RegExp(r'\d+').firstMatch(widget.dua.hint);
    if (hintDigits != null) {
      _targetCount = int.tryParse(hintDigits.group(0) ?? '3') ?? 3;
    }

    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
        if (_count == _targetCount) {
          HapticFeedback.heavyImpact();
        }
      } else {
        _count = 1; // reset cycle
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
    final dua = widget.dua;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // 1. Top App Bar
                _buildTopAppBar(context),

                // 2. Scrollable Detail Content (Focused purely on Arabic & Transliteration)
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      const SizedBox(height: 8),

                      // Centerpiece Hero Arabic Recitation & Audio Card
                      _buildHeroArabicCard(dua),

                      const SizedBox(height: 14),

                      // Phonetic Transliteration Card
                      if (dua.transli.isNotEmpty) ...[
                        _buildTransliterationCard(dua.transli),
                        const SizedBox(height: 14),
                      ],

                      const SizedBox(height: 90), // Bottom clearance for floating counter
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Floating Repetition Counter Dock
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Center(
              child: _buildFloatingCounterDock(),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Top App Bar
  Widget _buildTopAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Circular frosted back button
          HeartbeatTap(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFFF0F6FC),
                size: 20,
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
                  color: const Color(0xFFF0F6FC),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: JiraTheme.primaryBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: JiraTheme.primaryBlue.withValues(alpha: 0.8),
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF30363D)),
                  ),
                  child: Icon(
                    _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: _isBookmarked ? JiraTheme.primaryBlue : const Color(0xFFF0F6FC),
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF30363D)),
                  ),
                  child: const Icon(
                    Icons.share_outlined,
                    color: Color(0xFFF0F6FC),
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
  Widget _buildHeroArabicCard(Dua dua) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF30363D), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
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
                  color: const Color(0xFF8B949E),
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
            style: const TextStyle(
              fontFamily: 'HafsFont',
              fontSize: 24,
              fontWeight: FontWeight.normal,
              color: Colors.white,
              height: 1.8,
            ),
          ),

          const SizedBox(height: 24),

          // Audio Player Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0E14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF30363D), width: 0.8),
            ),
            child: Row(
              children: [
                // Circular Play/Pause button
                HeartbeatTap(
                  onTap: _togglePlay,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: JiraTheme.primaryBlue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: JiraTheme.primaryBlue.withValues(alpha: 0.4),
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
                                color: isHighlighted ? const Color(0xFF93C5FD) : const Color(0xFF30363D),
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
                    color: const Color(0xFF8B949E),
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
  Widget _buildTransliterationCard(String transliteration) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D)),
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
              color: const Color(0xFF8B949E),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            transliteration,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFC7D2FE),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Floating Repetition Counter Dock
  Widget _buildFloatingCounterDock() {
    final isCompleted = _count >= _targetCount;

    return HeartbeatTap(
      onTap: _incrementCount,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isCompleted ? JiraTheme.secondaryGreen : const Color(0xFF30363D),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isCompleted ? JiraTheme.secondaryGreen : Colors.black).withValues(alpha: 0.4),
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
                color: isCompleted ? JiraTheme.secondaryGreen : Colors.white,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isCompleted ? JiraTheme.secondaryGreen : const Color(0xFF1F242C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_count/$_targetCount',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isCompleted ? Colors.black : const Color(0xFF93C5FD),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
