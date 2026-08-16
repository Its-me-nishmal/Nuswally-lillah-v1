import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/jira_theme.dart';
import '../heartbeat_tap.dart';
import '../../screens/audio_quran_screen.dart';
import '../../screens/names_screen.dart';
import '../../screens/tasbeeh_screen.dart';

class QuickActionsDock extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;

  const QuickActionsDock({
    super.key,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final surfaceColor = isDark ? JiraTheme.darkSurface : JiraTheme.lightSurface;
    final containerColor = isDark ? JiraTheme.darkContainer : JiraTheme.lightContainer;
    final borderColor = isDark ? JiraTheme.darkBorder : JiraTheme.lightBorder;

    return Row(
      children: [
        // 1. Audio Quran Player
        Expanded(
          child: _buildTile(
            context: context,
            label: 'Audio',
            icon: Icons.headphones_rounded,
            iconColor: const Color(0xFF38BDF8),
            surfaceColor: surfaceColor,
            containerColor: containerColor,
            borderColor: borderColor,
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AudioQuranScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 10),

        // 2. Tasbeeh
        Expanded(
          child: _buildTile(
            context: context,
            label: 'Tasbeeh',
            icon: Icons.fingerprint_rounded,
            iconColor: JiraTheme.secondaryGreen,
            surfaceColor: surfaceColor,
            containerColor: containerColor,
            borderColor: borderColor,
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TasbeehScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 10),

        // 3. Quran
        Expanded(
          child: _buildTile(
            context: context,
            label: 'Quran',
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFF818CF8),
            surfaceColor: surfaceColor,
            containerColor: containerColor,
            borderColor: borderColor,
            onTap: () {
              HapticFeedback.selectionClick();
              if (onNavigateTab != null) {
                onNavigateTab!(1);
              }
            },
          ),
        ),
        const SizedBox(width: 10),

        // 4. 99 Names of Allah
        Expanded(
          child: _buildTile(
            context: context,
            label: '99 Names',
            icon: Icons.auto_awesome_rounded,
            iconColor: const Color(0xFFFBBF24),
            surfaceColor: surfaceColor,
            containerColor: containerColor,
            borderColor: borderColor,
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NamesScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTile({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color surfaceColor,
    required Color containerColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return HeartbeatTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor.withValues(alpha: isDark ? 0.6 : 0.9),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: containerColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor.withValues(alpha: 0.5),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 19,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
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
