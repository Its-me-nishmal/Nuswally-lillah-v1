import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

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

  static const List<_ThemeOption> _themes = [
    _ThemeOption(
      style: AppThemeStyle.teal,
      name: 'Oasis Teal',
      arabicMood: 'سَكِينَة',
      arabicMoodEn: 'Serenity',
      accent: Color(0xFF2DD4BF),
      bgTop: Color(0xFF07191C),
      bgBottom: Color(0xFF030D0F),
    ),
    _ThemeOption(
      style: AppThemeStyle.gold,
      name: 'Royal Gold',
      arabicMood: 'نُور',
      arabicMoodEn: 'Light',
      accent: Color(0xFFF59E0B),
      bgTop: Color(0xFF161108),
      bgBottom: Color(0xFF0D0A04),
    ),
    _ThemeOption(
      style: AppThemeStyle.emerald,
      name: 'Emerald Deen',
      arabicMood: 'إِيمَان',
      arabicMoodEn: 'Faith',
      accent: Color(0xFF10B981),
      bgTop: Color(0xFF051D14),
      bgBottom: Color(0xFF020E0A),
    ),
    _ThemeOption(
      style: AppThemeStyle.purple,
      name: 'Mystic Purple',
      arabicMood: 'تَأَمُّل',
      arabicMoodEn: 'Contemplation',
      accent: Color(0xFFC084FC),
      bgTop: Color(0xFF150E22),
      bgBottom: Color(0xFF0A0711),
    ),
    _ThemeOption(
      style: AppThemeStyle.crimson,
      name: 'Crimson Rose',
      arabicMood: 'مَحَبَّة',
      arabicMoodEn: 'Love',
      accent: Color(0xFFFB7185),
      bgTop: Color(0xFF200B10),
      bgBottom: Color(0xFF100508),
    ),
    _ThemeOption(
      style: AppThemeStyle.ocean,
      name: 'Ocean Breeze',
      arabicMood: 'صَفَاء',
      arabicMoodEn: 'Clarity',
      accent: Color(0xFF38BDF8),
      bgTop: Color(0xFF0A1724),
      bgBottom: Color(0xFF050B12),
    ),
  ];

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
    final bgTop = themeProvider.backgroundTop;
    final bgBottom = themeProvider.backgroundBottom;

    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 680;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgTop, bgBottom],
        ),
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding:
                    EdgeInsets.fromLTRB(20, isSmall ? 16 : 24, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.1),
                        border: Border.all(
                            color: accent.withValues(alpha: 0.25)),
                      ),
                      child: Icon(Icons.palette_rounded,
                          color: accent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose Your Soul',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: isSmall ? 18 : 21,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Every color reflects a different spiritual mood.',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Theme Grid ──
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    // Card height: adapt to available height
                    final rows = 3;
                    final spacing = 12.0;
                    final cardH =
                        (constraints.maxHeight - spacing * (rows - 1) - 8) /
                            rows;
                    final cardW = (constraints.maxWidth - 40 - spacing) / 2;
                    final ratio = cardW / cardH;

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: ratio.clamp(0.9, 2.0),
                      ),
                      itemCount: _themes.length,
                      itemBuilder: (ctx, i) {
                        final opt = _themes[i];
                        final isSelected =
                            themeProvider.themeStyle == opt.style;
                        return _ThemeCard(
                          option: opt,
                          isSelected: isSelected,
                          containerColor: themeProvider.containerColor,
                          isSmall: isSmall,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            themeProvider.setThemeStyle(opt.style);
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              // ── Continue Button ──
              Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 10, 20, MediaQuery.of(context).padding.bottom + 20),
                child: _ObThemeGlowButton(
                  accent: accent,
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

class _ThemeCard extends StatelessWidget {
  final _ThemeOption option;
  final bool isSelected;
  final Color containerColor;
  final bool isSmall;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.option,
    required this.isSelected,
    required this.containerColor,
    required this.isSmall,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? option.accent
                  : option.accent.withValues(alpha: 0.1),
              width: isSelected ? 1.8 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: option.accent.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmall ? 10 : 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Color dot
                    Container(
                      width: isSmall ? 22 : 26,
                      height: isSmall ? 22 : 26,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            option.accent,
                            option.accent.withValues(alpha: 0.5)
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: option.accent.withValues(alpha: 0.45),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.black, size: 12)
                          : null,
                    ),
                    // Mini preview strip
                    Container(
                      width: 32,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: LinearGradient(
                          colors: [option.bgTop, option.bgBottom],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: option.accent.withValues(alpha: 0.2),
                          width: 0.8,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 14,
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: option.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  option.arabicMood,
                  style: TextStyle(
                    fontFamily: 'HafsFont',
                    fontSize: isSmall ? 13 : 15,
                    color: option.accent,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 1),
                Text(
                  option.name,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: isSmall ? 10 : 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  option.arabicMoodEn,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 9,
                    color: option.accent.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ObThemeGlowButton extends StatelessWidget {
  final Color accent;
  final VoidCallback onTap;

  const _ObThemeGlowButton({required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent, accent.withValues(alpha: 0.75)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'This Is Me',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_rounded,
                size: 18, color: Colors.black),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption {
  final AppThemeStyle style;
  final String name;
  final String arabicMood;
  final String arabicMoodEn;
  final Color accent;
  final Color bgTop;
  final Color bgBottom;

  const _ThemeOption({
    required this.style,
    required this.name,
    required this.arabicMood,
    required this.arabicMoodEn,
    required this.accent,
    required this.bgTop,
    required this.bgBottom,
  });
}
