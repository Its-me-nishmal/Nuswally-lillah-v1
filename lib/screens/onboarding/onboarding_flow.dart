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

  static const int _totalPages = 6;

  // Pages 0 (Welcome) and 5 (Summary) have no progress bar
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
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final accent = theme.primaryAccent;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: theme.backgroundBottom,
      body: Column(
        children: [
          // ── Status bar area (always present, transparent) ──
          SizedBox(height: topPad),

          // ── Progress bar — only on pages 1–4 ──
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: _showProgressBar
                ? _OnboardingProgressBar(
                    currentPage: _currentPage,
                    totalSteps: 4,
                    accent: accent,
                    onBack: _currentPage > 1
                        ? () {
                            HapticFeedback.lightImpact();
                            _goToPage(_currentPage - 1);
                          }
                        : null,
                  )
                : const SizedBox.shrink(),
          ),

          // ── Page content ──
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ObPage1Welcome(onNext: () => _goToPage(1)),
                ObPage2Location(onNext: () => _goToPage(2)),
                ObPage3Theme(onNext: () => _goToPage(3)),
                ObPage4Habits(onNext: () => _goToPage(4)),
                ObPage5Notifications(
                  onNext: () async {
                    await markComplete();
                    if (mounted) _goToPage(5);
                  },
                ),
                const ObPage6Summary(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Progress Bar — sits between status bar and page content
// ─────────────────────────────────────────
class _OnboardingProgressBar extends StatelessWidget {
  final int currentPage;
  final int totalSteps;
  final Color accent;
  final VoidCallback? onBack;

  const _OnboardingProgressBar({
    required this.currentPage,
    required this.totalSteps,
    required this.accent,
    this.onBack,
  });

  static const _stepLabels = ['Location', 'Theme', 'Habits', 'Alerts'];

  @override
  Widget build(BuildContext context) {
    final stepIndex = (currentPage - 1).clamp(0, totalSteps - 1);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 20, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Step chips row ──
          Row(
            children: [
              // Back button (fixed 36px slot)
              SizedBox(
                width: 36,
                child: onBack != null
                    ? GestureDetector(
                        onTap: onBack,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 15,
                            color: accent.withValues(alpha: 0.7),
                          ),
                        ),
                      )
                    : null,
              ),

              // Step chips
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalSteps, (i) {
                    final isActive = i == stepIndex;
                    final isDone = i < stepIndex;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: EdgeInsets.symmetric(
                          horizontal: isActive ? 10 : 6,
                          vertical: 4,
                        ),
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

              // Step counter (fixed 36px slot)
              SizedBox(
                width: 36,
                child: Text(
                  '${stepIndex + 1}/$totalSteps',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Thin progress line ──
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
