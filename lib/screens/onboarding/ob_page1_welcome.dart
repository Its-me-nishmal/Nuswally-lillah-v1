import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class ObPage1Welcome extends StatefulWidget {
  final VoidCallback onNext;
  const ObPage1Welcome({super.key, required this.onNext});

  @override
  State<ObPage1Welcome> createState() => _ObPage1WelcomeState();
}

class _ObPage1WelcomeState extends State<ObPage1Welcome>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _staggerCtrl;
  late Animation<double> _pulse;
  late Animation<double> _fadeVerse;
  late Animation<Offset> _slideVerse;
  late Animation<double> _fadeName;
  late Animation<Offset> _slideName;
  late Animation<double> _fadeTagline;
  late Animation<double> _fadeBtn;
  late Animation<Offset> _slideBtn;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeVerse = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _staggerCtrl,
          curve: const Interval(0.0, 0.35, curve: Curves.easeOut)),
    );
    _slideVerse =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _staggerCtrl,
          curve: const Interval(0.0, 0.35, curve: Curves.easeOut)),
    );

    _fadeName = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _staggerCtrl,
          curve: const Interval(0.2, 0.55, curve: Curves.easeOut)),
    );
    _slideName =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _staggerCtrl,
          curve: const Interval(0.2, 0.55, curve: Curves.easeOut)),
    );

    _fadeTagline = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _staggerCtrl,
          curve: const Interval(0.4, 0.7, curve: Curves.easeOut)),
    );

    _fadeBtn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _staggerCtrl,
          curve: const Interval(0.65, 1.0, curve: Curves.easeOut)),
    );
    _slideBtn =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _staggerCtrl,
          curve: const Interval(0.65, 1.0, curve: Curves.easeOut)),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _staggerCtrl.forward();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final accent = theme.primaryAccent;
    final bgTop = theme.backgroundTop;
    final bgBottom = theme.backgroundBottom;

    // Responsive sizing
    final size = MediaQuery.of(context).size;
    final h = size.height;
    final isSmall = h < 680;
    final iconSize = isSmall ? 90.0 : 120.0;
    final titleFontSize = isSmall ? 26.0 : 32.0;
    final vGap1 = isSmall ? 20.0 : 32.0;
    final vGap2 = isSmall ? 20.0 : 36.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgTop, bgBottom],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: _GeometricRings(accent: accent)),
          SafeArea(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          SizedBox(height: h * 0.06),

                          // Animated Mosque Icon
                          ScaleTransition(
                            scale: _pulse,
                            child: _MosqueGlowIcon(
                                accent: accent, size: iconSize),
                          ),

                          SizedBox(height: vGap1),

                          // Quranic Verse
                          FadeTransition(
                            opacity: _fadeVerse,
                            child: SlideTransition(
                              position: _slideVerse,
                              child: Column(
                                children: [
                                  Text(
                                    '﴿ وَأَقِيمُوا الصَّلَاةَ ﴾',
                                    style: TextStyle(
                                      fontFamily: 'HafsFont',
                                      fontSize: isSmall ? 18.0 : 22.0,
                                      color: accent.withValues(alpha: 0.75),
                                      height: 1.8,
                                    ),
                                    textAlign: TextAlign.center,
                                    textDirection: TextDirection.rtl,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '"And establish prayer" — Al-Baqarah 2:43',
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 11,
                                      color:
                                          Colors.white.withValues(alpha: 0.3),
                                      fontStyle: FontStyle.italic,
                                      letterSpacing: 0.3,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: vGap2),

                          // App Name
                          FadeTransition(
                            opacity: _fadeName,
                            child: SlideTransition(
                              position: _slideName,
                              child: Column(
                                children: [
                                  Text(
                                    'Nuswally Lillah',
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'نُصَلِّي لِلّٰه',
                                    style: TextStyle(
                                      fontFamily: 'HafsFont',
                                      fontSize: isSmall ? 15.0 : 18.0,
                                      color: accent.withValues(alpha: 0.8),
                                    ),
                                    textAlign: TextAlign.center,
                                    textDirection: TextDirection.rtl,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Tagline
                          FadeTransition(
                            opacity: _fadeTagline,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'Your personal companion for every Salah — precise prayer times, Quran, Qibla & spiritual habits.',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: isSmall ? 12.0 : 13.5,
                                  height: 1.6,
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),

                          const Spacer(),

                          // CTA Button
                          FadeTransition(
                            opacity: _fadeBtn,
                            child: SlideTransition(
                              position: _slideBtn,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 28),
                                child: _GlowButton(
                                  label: 'Begin My Journey',
                                  accent: accent,
                                  icon: Icons.arrow_forward_rounded,
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    widget.onNext();
                                  },
                                ),
                              ),
                            ),
                          ),

                          SizedBox(
                              height: MediaQuery.of(context).padding.bottom +
                                  32),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Glow Button
// ─────────────────────────────────────────
class _GlowButton extends StatelessWidget {
  final String label;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;

  const _GlowButton({
    required this.label,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent, accent.withValues(alpha: 0.75)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 18, color: Colors.black),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Mosque Glow Icon
// ─────────────────────────────────────────
class _MosqueGlowIcon extends StatelessWidget {
  final Color accent;
  final double size;
  const _MosqueGlowIcon({required this.accent, required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size * 1.17,
          height: size * 1.17,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.04),
            border:
                Border.all(color: accent.withValues(alpha: 0.08), width: 1),
          ),
        ),
        Container(
          width: size * 0.92,
          height: size * 0.92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.07),
            border:
                Border.all(color: accent.withValues(alpha: 0.12), width: 1),
          ),
        ),
        Container(
          width: size * 0.67,
          height: size * 0.67,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.12),
            border:
                Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.mosque_rounded,
            size: size * 0.33,
            color: accent,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// Geometric Background Rings
// ─────────────────────────────────────────
class _GeometricRings extends StatelessWidget {
  final Color accent;
  const _GeometricRings({required this.accent});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _RingPainter(accent: accent));
  }
}

class _RingPainter extends CustomPainter {
  final Color accent;
  _RingPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final cx = size.width / 2;
    final cy = size.height * 0.38;

    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(Offset(cx, cy), 80.0 + i * 38, paint);
    }

    final linePaint = Paint()
      ..color = accent.withValues(alpha: 0.02)
      ..strokeWidth = 0.8;

    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawLine(
        Offset(cx + 55 * math.cos(angle), cy + 55 * math.sin(angle)),
        Offset(cx + 240 * math.cos(angle), cy + 240 * math.sin(angle)),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.accent != accent;
}
