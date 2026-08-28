import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/home_design.dart';
import '../heartbeat_tap.dart';

/// Full-width bottom navigation, attached to the bottom edge (not floating).
/// Restyled with the gold hairline language and an active indicator dot.
class ObsidianBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const ObsidianBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  static const List<_NavItemData> _items = [
    _NavItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItemData(
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book_rounded,
      label: 'Quran',
    ),
    _NavItemData(
      icon: Icons.bookmark_border_rounded,
      activeIcon: Icons.bookmark_rounded,
      label: 'Library',
    ),
    _NavItemData(
      icon: Icons.play_circle_outline,
      activeIcon: Icons.play_circle_fill,
      label: 'Media',
    ),
    _NavItemData(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'More',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // Labels sit in a fixed-height bar; cap growth so they cannot clip.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: 9,
              bottom: bottomInset > 0 ? bottomInset + 4 : 10,
            ),
            decoration: BoxDecoration(
              color: HomeDesign.navFill(
                isDark,
              ).withValues(alpha: isDark ? 0.94 : 0.96),
              border: Border(
                top: BorderSide(color: HomeDesign.goldLine(isDark), width: 1.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: HomeDesign.shadow(isDark),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: List.generate(_items.length, (index) {
                final item = _items[index];
                final isActive = currentIndex == index;
                final activeColor = themeProvider.accentText;
                final inactiveColor = themeProvider.textSecondary;

                return Expanded(
                  child: Semantics(
                    button: true,
                    selected: isActive,
                    label: item.label,
                    child: HeartbeatTap(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onTabSelected(index);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        color: Colors.transparent,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedScale(
                              duration: const Duration(milliseconds: 200),
                              scale: isActive ? 1.08 : 1.0,
                              curve: Curves.easeOutBack,
                              child: Icon(
                                isActive ? item.activeIcon : item.icon,
                                size: 23,
                                color: isActive ? activeColor : inactiveColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isActive ? activeColor : inactiveColor,
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Active indicator dot.
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isActive ? 5 : 0,
                              height: isActive ? 5 : 0,
                              decoration: BoxDecoration(
                                color: themeProvider.primaryAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
