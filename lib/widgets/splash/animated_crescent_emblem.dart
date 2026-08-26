import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedCrescentEmblem extends StatefulWidget {
  final double size;
  final Color primaryColor;
  final Color? secondaryColor;

  const AnimatedCrescentEmblem({
    super.key,
    this.size = 80,
    required this.primaryColor,
    this.secondaryColor,
  });

  @override
  State<AnimatedCrescentEmblem> createState() => _AnimatedCrescentEmblemState();
}

class _AnimatedCrescentEmblemState extends State<AnimatedCrescentEmblem>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _crescentProgress;
  late Animation<double> _starScale;
  late Animation<double> _starRotation;
  late Animation<double> _auraPulse;

  @override
  void initState() {
    super.initState();

    // 1. Entrance & Reveal Animation (1400ms)
    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _crescentProgress = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.0, 0.70, curve: Curves.easeOutCubic),
    );

    _starScale = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.40, 0.90, curve: Curves.elasticOut),
    );

    _starRotation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.40, 0.95, curve: Curves.easeOutBack),
      ),
    );

    // 2. Continuous Ambient Breathing Pulse (2400ms loop)
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _auraPulse = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOutSine),
    );

    _mainCtrl.forward();
    _pulseCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_mainCtrl, _pulseCtrl]),
        builder: (context, _) {
          return CustomPaint(
            painter: _CrescentStarPainter(
              crescentProgress: _crescentProgress.value,
              starScale: _starScale.value,
              starRotation: _starRotation.value,
              auraScale: _auraPulse.value,
              primaryColor: widget.primaryColor,
              secondaryColor: widget.secondaryColor ?? const Color(0xFFFBBF24),
            ),
          );
        },
      ),
    );
  }
}

class _CrescentStarPainter extends CustomPainter {
  final double crescentProgress;
  final double starScale;
  final double starRotation;
  final double auraScale;
  final Color primaryColor;
  final Color secondaryColor;

  _CrescentStarPainter({
    required this.crescentProgress,
    required this.starScale,
    required this.starRotation,
    required this.auraScale,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.46, size.height * 0.50);
    final radius = size.width * 0.38;

    // 1. Ambient Glow Halo
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: 0.35 * crescentProgress),
          primaryColor.withValues(alpha: 0.10 * crescentProgress),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5 * auraScale));

    canvas.drawCircle(center, radius * 1.5 * auraScale, auraPaint);

    if (crescentProgress <= 0.01) return;

    // 2. Draw Sacred Crescent Path (Moon Geometry)
    final outerPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    // Inner cutter circle shifted to create elegant thin crescent tip
    final innerCenter = Offset(center.dx + radius * 0.35, center.dy - radius * 0.12);
    final innerPath = Path()
      ..addOval(Rect.fromCircle(center: innerCenter, radius: radius * 0.82));

    final crescentPath = Path.combine(PathOperation.difference, outerPath, innerPath);

    // Save and clip with progress rotation arc for smooth reveal
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi * 0.25 * (1.0 - crescentProgress));
    canvas.translate(-center.dx, -center.dy);

    final crescentGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryColor,
        primaryColor.withValues(alpha: 0.85),
        const Color(0xFF5EEAD4),
      ],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final crescentPaint = Paint()
      ..shader = crescentGradient
      ..style = PaintingStyle.fill;

    // Glowing border shadow
    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);

    canvas.drawPath(crescentPath, glowPaint);
    canvas.drawPath(crescentPath, crescentPaint);
    canvas.restore();

    // 3. Draw Radiant 8-Pointed Star in Crescent Nook
    if (starScale > 0.01) {
      final starCenter = Offset(center.dx + radius * 0.42, center.dy - radius * 0.36);
      final starRadius = radius * 0.24 * starScale;

      canvas.save();
      canvas.translate(starCenter.dx, starCenter.dy);
      canvas.rotate(starRotation * math.pi * 2);

      // Star Glow
      final starGlowPaint = Paint()
        ..color = secondaryColor.withValues(alpha: 0.6 * starScale)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6);

      final starPath = _createOctagramPath(Offset.zero, starRadius, starRadius * 0.48);

      final starPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            secondaryColor,
            const Color(0xFFFDE68A),
            primaryColor,
          ],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: starRadius))
        ..style = PaintingStyle.fill;

      canvas.drawPath(starPath, starGlowPaint);
      canvas.drawPath(starPath, starPaint);
      canvas.restore();
    }
  }

  Path _createOctagramPath(Offset center, double outerRadius, double innerRadius) {
    final path = Path();
    const points = 8;
    const step = math.pi / points;

    for (int i = 0; i < points * 2; i++) {
      final r = (i % 2 == 0) ? outerRadius : innerRadius;
      final angle = i * step - math.pi / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _CrescentStarPainter oldDelegate) {
    return oldDelegate.crescentProgress != crescentProgress ||
        oldDelegate.starScale != starScale ||
        oldDelegate.starRotation != starRotation ||
        oldDelegate.auraScale != auraScale ||
        oldDelegate.primaryColor != primaryColor;
  }
}
