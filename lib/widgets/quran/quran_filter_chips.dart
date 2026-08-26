import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/jira_theme.dart';
import '../heartbeat_tap.dart';

enum QuranFilterType { all, bookmarks, juz, meccan, medinan }

class QuranFilterChips extends StatelessWidget {
  final QuranFilterType activeFilter;
  final ValueChanged<QuranFilterType> onFilterSelected;
  final int totalCount;
  final int bookmarksCount;

  const QuranFilterChips({
    super.key,
    required this.activeFilter,
    required this.onFilterSelected,
    this.totalCount = 114,
    this.bookmarksCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final filters = [
      (QuranFilterType.all, 'All Surahs ($totalCount)'),
      (QuranFilterType.bookmarks, bookmarksCount > 0 ? 'Bookmarks ($bookmarksCount)' : 'Bookmarks'),
      (QuranFilterType.juz, 'Juz'),
      (QuranFilterType.meccan, 'Meccan'),
      (QuranFilterType.medinan, 'Medinan'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((item) {
          final type = item.$1;
          final label = item.$2;
          final isSelected = activeFilter == type;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: HeartbeatTap(
              onTap: () {
                HapticFeedback.selectionClick();
                onFilterSelected(type);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFA4C6FB)
                      : (isDark ? JiraTheme.darkSurface : JiraTheme.lightSurface),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFA4C6FB)
                        : (isDark ? JiraTheme.darkBorderSubtle : JiraTheme.lightBorderSubtle),
                    width: 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFA4C6FB).withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF0B0E14)
                          : themeProvider.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
