import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/heartbeat_tap.dart';
import 'ob_page1_welcome.dart';
import 'ob_page2_location.dart';
import 'ob_page4_habits.dart';
import 'ob_page5_notifications.dart';
import 'ob_page6_summary.dart';
import '../../theme/app_colors.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _totalPages = 5;

  // Pages 0 (Welcome) and 4 (Summary) have no top progress bar
  bool get _showProgressBar => _currentPage >= 1 && _currentPage <= 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToPage(int page) async {
    if (page >= _totalPages) return;
    setState(() => _currentPage = page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }

  @override
  Widget build(BuildContext context) {
    context.watchTheme();
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: context.pageTop,
      body: Column(
        children: [
          SizedBox(height: topPad > 0 ? topPad + 4 : 14),

          // ── Progress Bar — Only on steps 1, 2, 3 ──
          if (_showProgressBar)
            _OnboardingProgressBar(
              currentPage: _currentPage,
              totalSteps: 3,
              onBack: _currentPage > 1
                  ? () {
                      HapticFeedback.lightImpact();
                      _goToPage(_currentPage - 1);
                    }
                  : null,
            ),

          // ── Page Content ──
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ObPage1Welcome(onNext: () => _goToPage(1)),
                ObPage2Location(onNext: () => _goToPage(2)),
                ObPage4Habits(onNext: () => _goToPage(3)),
                ObPage5Notifications(
                  onNext: () async {
                    await markComplete();
                    if (mounted) _goToPage(4);
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
// Progress Bar
// ─────────────────────────────────────────
class _OnboardingProgressBar extends StatelessWidget {
  final int currentPage;
  final int totalSteps;
  final VoidCallback? onBack;

  const _OnboardingProgressBar({
    required this.currentPage,
    required this.totalSteps,
    this.onBack,
  });

  static const _stepLabels = [
    'LOCATION SETUP',
    'SPIRITUAL RHYTHM',
    'PRAYER NOTIFICATIONS',
  ];

  @override
  Widget build(BuildContext context) {
    context.watchTheme();
    final stepIndex = (currentPage - 1).clamp(0, totalSteps - 1);
    final label = _stepLabels[stepIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (onBack != null) ...[
                    HeartbeatTap(
                      onTap: onBack!,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: context.cardTop,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.cardBorder),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 16,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    'STEP $currentPage OF $totalSteps • $label',
                    style: GoogleFonts.outfit(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: context.accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 3-Segment Glowing Progress Bar
          Row(
            children: List.generate(totalSteps, (i) {
              final isFilled = i < currentPage;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: isFilled ? context.accent : context.cardBottom,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: isFilled
                        ? [
                            BoxShadow(
                              color: context.accent.withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
