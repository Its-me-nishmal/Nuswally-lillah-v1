import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/prayer_provider.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with SingleTickerProviderStateMixin {
  // Heading angle from North (0 to 360)
  // Initially we start at some arbitrary angle and animate/let user simulate it
  double _heading = 45.0;
  final double _qiblaBearing = 292.0; // Perfect Qibla bearing from Kerala (WNW)
  
  late AnimationController _pulseController;
  bool _hasSignaledAlignment = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  double get _relativeAngle {
    // Relative angle of the Kaaba needle from the top of the screen
    return (_qiblaBearing - _heading) % 360;
  }

  bool get _isAligned {
    final diff = (_heading - _qiblaBearing).abs();
    return diff < 4.0 || diff > 356.0;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // Let user drag on the dial to simulate rotating their phone
    // Rotating clock-wise increases heading, counter-clock-wise decreases heading
    setState(() {
      _heading = (_heading + details.delta.dx * 0.4) % 360;
      if (_isAligned) {
        if (!_hasSignaledAlignment) {
          HapticFeedback.heavyImpact();
          _hasSignaledAlignment = true;
        } else {
          HapticFeedback.selectionClick();
        }
      } else {
        _hasSignaledAlignment = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prayerProvider = Provider.of<PrayerProvider>(context);
    final locationName = prayerProvider.selectedLocation?.name ?? 'Kozhikode';
    final districtName = prayerProvider.selectedLocation?.district ?? 'Kerala';
    
    final colorScheme = Theme.of(context).colorScheme;
    final isAligned = _isAligned;

    return Scaffold(
      backgroundColor: const Color(0xFF051424),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Color(0xFF09253d),
              Color(0xFF051424),
            ],
            radius: 1.2,
            center: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Location indicator card
                      _buildLocationCard(locationName, districtName),
                      const SizedBox(height: 30),
                      
                      // Alignment Badge
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: isAligned
                            ? Container(
                                key: const ValueKey('aligned'),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: colorScheme.primary, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.gps_fixed_rounded, color: colorScheme.primary, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'PERFECTLY ALIGNED',
                                      style: GoogleFonts.jetBrainsMono(
                                        color: colorScheme.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                key: const ValueKey('aligning'),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.explore_outlined, color: Colors.white.withValues(alpha: 0.4), size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'ROTATE DEVICE TO ALIGN',
                                      style: GoogleFonts.jetBrainsMono(
                                        color: Colors.white.withValues(alpha: 0.4),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      
                      const Spacer(),

                      // Immersive compass rose
                      GestureDetector(
                        onPanUpdate: _onPanUpdate,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer ambient aura
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                final scale = 1.0 + (_pulseController.value * 0.05);
                                return Container(
                                  width: 290,
                                  height: 290,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: isAligned
                                            ? colorScheme.primary.withValues(alpha: 0.12 * scale)
                                            : colorScheme.primary.withValues(alpha: 0.01),
                                        blurRadius: 40,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            
                            // Compass background ring
                            Container(
                              width: 280,
                              height: 280,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0C1D2F).withValues(alpha: 0.6),
                                border: Border.all(
                                  color: isAligned 
                                      ? colorScheme.primary.withValues(alpha: 0.4) 
                                      : Colors.white.withValues(alpha: 0.05),
                                  width: 2,
                                ),
                              ),
                            ),

                            // The Rotating Compass Dial
                            Transform.rotate(
                              angle: -_heading * math.pi / 180,
                              child: SizedBox(
                                width: 280,
                                height: 280,
                                child: CustomPaint(
                                  painter: CompassPainter(
                                    qiblaAngle: _qiblaBearing,
                                    accentColor: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),

                            // Fixed Kaaba pointer needle (pointing up)
                            Transform.rotate(
                              angle: _relativeAngle * math.pi / 180,
                              child: SizedBox(
                                width: 280,
                                height: 280,
                                child: CustomPaint(
                                  painter: NeedlePainter(accentColor: colorScheme.primary),
                                ),
                              ),
                            ),

                            // Center Kaaba silhouette indicator
                            Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isAligned ? colorScheme.primary : const Color(0xFF051424),
                                  border: Border.all(
                                    color: isAligned ? Colors.transparent : colorScheme.primary.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    if (isAligned)
                                      BoxShadow(
                                        color: colorScheme.primary.withValues(alpha: 0.4),
                                        blurRadius: 15,
                                        spreadRadius: 3,
                                      ),
                                  ],
                                ),
                              child: Icon(
                                Icons.mosque,
                                color: isAligned ? const Color(0xFF051424) : colorScheme.primary,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(),

                      // Bearing and distance metrics
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMetricCard(
                            title: 'BEARING',
                            value: '${_heading.toInt()}° NW',
                            subValue: 'Qibla: ${_qiblaBearing.toInt()}°',
                            colorScheme: colorScheme,
                          ),
                          _buildMetricCard(
                            title: 'DISTANCE',
                            value: '3,950 km',
                            subValue: 'To Makkah',
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),

                      // Tips card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: colorScheme.primary.withValues(alpha: 0.6), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Hold your device flat and keep away from metal objects or magnetic fields for maximum accuracy.',
                                style: GoogleFonts.hankenGrotesk(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          ),
          Text(
            'QIBLA FINDER',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                // Instantly align compass to let user see perfect state
                _heading = _qiblaBearing;
                HapticFeedback.heavyImpact();
              });
            },
            icon: const Icon(Icons.autorenew_rounded, color: Colors.white),
            tooltip: 'Simulate perfect alignment',
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(String location, String district) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF122131),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF5EEAD4).withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_rounded, color: Color(0xFF5EEAD4), size: 18),
          const SizedBox(width: 8),
          Text(
            '$location, $district',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFD4E4FA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subValue,
    required ColorScheme colorScheme,
  }) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF122131),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.3),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subValue,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 11,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class CompassPainter extends CustomPainter {
  final double qiblaAngle;
  final Color accentColor;

  CompassPainter({required this.qiblaAngle, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintTick = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.5;

    final paintAccentTick = Paint()
      ..color = accentColor.withValues(alpha: 0.7)
      ..strokeWidth = 2.0;

    // Draw degree ticks
    for (int i = 0; i < 360; i += 5) {
      final angle = i * math.pi / 180;
      final isMajor = i % 30 == 0;
      final isCardinals = i % 90 == 0;
      
      final tickLength = isCardinals ? 18.0 : (isMajor ? 12.0 : 6.0);
      final currentPaint = (i == 0 || (i - qiblaAngle).abs() < 2.5) ? paintAccentTick : paintTick;
      
      final start = Offset(
        center.dx + (radius - 12 - tickLength) * math.cos(angle),
        center.dy + (radius - 12 - tickLength) * math.sin(angle),
      );
      final end = Offset(
        center.dx + (radius - 12) * math.cos(angle),
        center.dy + (radius - 12) * math.sin(angle),
      );

      canvas.drawLine(start, end, currentPaint);

      // Draw text for N, E, S, W
      if (isCardinals) {
        // Align coordinates to standard compass mapping: N at 0 (top/270), E at 90 (0), S at 180 (90), W at 270 (180)
        // Let's draw traditional compass markings
        String traditionalDir = '';
        if (i == 270) {
          traditionalDir = 'N';
        } else if (i == 0) {
          traditionalDir = 'E';
        } else if (i == 90) {
          traditionalDir = 'S';
        } else if (i == 180) {
          traditionalDir = 'W';
        }

        if (traditionalDir.isNotEmpty) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: traditionalDir,
              style: GoogleFonts.jetBrainsMono(
                color: traditionalDir == 'N' ? Colors.redAccent : Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          
          final textOffset = Offset(
            center.dx + (radius - 40) * math.cos(angle) - textPainter.width / 2,
            center.dy + (radius - 40) * math.sin(angle) - textPainter.height / 2,
          );
          textPainter.paint(canvas, textOffset);
        }
      }
    }

    // Draw thin elegant grid lines inside compass
    final paintGrid = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius * 0.7, paintGrid);
    canvas.drawCircle(center, radius * 0.4, paintGrid);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NeedlePainter extends CustomPainter {
  final Color accentColor;

  NeedlePainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw the Qibla (Kaaba) pointer pointing up
    final needlePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Needle pointing upwards
    path.moveTo(center.dx, center.dy - radius + 24);
    path.lineTo(center.dx - 8, center.dy - radius + 55);
    path.lineTo(center.dx + 8, center.dy - radius + 55);
    path.close();

    canvas.drawPath(path, needlePaint);

    // Glowing glow effect around needle
    final glowPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
