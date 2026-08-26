import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_update_service.dart';
import '../theme/jira_theme.dart';
import 'home_screen.dart';
import 'onboarding/onboarding_flow.dart';

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
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
    _startInitializationFlow();
  }

  Future<void> _startInitializationFlow() async {
    // Run splash delay and update check in parallel
    final splashWait = Future.delayed(const Duration(milliseconds: 1800));

    AppUpdateInfo? updateInfo;
    try {
      updateInfo = await AppUpdateService.fetchUpdateInfo(forceRemote: true);
    } catch (_) {
      // Ignore network errors/timeouts during splash
    }

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
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isForce
                      ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                      : JiraTheme.secondaryGreen.withValues(alpha: 0.5),
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
                  // Header Icon & Status
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isForce
                              ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                              : JiraTheme.secondaryGreen.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isForce
                              ? Icons.warning_amber_rounded
                              : Icons.system_update_rounded,
                          color: isForce
                              ? const Color(0xFFEF4444)
                              : JiraTheme.secondaryGreen,
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
                              style: GoogleFonts.outfit(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFF0F6FC),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Version v${info.versionName}',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: isForce
                                    ? const Color(0xFFF87171)
                                    : const Color(0xFF34D399),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Description
                  if (info.description.isNotEmpty) ...[
                    Text(
                      info.description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF8B949E),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Highlights preview (Features & Bug Fixes)
                  if (info.features.isNotEmpty || info.bugFixes.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D121D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF30363D)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final feat in info.features.take(2)) ...[
                            _buildDialogHighlightRow(
                              Icons.check_circle_outline_rounded,
                              JiraTheme.secondaryGreen,
                              feat,
                            ),
                            const SizedBox(height: 6),
                          ],
                          for (final fix in info.bugFixes.take(2)) ...[
                            _buildDialogHighlightRow(
                              Icons.build_circle_outlined,
                              const Color(0xFFFBBF24),
                              fix,
                            ),
                            const SizedBox(height: 6),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Action Buttons
                  ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      AppUpdateService.launchDownload(info.downloadUrl);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: JiraTheme.secondaryGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text(
                      'Update Now',
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  // "Later" button for non-critical updates
                  if (!isForce) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _navigateToNextScreen();
                      },
                      child: Text(
                        'Later / Continue to App',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF8B949E),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogHighlightRow(
      IconData icon, Color color, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: color, size: 13),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFFE6EDF3),
              fontSize: 12,
            ),
          ),
        ),
      ],
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
        transitionDuration: const Duration(milliseconds: 600),
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
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Spacer(flex: 3),

                                  // Glowing Mosque Emblem
                                  Container(
                                    width: 88,
                                    height: 88,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF161B22),
                                      border: Border.all(
                                        color: JiraTheme.primaryBlue,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              JiraTheme.primaryBlue.withValues(alpha: 0.35),
                                          blurRadius: 28,
                                          spreadRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.mosque_rounded,
                                        size: 44,
                                        color: Color(0xFF93C5FD),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Sacred Arabic Calligraphy
                                  const Text(
                                    'نُصَلِّي لِلَّهِ',
                                    style: TextStyle(
                                      fontFamily: 'HafsFont',
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF0F6FC),
                                      height: 1.2,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // English Title
                                  Text(
                                    'NUSWALLY LILLAH',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 4.0,
                                      color: JiraTheme.secondaryGreen,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  // Subtitle
                                  Text(
                                    'YOUR ISLAMIC SANCTUARY',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 2.0,
                                      color: const Color(0xFF8B949E),
                                    ),
                                  ),

                                  const Spacer(flex: 3),

                                  // Bottom Bismillah Calligraphy
                                  const Text(
                                    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                                    style: TextStyle(
                                      fontFamily: 'HafsFont',
                                      fontSize: 18,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // App Version Tag
                                  Text(
                                    'v${AppUpdateService.currentVersionName}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF475569),
                                      letterSpacing: 1.0,
                                    ),
                                  ),

                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
