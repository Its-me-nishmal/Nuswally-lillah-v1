import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Hand-drawn glyphs for the home surface.
///
/// These exist because the shapes in the design (an ogee mosque arch, a
/// tasbeeh bead loop, a rub-el-hizb star) have no Material equivalent.

/// Decorative gold mosque arch with a crescent, stars and a domed silhouette.
/// Sits at the right edge of the next-prayer hero card.
class MosqueArchGlyph extends StatelessWidget {
  final double width;
  final double height;
  final Color gold;
  final Color domeColor;

  const MosqueArchGlyph({
    super.key,
    required this.width,
    required this.height,
    required this.gold,
    required this.domeColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _MosqueArchPainter(gold: gold, domeColor: domeColor),
      ),
    );
  }
}

class _MosqueArchPainter extends CustomPainter {
  final Color gold;
  final Color domeColor;

  _MosqueArchPainter({required this.gold, required this.domeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // --- Ogee arch outline -------------------------------------------
    final arch = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.44)
      ..cubicTo(w * 0.03, h * 0.22, w * 0.30, h * 0.09, w * 0.50, 0)
      ..cubicTo(w * 0.70, h * 0.09, w * 0.97, h * 0.22, w, h * 0.44)
      ..lineTo(w, h);

    canvas.drawPath(
      arch,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [gold.withValues(alpha: 0.06), gold.withValues(alpha: 0.01)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    canvas.drawPath(
      arch,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = gold.withValues(alpha: 0.55),
    );

    // --- Crescent moon ------------------------------------------------
    final moonCenter = Offset(w * 0.52, h * 0.30);
    final moonRadius = w * 0.145;
    final outer = Path()
      ..addOval(Rect.fromCircle(center: moonCenter, radius: moonRadius));
    final cut = Path()
      ..addOval(
        Rect.fromCircle(
          center: moonCenter.translate(moonRadius * 0.46, -moonRadius * 0.20),
          radius: moonRadius * 0.88,
        ),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, cut),
      Paint()..color = gold.withValues(alpha: 0.92),
    );

    // --- Stars --------------------------------------------------------
    final starPaint = Paint()..color = gold.withValues(alpha: 0.75);
    for (final star in const [
      Offset(0.24, 0.22),
      Offset(0.78, 0.26),
      Offset(0.34, 0.40),
      Offset(0.70, 0.44),
    ]) {
      canvas.drawCircle(Offset(w * star.dx, h * star.dy), w * 0.014, starPaint);
    }

    // --- Mosque silhouette -------------------------------------------
    final baseY = h;
    final bodyTop = h * 0.78;
    final domePaint = Paint()..color = domeColor;
    final domeEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = gold.withValues(alpha: 0.42);

    // Central dome + prayer hall.
    final hall = Path()
      ..moveTo(w * 0.30, baseY)
      ..lineTo(w * 0.30, bodyTop)
      ..cubicTo(w * 0.30, h * 0.60, w * 0.42, h * 0.55, w * 0.50, h * 0.55)
      ..cubicTo(w * 0.58, h * 0.55, w * 0.70, h * 0.60, w * 0.70, bodyTop)
      ..lineTo(w * 0.70, baseY)
      ..close();
    canvas.drawPath(hall, domePaint);
    canvas.drawPath(hall, domeEdge);

    // Finial on the dome.
    canvas.drawLine(
      Offset(w * 0.50, h * 0.55),
      Offset(w * 0.50, h * 0.50),
      Paint()
        ..strokeWidth = 1.0
        ..color = gold.withValues(alpha: 0.6),
    );

    // Flanking minarets.
    for (final x in const [0.20, 0.80]) {
      final rect = Rect.fromLTRB(
        w * (x - 0.035),
        h * 0.66,
        w * (x + 0.035),
        baseY,
      );
      canvas.drawRect(rect, domePaint);
      canvas.drawRect(rect, domeEdge);
      final cap = Path()
        ..moveTo(rect.left, h * 0.66)
        ..lineTo(rect.center.dx, h * 0.58)
        ..lineTo(rect.right, h * 0.66)
        ..close();
      canvas.drawPath(cap, domePaint);
      canvas.drawPath(cap, domeEdge);
    }

    // Arched windows in the prayer hall.
    final windowPaint = Paint()..color = gold.withValues(alpha: 0.30);
    for (final x in const [0.395, 0.50, 0.605]) {
      final left = w * (x - 0.026);
      final right = w * (x + 0.026);
      final top = h * 0.83;
      final window = Path()
        ..moveTo(left, baseY)
        ..lineTo(left, top)
        ..cubicTo(left, h * 0.78, right, h * 0.78, right, top)
        ..lineTo(right, baseY)
        ..close();
      canvas.drawPath(window, windowPaint);
    }
  }

  @override
  bool shouldRepaint(_MosqueArchPainter old) =>
      old.gold != gold || old.domeColor != domeColor;
}

/// Tasbeeh bead loop with a tassel.
class TasbeehGlyph extends StatelessWidget {
  final double size;
  final Color color;

  const TasbeehGlyph({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _TasbeehPainter(color: color)),
    );
  }
}

class _TasbeehPainter extends CustomPainter {
  final Color color;

  _TasbeehPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final center = Offset(size.width * 0.5, size.height * 0.42);
    final radius = size.width * 0.30;
    final bead = size.width * 0.058;

    // Bead loop, open at the bottom for the tassel.
    const beadCount = 11;
    const sweep = math.pi * 1.62;
    final start = math.pi * 0.69;
    for (var i = 0; i < beadCount; i++) {
      final angle = start + (sweep / (beadCount - 1)) * i;
      canvas.drawCircle(
        center + Offset(math.cos(angle) * radius, math.sin(angle) * radius),
        bead,
        paint,
      );
    }

    // Tassel: two smaller beads then a cord.
    final tailTop = Offset(size.width * 0.5, size.height * 0.70);
    canvas.drawCircle(tailTop, bead * 0.86, paint);
    canvas.drawCircle(tailTop.translate(0, bead * 2.3), bead * 0.74, paint);
    canvas.drawLine(
      tailTop.translate(0, bead * 3.1),
      Offset(size.width * 0.5, size.height * 0.94),
      Paint()
        ..color = color
        ..strokeWidth = size.width * 0.045
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TasbeehPainter old) => old.color != color;
}

/// Rub-el-hizb (eight-point star) framing the "99" label.
class NinetyNineGlyph extends StatelessWidget {
  final double size;
  final Color color;

  const NinetyNineGlyph({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _NinetyNinePainter(color: color)),
    );
  }
}

class _NinetyNinePainter extends CustomPainter {
  final Color color;

  _NinetyNinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final half = size.width * 0.40;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.055
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    // Two overlapping squares, one rotated 45°.
    for (final rotation in [0.0, math.pi / 4]) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: half * 2, height: half * 2),
        stroke,
      );
      canvas.restore();
    }

    final label = TextPainter(
      text: TextSpan(
        text: '99',
        style: TextStyle(
          color: color,
          fontSize: size.width * 0.34,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, center - Offset(label.width / 2, label.height / 2));
  }

  @override
  bool shouldRepaint(_NinetyNinePainter old) => old.color != color;
}
