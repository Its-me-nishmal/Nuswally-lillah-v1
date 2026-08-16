import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF161B22).withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF30363D).withValues(alpha: 0.8)
                  : const Color(0xFFD0D7DE),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / _items.length;
              final isWithinTabs = currentIndex >= 0 && currentIndex < _items.length;

              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // 1. Smooth Sliding Glowing Active Pill
                  if (isWithinTabs)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      left: currentIndex * tabWidth + (tabWidth - 44) / 2,
                      top: (constraints.maxHeight - 44) / 2,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: JiraTheme.secondaryGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: JiraTheme.secondaryGreen.withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 2. Interactive Navigation Icons
                  Row(
                    children: List.generate(_items.length, (index) {
                      final item = _items[index];
                      final isActive = currentIndex == index;

                      return Expanded(
                        child: HeartbeatTap(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onTabSelected(index);
                          },
                          child: Container(
                            height: 48,
                            color: Colors.transparent,
                            child: Center(
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 200),
                                scale: isActive ? 1.08 : 1.0,
                                curve: Curves.easeOutBack,
                                child: Icon(
                                  isActive ? item.activeIcon : item.icon,
                                  size: 22,
                                  color: isActive
                                      ? const Color(0xFF0B0E14)
                                      : (isDark ? const Color(0xFF8B949E) : const Color(0xFF626F86)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
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
