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

  const JiraScreen({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundBottom,
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
          // Subtle Islamic geometric overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.015,
              child: Image.asset(
                'assets/images/islamic_bg.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          SafeArea(child: child),
        ],
      ),
    );
  }
}
