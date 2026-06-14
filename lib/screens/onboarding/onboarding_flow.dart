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
          // ── Status bar area (always present, transparent, with minimum safety pad) ──
          SizedBox(height: topPad > 0 ? topPad + 6 : 16),

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

  static const _stepLabels = [
    'Location Setup',
    'Personalize Theme',
    'Build Daily Rhythm',
    'Prayer Alerts',
  ];

  static const _stepSubtitles = [
    'Select your area',
    'Choose your mood style',
    'Track your custom habits',
    'Configure notifications',
  ];

  static const _stepIcons = [
    Icons.location_on_rounded,
    Icons.palette_rounded,
    Icons.auto_awesome_rounded,
    Icons.notifications_active_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final stepIndex = (currentPage - 1).clamp(0, totalSteps - 1);
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 680;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 8, 20, isSmall ? 10 : 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Segmented Progress Bar ──
          Row(
            children: List.generate(totalSteps, (i) {
              final isCompletedOrActive = i <= stepIndex;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: i == 0 ? 0 : 3.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompletedOrActive
                          ? accent
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          ),

          SizedBox(height: isSmall ? 14 : 18),

          // ── Header Row ──
          Row(
            children: [
              // Back Button (with modern glass circle)
              if (onBack != null) ...[
                GestureDetector(
                  onTap: onBack,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 0.8,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Step info (Title & Description)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'STEP ${stepIndex + 1} OF $totalSteps',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: accent.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          _stepIcons[stepIndex],
                          size: 14,
                          color: accent,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _stepLabels[stepIndex],
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: isSmall ? 14 : 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _stepSubtitles[stepIndex],
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Step pill badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Setup',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
