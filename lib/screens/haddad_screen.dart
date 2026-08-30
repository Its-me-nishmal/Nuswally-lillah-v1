import 'package:flutter/material.dart';
import 'moulid_reader_screen.dart';

/// Ratib al-Haddad Screen
/// Fully powered by the authentic, lossless decoded manuscript dataset (`assets/data/haddad_ratheeb.json`)
/// and the unified continuous reading engine with:
/// - Emerald & Gold design system tokens
/// - Two-finger pinch-to-zoom
/// - Collapsible frosted top bar
/// - Live progress bar & wide STOP button
/// - Poetic couplets & in-line chapter separators
class HaddadScreen extends StatelessWidget {
  const HaddadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MoulidReaderScreen(
      assetPath: 'assets/data/haddad_ratheeb.json.gz',
    );
  }
}
