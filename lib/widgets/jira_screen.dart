import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Shared full-screen scaffold matching the Home screen background.
///
/// Applies the theme gradient, the ultra-subtle (`0.015`) Islamic geometric
/// overlay, and a [SafeArea] so pushed screens look identical to the Home
/// tab surfaces. Content is exposed via the [child] slot.
class JiraScreen extends StatelessWidget {
  final Widget child;
  final bool safeAreaTop;
  final bool safeAreaBottom;
  final bool safeAreaLeft;
  final bool safeAreaRight;
  final bool extendBody;
  final Widget? bottomNavigationBar;

  const JiraScreen({
    super.key,
    required this.child,
    this.safeAreaTop = true,
    this.safeAreaBottom = true,
    this.safeAreaLeft = true,
    this.safeAreaRight = true,
    this.extendBody = false,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundBottom,
      extendBody: extendBody,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  themeProvider.backgroundTop,
                  themeProvider.backgroundBottom,
                ],
              ),
            ),
          ),
          // Islamic geometric overlay - clearly visible elegant watermark
          Positioned.fill(
            child: Opacity(
              opacity: 0.035,
              child: Image.asset(
                'assets/images/islamic_bg.webp',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          SafeArea(
            top: safeAreaTop,
            bottom: safeAreaBottom,
            left: safeAreaLeft,
            right: safeAreaRight,
            child: child,
          ),
        ],
      ),
    );
  }
}
