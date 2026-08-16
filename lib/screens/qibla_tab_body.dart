import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/prayer_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/heartbeat_tap.dart';
import 'qibla_screen.dart' show CompassPainter, NeedlePainter;

/// Qibla compass tab body used inside [HomeScreen].
class QiblaTabBody extends StatefulWidget {
  const QiblaTabBody({super.key});

  @override
  State<QiblaTabBody> createState() => _QiblaTabBodyState();
}

class _QiblaTabBodyState extends State<QiblaTabBody> with SingleTickerProviderStateMixin {
  double _heading = 45.0;
  final double _qiblaBearing = 292.0; // Perfect Qibla bearing
  
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
    return (_qiblaBearing - _heading) % 360;
  }

  bool get _isAligned {
    final diff = (_heading - _qiblaBearing).abs();
    return diff < 4.0 || diff > 356.0;
  }

  void _onPanUpdate(DragUpdateDetails details) {
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
    
    final activeColor = tp.primaryAccent;
    final isAligned = _isAligned;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Location indicator card
            _buildLocationCard(locationName, districtName, tp),
            const SizedBox(height: 24),
            
            // Alignment Badge
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isAligned
                  ? Container(
                      key: const ValueKey('aligned'),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: activeColor, width: 1.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.gps_fixed_rounded, color: activeColor, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'PERFECTLY ALIGNED',
                            style: GoogleFonts.jetBrainsMono(
                              color: activeColor,
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
                            'ROTATE COMPASS TO ALIGN',
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
            
            const SizedBox(height: 32),

            // Immersive compass rose
            GestureDetector(
              onPanUpdate: _onPanUpdate,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ambient aura
                  const SizedBox(
                    width: 250,
                    height: 250,
                  ),
                  
                  // Compass background ring
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tp.surfaceColor,
                      border: Border.all(
                        color: isAligned 
                            ? activeColor.withValues(alpha: 0.4) 
                            : tp.borderColor,
                        width: 2,
                      ),
                    ),
                  ),

                  // The Rotating Compass Dial
                  Transform.rotate(
                    angle: -_heading * math.pi / 180,
                    child: SizedBox(
                      width: 240,
                      height: 240,
                      child: CustomPaint(
                        painter: CompassPainter(
                          qiblaAngle: _qiblaBearing,
                          accentColor: activeColor,
                        ),
                      ),
                    ),
                  ),

                  // Fixed Kaaba pointer needle (pointing up)
                  Transform.rotate(
                    angle: _relativeAngle * math.pi / 180,
                    child: SizedBox(
                      width: 240,
                      height: 240,
                      child: CustomPaint(
                        painter: NeedlePainter(accentColor: activeColor),
                      ),
                    ),
                  ),

                  // Center Kaaba silhouette indicator
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAligned ? activeColor : tp.containerColor,
                      border: Border.all(
                        color: isAligned ? Colors.transparent : activeColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.mosque,
                      color: isAligned ? tp.backgroundBottom : activeColor,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 36),

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
            
            const SizedBox(height: 24),

            // Tips card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tp.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tp.borderColor, width: 1.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: tp.primaryAccent.withValues(alpha: 0.7), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hold your device flat and keep away from metal objects or magnetic fields for maximum accuracy.',
                      style: GoogleFonts.outfit(
                        color: tp.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 120), // Clearance for bottom navigation bar
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(String location, String district, ThemeProvider tp) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: tp.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tp.borderColor, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_rounded, color: tp.primaryAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                '$location, $district',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: tp.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        HeartbeatTap(
          onTap: () {
            setState(() {
              _heading = _qiblaBearing;
            });
            HapticFeedback.heavyImpact();
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tp.surfaceColor,
              shape: BoxShape.circle,
              border: Border.all(color: tp.borderColor, width: 1.0),
            ),
            child: Icon(
              Icons.autorenew_rounded,
              color: tp.primaryAccent,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subValue,
    required ThemeProvider themeProvider,
  }) {
    return Container(
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
    );
  }
}
