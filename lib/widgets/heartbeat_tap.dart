import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared micro-interaction widget matching the Home screen's `_HeartbeatTap`.
///
/// Wraps any tappable widget with a 160ms heartbeat scale pulse
/// (1.0 -> 0.93 -> 1.04 -> 1.0) and a subtle `selectionClick` haptic.
class HeartbeatTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const HeartbeatTap({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<HeartbeatTap> createState() => _HeartbeatTapState();
}

class _HeartbeatTapState extends State<HeartbeatTap> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.93), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 0.93, end: 1.04), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.04, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    _controller.forward(from: 0.0);
    widget.onTap();
  }

  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onLongPress: widget.onLongPress == null ? null : _handleLongPress,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
