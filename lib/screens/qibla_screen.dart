import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/prayer_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/heartbeat_tap.dart';
import '../widgets/jira_header.dart';
import '../widgets/jira_screen.dart';

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
    final tp = context.watch<ThemeProvider>();
    final locationName = prayerProvider.selectedLocation?.name ?? 'Kozhikode';
    final districtName = prayerProvider.selectedLocation?.district ?? 'Kerala';
    final isAligned = _isAligned;

    return JiraScreen(
      child: Column(
        children: [
          JiraHeader(
            title: 'Qibla Finder',
            actions: [
              _buildHeaderActionButton(
                icon: Icons.autorenew_rounded,
                tooltip: 'Simulate perfect alignment',
                themeProvider: tp,
                onTap: () {
                  setState(() {
                    // Instantly align compass to let user see perfect state
                    _heading = _qiblaBearing;
                    HapticFeedback.heavyImpact();
                  });
                },
              ),
            ],
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, 16 + MediaQuery.paddingOf(context).bottom),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Location indicator card
                            _buildLocationCard(locationName, districtName, tp),
                            const SizedBox(height: 20),

                            // Alignment Badge
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: isAligned
                                  ? Container(
                                      key: const ValueKey('aligned'),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: tp.primaryAccent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: tp.primaryAccent, width: 1.0),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.gps_fixed_rounded, color: tp.primaryAccent, size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            'PERFECTLY ALIGNED',
                                            style: GoogleFonts.jetBrainsMono(
                                              color: tp.primaryAccent,
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
                                        color: tp.containerColor,
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(color: tp.borderColor, width: 1),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.explore_outlined, color: tp.textMuted, size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            'ROTATE DEVICE TO ALIGN',
                                            style: GoogleFonts.jetBrainsMono(
                                              color: tp.textMuted,
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
                                  const SizedBox(
                                    width: 290,
                                    height: 290,
                                  ),

                                  // Compass background ring
                                  Container(
                                    width: 280,
                                    height: 280,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: tp.surfaceColor,
                                      border: Border.all(
                                        color: isAligned
                                            ? tp.primaryAccent.withValues(alpha: 0.4)
                                            : tp.borderColor,
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
                                          accentColor: tp.primaryAccent,
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
                                        painter: NeedlePainter(accentColor: tp.primaryAccent),
                                      ),
                                    ),
                                  ),

                                  // Center Kaaba silhouette indicator
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isAligned ? tp.primaryAccent : tp.containerColor,
                                      border: Border.all(
                                        color: isAligned ? Colors.transparent : tp.primaryAccent.withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.mosque,
                                      color: isAligned ? tp.backgroundBottom : tp.primaryAccent,
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
                                  themeProvider: tp,
                                ),
                                _buildMetricCard(
                                  title: 'DISTANCE',
                                  value: '3,950 km',
                                  subValue: 'To Makkah',
                                  themeProvider: tp,
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Tips card
                            _buildTipsCard(tp),
                            const SizedBox(height: 12),
                          ],
                        ),
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

  Widget _buildHeaderActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeProvider themeProvider,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: HeartbeatTap(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: themeProvider.surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: themeProvider.borderColor, width: 1.0),
          ),
          child: Center(
            child: Icon(icon, size: 18, color: themeProvider.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard(String location, String district, ThemeProvider themeProvider) {
    return HeartbeatTap(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: themeProvider.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: themeProvider.borderColor, width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_rounded, color: themeProvider.primaryAccent, size: 18),
            const SizedBox(width: 8),
            Text(
              '$location, $district',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: themeProvider.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subValue,
    required ThemeProvider themeProvider,
  }) {
    return HeartbeatTap(
      onTap: () {},
      child: Container(
        width: 145,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeProvider.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: themeProvider.borderColor, width: 1.0),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: themeProvider.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: themeProvider.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subValue,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: themeProvider.primaryAccent.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard(ThemeProvider themeProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeProvider.borderColor, width: 1.0),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: themeProvider.primaryAccent.withValues(alpha: 0.7), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hold your device flat and keep away from metal objects or magnetic fields for maximum accuracy.',
              style: GoogleFonts.outfit(
                color: themeProvider.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
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
