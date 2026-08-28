import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../heartbeat_tap.dart';
import '../../theme/app_colors.dart';

enum QuranFilterType { all, juz, bookmarks, meccan, medinan }

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
    context.watchTheme();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final filters = [
      (QuranFilterType.all, 'Surah'),
      (QuranFilterType.juz, 'Juz'),
      (
        QuranFilterType.bookmarks,
        bookmarksCount > 0 ? 'Bookmarks ($bookmarksCount)' : 'Bookmarks',
      ),
      (QuranFilterType.meccan, 'Meccan'),
      (QuranFilterType.medinan, 'Medinan'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      child: Row(
        children: filters.map((item) {
          final type = item.$1;
          final label = item.$2;
          final isSelected = activeFilter == type;

          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: HeartbeatTap(
              onTap: () {
                HapticFeedback.selectionClick();
                onFilterSelected(type);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6.5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF1E2833) : context.cardBorder)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? themeProvider.primaryAccent.withValues(
                            alpha: isDark ? 0.35 : 0.45,
                          )
                        : Colors.transparent,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? themeProvider.primaryAccent
                        : themeProvider.textSecondary,
                    letterSpacing: 0.1,
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
