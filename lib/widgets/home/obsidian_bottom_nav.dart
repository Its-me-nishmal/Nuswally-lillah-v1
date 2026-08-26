import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/jira_theme.dart';
import '../heartbeat_tap.dart';

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
      icon: Icons.collections_bookmark_outlined,
      activeIcon: Icons.collections_bookmark_rounded,
      label: 'Library',
    ),
    _NavItemData(
      icon: Icons.play_circle_outline,
      activeIcon: Icons.play_circle_fill,
      label: 'Media',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final surfaceColor = (isDark ? JiraTheme.darkSurface : JiraTheme.lightSurface)
        .withValues(alpha: 0.90);
    final borderColor = isDark ? JiraTheme.darkBorderSubtle : JiraTheme.lightBorderSubtle;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: 8,
            bottom: bottomInset > 0 ? bottomInset : 8,
          ),
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(
              top: BorderSide(
                color: borderColor,
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isActive = currentIndex == index;
              final activeColor = JiraTheme.primaryBlue;
              final inactiveColor = isDark
                  ? const Color(0xFF8B949E)
                  : const Color(0xFF64748B);

              return Expanded(
                child: HeartbeatTap(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTabSelected(index);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon with subtle scale animation
                        AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          scale: isActive ? 1.08 : 1.0,
                          curve: Curves.easeOutBack,
                          child: Icon(
                            isActive ? item.activeIcon : item.icon,
                            size: 22,
                            color: isActive ? activeColor : inactiveColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Label
                        Text(
                          item.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                            color: isActive ? activeColor : inactiveColor,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],
                    ),
                  ),
                ),
              );
            }),
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
