import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/prayer_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/journal_provider.dart';
import '../home_screen.dart';

class ObPage6Summary extends StatefulWidget {
  const ObPage6Summary({super.key});

  @override
  State<ObPage6Summary> createState() => _ObPage6SummaryState();
}

class _ObPage6SummaryState extends State<ObPage6Summary>
    with TickerProviderStateMixin {
  late AnimationController _checkCtrl;
  late AnimationController _cardCtrl;
  late AnimationController _particleCtrl;
  late Animation<double> _checkScale;
  late Animation<double> _checkOpacity;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _btnFade;
  bool _enteringApp = false;

  final List<_Particle> _particles = List.generate(18, (i) => _Particle(i));

  @override
  void initState() {
    super.initState();

    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    _checkScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _checkCtrl, curve: Curves.easeOut));

    _checkOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _checkCtrl,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOut)));

    _cardFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut));
    _cardSlide = Tween<Offset>(
            begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));

    _btnFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _cardCtrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));

    // Staggered sequence
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      _checkCtrl.forward();
      _particleCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _cardCtrl.forward();
    });
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _cardCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  Future<void> _enterApp() async {
    if (_enteringApp) return;
    setState(() => _enteringApp = true);
    HapticFeedback.mediumImpact();

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (ctx, anim, _) => const HomeScreen(),
        transitionsBuilder: (ctx, anim, _, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final accent = theme.primaryAccent;
    final bgTop = theme.backgroundTop;
    final bgBottom = theme.backgroundBottom;
    final cardColor = theme.containerColor;

    final prayerProvider = context.watch<PrayerProvider>();
    final journalProvider = context.watch<JournalProvider>();

    final locationName = prayerProvider.selectedLocation != null
        ? '${prayerProvider.selectedLocation!.name}, ${prayerProvider.selectedLocation!.district}'
        : 'Not set';
    final habitCount = journalProvider.habits.length;
    final adhanSound =
        prayerProvider.adhanNotificationSounds['Fajr'] ?? 'Full Adhan';

    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 680;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgTop, bgBottom],
        ),
      ),
      child: Stack(
        children: [
          // Particle burst
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleCtrl,
              builder: (ctx, _) => CustomPaint(
                painter:
                    _ParticlePainter(_particles, _particleCtrl.value, accent),
              ),
            ),
          ),

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
                          SizedBox(height: isSmall ? 24 : 40),

                          // Animated check mark
                          AnimatedBuilder(
                            animation: _checkCtrl,
                            builder: (ctx, _) => Opacity(
                              opacity: _checkOpacity.value,
                              child: ScaleTransition(
                                scale: _checkScale,
                                child: _CheckCircle(
                                    accent: accent, isSmall: isSmall),
                              ),
                            ),
                          ),

                          SizedBox(height: isSmall ? 16 : 24),

                          // Arabic Bismillah
                          FadeTransition(
                            opacity: _cardFade,
                            child: Column(
                              children: [
                                Text(
                                  'بِسْمِ اللهِ',
                                  style: TextStyle(
                                    fontFamily: 'HafsFont',
                                    fontSize: isSmall ? 22 : 28,
                                    color: accent,
                                  ),
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'In the Name of Allah — You\'re all set!',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: isSmall ? 18 : 28),

                          // Summary card
                          SlideTransition(
                            position: _cardSlide,
                            child: FadeTransition(
                              opacity: _cardFade,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: _SummaryCard(
                                  accent: accent,
                                  cardColor: cardColor,
                                  themeName: theme.themeName,
                                  locationName: locationName,
                                  habitCount: habitCount,
                                  adhanSound: adhanSound,
                                  isSmall: isSmall,
                                ),
                              ),
                            ),
                          ),

                          const Spacer(),

                          SizedBox(height: isSmall ? 12 : 20),

                          // Enter App button
                          FadeTransition(
                            opacity: _btnFade,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                  24, 0, 24, bottomPad + 24),
                              child: GestureDetector(
                                onTap: _enterApp,
                                child: Container(
                                  height: 56,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        accent,
                                        accent.withValues(alpha: 0.75)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accent.withValues(alpha: 0.4),
                                        blurRadius: 22,
                                        offset: const Offset(0, 7),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.mosque_rounded,
                                          size: 18, color: Colors.black),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Enter the App',
                                        style: GoogleFonts.hankenGrotesk(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black,
                                          letterSpacing: 0.3,
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

// ─── Check Circle ───
class _CheckCircle extends StatelessWidget {
  final Color accent;
  final bool isSmall;
  const _CheckCircle({required this.accent, required this.isSmall});

  @override
  Widget build(BuildContext context) {
    final s = isSmall ? 0.8 : 1.0;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120 * s,
          height: 120 * s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.04),
          ),
        ),
        Container(
          width: 88 * s,
          height: 88 * s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.1),
            border: Border.all(color: accent.withValues(alpha: 0.2), width: 1),
          ),
        ),
        Container(
          width: 62 * s,
          height: 62 * s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.15),
            border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(Icons.check_rounded, color: accent, size: 26 * s),
        ),
      ],
    );
  }
}

// ─── Summary Card ───
class _SummaryCard extends StatelessWidget {
  final Color accent;
  final Color cardColor;
  final String themeName;
  final String locationName;
  final int habitCount;
  final String adhanSound;
  final bool isSmall;

  const _SummaryCard({
    required this.accent,
    required this.cardColor,
    required this.themeName,
    required this.locationName,
    required this.habitCount,
    required this.adhanSound,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 16 : 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Your Personalization',
            style: GoogleFonts.hankenGrotesk(
              fontSize: isSmall ? 10 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: accent.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: isSmall ? 10 : 16),
          _SummaryRow(
            icon: Icons.location_on_rounded,
            label: 'Location',
            value: locationName,
            accent: accent,
          ),
          _Divider(accent: accent),
          _SummaryRow(
            icon: Icons.palette_rounded,
            label: 'Theme',
            value: themeName,
            accent: accent,
          ),
          _Divider(accent: accent),
          _SummaryRow(
            icon: Icons.auto_awesome_rounded,
            label: 'Habits',
            value: habitCount == 0
                ? 'None selected'
                : '$habitCount habit${habitCount == 1 ? '' : 's'} tracked',
            accent: accent,
          ),
          _Divider(accent: accent),
          _SummaryRow(
            icon: Icons.notifications_active_rounded,
            label: 'Adhan Alert',
            value: adhanSound,
            accent: accent,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accent.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.4),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final Color accent;
  const _Divider({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: accent.withValues(alpha: 0.07),
    );
  }
}

// ─── Particle Painter ───
class _Particle {
  final double angle;
  final double radius;
  final double size;
  final double speed;

  _Particle(int seed)
      : angle = (seed * 20.0) * math.pi / 180,
        radius = 80 + (seed % 5) * 20.0,
        size = 3.0 + (seed % 4) * 1.5,
        speed = 0.6 + (seed % 3) * 0.15;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color accent;

  _ParticlePainter(this.particles, this.progress, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.35;

    for (final p in particles) {
      final t = (progress * p.speed).clamp(0.0, 1.0);
      final fade = (1.0 - t).clamp(0.0, 1.0);
      final r = p.radius * t;

      final paint = Paint()
        ..color = accent.withValues(alpha: 0.5 * fade)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(cx + r * math.cos(p.angle), cy + r * math.sin(p.angle)),
        p.size * (1 - t * 0.4),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
