import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/home_design.dart';
import '../../widgets/heartbeat_tap.dart';

/// Onboarding appearance step. The app ships a single accent, so the only
/// choice here is dark or light.
class ObPage3Theme extends StatefulWidget {
  final VoidCallback onNext;
  const ObPage3Theme({super.key, required this.onNext});

  @override
  State<ObPage3Theme> createState() => _ObPage3ThemeState();
}

class _ObPage3ThemeState extends State<ObPage3Theme>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _entranceCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final accent = themeProvider.primaryAccent;
    final isDark = themeProvider.isDarkMode;

    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 680;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [HomeDesign.pageTop(isDark), HomeDesign.pageBottom(isDark)],
        ),
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(20, isSmall ? 10 : 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.1),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(
                        Icons.brightness_6_rounded,
                        color: accent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose Your Look',
                            style: GoogleFonts.outfit(
                              fontSize: isSmall ? 18 : 21,
                              fontWeight: FontWeight.w800,
                              color: themeProvider.textPrimary,
                            ),
                          ),
                          Text(
                            'You can change this any time from the home screen.',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: themeProvider.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Dark / Light choice
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ModeCard(
                          label: 'Dark',
                          caption: 'Easy on the eyes at night',
                          icon: Icons.nightlight_round,
                          isSelected: isDark,
                          previewTop: HomeDesign.pageTop(true),
                          previewBottom: HomeDesign.pageBottom(true),
                          previewCard: HomeDesign.cardTop(true),
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            themeProvider.setDarkMode(true);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ModeCard(
                          label: 'Light',
                          caption: 'Crisp and bright by day',
                          icon: Icons.wb_sunny_rounded,
                          isSelected: !isDark,
                          previewTop: HomeDesign.pageTop(false),
                          previewBottom: HomeDesign.pageBottom(false),
                          previewCard: HomeDesign.cardTop(false),
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            themeProvider.setDarkMode(false);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Continue
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: _ObThemeGlowButton(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.onNext();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String label;
  final String caption;
  final IconData icon;
  final bool isSelected;
  final Color previewTop;
  final Color previewBottom;
  final Color previewCard;
  final VoidCallback onTap;

  const _ModeCard({
    required this.label,
    required this.caption,
    required this.icon,
    required this.isSelected,
    required this.previewTop,
    required this.previewBottom,
    required this.previewCard,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final accent = themeProvider.primaryAccent;

    return HeartbeatTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: HomeDesign.cardGradient(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accent : HomeDesign.goldLine(isDark),
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: HomeDesign.shadow(isDark),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Miniature of the home surface in this mode.
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [previewTop, previewBottom],
                  ),
                  border: Border.all(color: HomeDesign.goldLine(isDark)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _previewBlock(height: 26, color: previewCard),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Expanded(
                            child: _previewBlock(
                              height: 16,
                              color: previewCard,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: _previewBlock(
                              height: 16,
                              color: previewCard,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Expanded(
                        child: _previewBlock(
                          height: double.infinity,
                          color: previewCard,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? accent : HomeDesign.gold,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: themeProvider.textPrimary,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.check_circle_rounded, size: 15, color: accent),
                ],
              ],
            ),
            const SizedBox(height: 3),
            Text(
              caption,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.outfit(
                fontSize: 10.5,
                color: themeProvider.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewBlock({required double height, required Color color}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: HomeDesign.gold.withValues(alpha: 0.25)),
      ),
    );
  }
}

class _ObThemeGlowButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ObThemeGlowButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return HeartbeatTap(
      onTap: onTap,
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: themeProvider.primaryAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Apply & Continue',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
