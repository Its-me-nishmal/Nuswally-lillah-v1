import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'heartbeat_tap.dart';
import '../theme/app_colors.dart';

class TelegramThemeToggle extends StatefulWidget {
  const TelegramThemeToggle({super.key});

  @override
  State<TelegramThemeToggle> createState() => _TelegramThemeToggleState();
}

class _TelegramThemeToggleState extends State<TelegramThemeToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(ThemeProvider provider) {
    if (_controller.isAnimating) return;
    if (provider.isDarkMode) {
      _controller.forward(from: 0);
    } else {
      _controller.reverse(from: math.pi);
    }
    provider.toggleDarkMode();
  }

  @override
  Widget build(BuildContext context) {
    context.watchTheme();
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return HeartbeatTap(
      onTap: () => _handleTap(themeProvider),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: context.cardTop,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.cardBorder, width: 1.0),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value,
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
                  size: 18,
                  color: isDark ? context.gold : context.accent,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
