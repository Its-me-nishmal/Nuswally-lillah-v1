import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';
import 'ob_page1_welcome.dart';
import 'ob_page2_location.dart';
import 'ob_page3_theme.dart';
import 'ob_page4_habits.dart';
import 'ob_page5_notifications.dart';
import 'ob_page6_summary.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Total pages: Welcome, Location, Theme, Habits, Notifications, Summary
  static const int _totalPages = 6;

  // Pages 0 (Welcome) and 5 (Summary) don't show the progress bar
  bool get _showProgressBar => _currentPage >= 1 && _currentPage <= 4;

  late AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  Future<void> _goToPage(int page) async {
    if (page >= _totalPages) return;
    setState(() => _currentPage = page);

    // Animate progress bar
    if (_showProgressBar) {
      // progress bar covers pages 1–4 (4 steps)
      final target = (page - 1) / 4.0;
      _progressCtrl.animateTo(target.clamp(0.0, 1.0));
    }

    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  /// Marks onboarding as complete in SharedPrefs (called before entering app)
  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final accent = theme.primaryAccent;

    return Scaffold(
      backgroundColor: theme.backgroundBottom,
      body: Stack(
        children: [
          // Page content
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // no manual swipe
            children: [
              // Page 1 — Welcome
              ObPage1Welcome(
                onNext: () => _goToPage(1),
              ),

              // Page 2 — Location (mandatory)
              ObPage2Location(
                onNext: () => _goToPage(2),
              ),

              // Page 3 — Theme
              ObPage3Theme(
                onNext: () => _goToPage(3),
              ),

              // Page 4 — Habits
              ObPage4Habits(
                onNext: () => _goToPage(4),
              ),

              // Page 5 — Notifications
              ObPage5Notifications(
                onNext: () async {
                  await markComplete();
                  if (mounted) _goToPage(5);
                },
              ),

              // Page 6 — Summary / Enter App
              const ObPage6Summary(),
            ],
          ),

          // ── Top Progress Bar (pages 1–4) ──
          if (_showProgressBar)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _OnboardingProgressBar(
                currentPage: _currentPage,
                totalSteps: 4,
                accent: accent,
                pageController: _pageController,
                onBack: _currentPage > 1
                    ? () {
                        HapticFeedback.lightImpact();
                        _goToPage(_currentPage - 1);
                      }
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Top Progress Bar Widget
// ─────────────────────────────────────────
class _OnboardingProgressBar extends StatelessWidget {
  final int currentPage; // 1-indexed page (1=location, 2=theme, 3=habits, 4=notifs)
  final int totalSteps;
  final Color accent;
  final PageController pageController;
  final VoidCallback? onBack;

  const _OnboardingProgressBar({
    required this.currentPage,
    required this.totalSteps,
    required this.accent,
    required this.pageController,
    this.onBack,
  });

  static const _stepLabels = ['Location', 'Theme', 'Habits', 'Alerts'];

  @override
  Widget build(BuildContext context) {
    // currentPage is 1 (Location) through 4 (Notifications)
    final stepIndex = (currentPage - 1).clamp(0, totalSteps - 1);

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 24,
        bottom: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Step info row
          Row(
            children: [
              // Back button
              SizedBox(
                width: 40,
                child: onBack != null
                    ? GestureDetector(
                        onTap: onBack,
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: accent.withValues(alpha: 0.7),
                        ),
                      )
                    : null,
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalSteps, (i) {
                    final isActive = i == stepIndex;
                    final isDone = i < stepIndex;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: EdgeInsets.symmetric(
                            horizontal: isActive ? 10 : 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDone
                              ? accent.withValues(alpha: 0.15)
                              : isActive
                                  ? accent.withValues(alpha: 0.12)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDone
                                ? accent.withValues(alpha: 0.3)
                                : isActive
                                    ? accent.withValues(alpha: 0.4)
                                    : Colors.white.withValues(alpha: 0.06),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isDone)
                              Icon(Icons.check_rounded,
                                  size: 10,
                                  color: accent.withValues(alpha: 0.8))
                            else
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive
                                      ? accent
                                      : Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                            if (isActive) ...[
                              const SizedBox(width: 5),
                              Text(
                                _stepLabels[i],
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              // Step counter
              SizedBox(
                width: 40,
                child: Text(
                  '${stepIndex + 1}/$totalSteps',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Thin progress line
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (stepIndex + 1) / totalSteps,
              minHeight: 2,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}
