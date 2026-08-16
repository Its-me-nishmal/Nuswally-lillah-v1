import 'package:flutter/material.dart';

class AdhkaarLangBadge extends StatelessWidget {
  final double size;
  final bool filled;

  const AdhkaarLangBadge({
    super.key,
    this.size = 20.0,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? Colors.white.withValues(alpha: 0.25) : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: filled ? Colors.white : Theme.of(context).primaryColor,
          width: 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        'م',
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: size * 0.55,
          fontWeight: FontWeight.bold,
          color: filled ? Colors.white : Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
