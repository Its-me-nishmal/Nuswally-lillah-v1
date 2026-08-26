import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../heartbeat_tap.dart';
import '../../screens/audio_quran_screen.dart';
import '../../screens/names_screen.dart';
import '../../screens/tasbeeh_screen.dart';

class QuickActionsDock extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;

  const QuickActionsDock({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final accentColor = themeProvider.primaryAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Audio Quran Player
          _buildActionItem(
            context: context,
            label: 'Audio',
            icon: Icons.headphones_rounded,
            accentColor: accentColor,
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AudioQuranScreen(),
                ),
              );
            },
          ),

          // 2. Tasbeeh Counter
          _buildActionItem(
            context: context,
            label: 'Tasbeeh',
            icon: Icons.fingerprint_rounded,
            accentColor: accentColor,
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TasbeehScreen()),
              );
            },
          ),

          // 3. Quran Directory Tab
          _buildActionItem(
            context: context,
            label: 'Quran',
            icon: Icons.menu_book_rounded,
            accentColor: accentColor,
            onTap: () {
              HapticFeedback.selectionClick();
              if (onNavigateTab != null) {
                onNavigateTab!(1);
              }
            },
          ),

          // 4. 99 Names of Allah
          _buildActionItem(
            context: context,
            label: '99 Names',
            icon: Icons.auto_awesome_rounded,
            accentColor: accentColor,
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NamesScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return HeartbeatTap(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modern Glass Squircle Icon Tile
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isDark
                    ? accentColor.withValues(alpha: 0.10)
                    : accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? accentColor.withValues(alpha: 0.22)
                      : accentColor.withValues(alpha: 0.30),
                  width: 1.0,
                ),
              ),
              child: Center(child: Icon(icon, size: 22, color: accentColor)),
            ),
            const SizedBox(height: 7),
            // Label
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: themeProvider.textPrimary,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
