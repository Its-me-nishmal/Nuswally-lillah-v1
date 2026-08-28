import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/home_design.dart';
import '../heartbeat_tap.dart';
import 'home_glyphs.dart';
import '../../screens/audio_quran_screen.dart';
import '../../screens/names_screen.dart';
import '../../screens/tasbeeh_screen.dart';

/// Five titled shortcut cards under the hero. Scrolls horizontally so the
/// labels never have to shrink on narrow phones.
class QuickActionsDock extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;

  const QuickActionsDock({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final accent = themeProvider.primaryAccent;

    final actions = <_QuickAction>[
      _QuickAction(
        label: 'Audio',
        caption: 'Listen & Reflect',
        tint: accent,
        icon: Icons.headphones_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AudioQuranScreen()),
        ),
      ),
      _QuickAction(
        label: 'Tasbeeh',
        caption: 'Dhikr & Count',
        tint: HomeDesign.gold,
        glyphBuilder: (size, color) => TasbeehGlyph(size: size, color: color),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TasbeehScreen()),
        ),
      ),
      _QuickAction(
        label: 'Quran',
        caption: 'Read & Learn',
        tint: accent,
        icon: Icons.menu_book_rounded,
        onTap: () => onNavigateTab?.call(1),
      ),
      _QuickAction(
        label: '99 Names',
        caption: 'Asma-ul-Husna',
        tint: HomeDesign.gold,
        glyphBuilder: (size, color) =>
            NinetyNineGlyph(size: size, color: color),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NamesScreen()),
        ),
      ),
      _QuickAction(
        label: 'Dua & Adhkaar',
        caption: 'Awraad & Supplications',
        tint: accent,
        icon: Icons.volunteer_activism_rounded,
        onTap: () => onNavigateTab?.call(2),
      ),
    ];

    // The cards are a fixed height, so cap how far the labels can grow.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SizedBox(
        height: 108,
        // Fade the right edge so it reads as "more to scroll".
        child: ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: [0.0, 0.86, 1.0],
            colors: [Colors.white, Colors.white, Colors.transparent],
          ).createShader(rect),
          blendMode: BlendMode.dstIn,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            clipBehavior: Clip.none,
            itemCount: actions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) =>
                _QuickActionCard(action: actions[index]),
          ),
        ),
      ),
    );
  }
}

typedef _GlyphBuilder = Widget Function(double size, Color color);

class _QuickAction {
  final String label;
  final String caption;
  final Color tint;
  final IconData? icon;
  final _GlyphBuilder? glyphBuilder;
  final VoidCallback onTap;

  _QuickAction({
    required this.label,
    required this.caption,
    required this.tint,
    required this.onTap,
    this.icon,
    this.glyphBuilder,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _QuickAction action;

  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return HeartbeatTap(
      onTap: () {
        HapticFeedback.selectionClick();
        action.onTap();
      },
      child: Container(
        width: 116,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          gradient: HomeDesign.cardGradient(isDark),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: HomeDesign.goldLine(isDark), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: HomeDesign.shadow(isDark),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: action.tint.withValues(alpha: isDark ? 0.13 : 0.11),
                border: Border.all(
                  color: action.tint.withValues(alpha: isDark ? 0.26 : 0.30),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: action.glyphBuilder != null
                    ? action.glyphBuilder!(22, action.tint)
                    : Icon(action.icon, size: 21, color: action.tint),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              action.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: themeProvider.textPrimary,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              action.caption,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: themeProvider.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
