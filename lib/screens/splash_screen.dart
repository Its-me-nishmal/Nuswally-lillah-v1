import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/app_update_service.dart';
import '../widgets/heartbeat_tap.dart';
import '../widgets/splash/animated_crescent_emblem.dart';
import 'home_screen.dart';
import 'onboarding/onboarding_flow.dart';
import '../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  final bool onboardingComplete;

  const SplashScreen({super.key, required this.onboardingComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    _startInitializationFlow();
  }

  Future<void> _startInitializationFlow() async {
    final splashWait = Future.delayed(const Duration(milliseconds: 1600));

    AppUpdateInfo? updateInfo;
    try {
      updateInfo = await AppUpdateService.fetchUpdateInfo(forceRemote: true);
    } catch (_) {}

    await splashWait;
    if (!mounted) return;

    if (updateInfo != null && AppUpdateService.isUpdateAvailable(updateInfo)) {
      _showUpdateDialog(updateInfo);
    } else {
      _navigateToNextScreen();
    }
  }

  void _showUpdateDialog(AppUpdateInfo info) {
    final isForce = AppUpdateService.isForceUpdate(info);
    final tp = context.read<ThemeProvider>();

    showDialog<void>(
      context: context,
      barrierDismissible: !isForce,
      builder: (ctx) {
        return PopScope(
          canPop: !isForce,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: tp.surfaceColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isForce
                      ? context.danger.withValues(alpha: 0.6)
                      : tp.primaryAccent.withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isForce
                              ? context.danger.withValues(alpha: 0.15)
                              : tp.primaryAccent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isForce
                              ? Icons.warning_amber_rounded
                              : Icons.system_update_rounded,
                          color: isForce ? context.danger : tp.primaryAccent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isForce
                                  ? 'Mandatory Update'
                                  : 'New Update Available',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: tp.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Version v${info.versionName}',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: isForce
                                    ? const Color(0xFFF87171)
                                    : tp.primaryAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (info.description.isNotEmpty) ...[
                    Text(
                      info.description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: tp.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Row(
                    children: [
                      if (!isForce)
                        Expanded(
                          child: HeartbeatTap(
                            onTap: () {
                              Navigator.pop(ctx);
                              _navigateToNextScreen();
                            },
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: tp.containerColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: tp.borderColor),
                              ),
                              child: Center(
                                child: Text(
                                  'Later',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: tp.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (!isForce) const SizedBox(width: 10),
                      Expanded(
                        child: HeartbeatTap(
                          onTap: () {
                            AppUpdateService.launchDownload(info.downloadUrl);
                          },
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: tp.primaryAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Update Now',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
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
        );
      },
    );
  }

  void _navigateToNextScreen() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim, _) {
          return widget.onboardingComplete
              ? const HomeScreen()
              : const OnboardingFlow();
        },
        transitionsBuilder: (context, anim, _, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watchTheme();
    final tp = context.watch<ThemeProvider>();
    final isDark = tp.isDarkMode;

    return Scaffold(
      backgroundColor: tp.backgroundTop,
      body: Stack(
        children: [
          // Background Gradient
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

          // Ambient Teal Radial Glow
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            left: -40,
            right: -40,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    tp.primaryAccent.withValues(alpha: isDark ? 0.12 : 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Center Floating Splash Box
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Container(
                          width: 290,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 28,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? context.cardTop
                                        : const Color(0xFFFFFFFF))
                                    .withValues(alpha: isDark ? 0.88 : 0.92),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: tp.primaryAccent.withValues(alpha: 0.45),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 32,
                                offset: const Offset(0, 12),
                              ),
                              BoxShadow(
                                color: tp.primaryAccent.withValues(alpha: 0.20),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Glowing Animated Crescent & Star Emblem
                              AnimatedCrescentEmblem(
                                size: 80,
                                primaryColor: tp.primaryAccent,
                              ),
                              const SizedBox(height: 12),

                              // Sacred Arabic Script
                              Text(
                                'نُصَلِّي لِلَّهِ',
                                style: TextStyle(
                                  fontFamily: 'HafsFont',
                                  fontSize: 26,
                                  fontWeight: FontWeight.normal,
                                  color: tp.textPrimary,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // English Title
                              Text(
                                'NUSWALLY LILLAH',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                  color: tp.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Sleek Micro Progress Indicator
                              SizedBox(
                                width: 36,
                                height: 3,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    backgroundColor: tp.borderColor,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      tp.primaryAccent,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
}
