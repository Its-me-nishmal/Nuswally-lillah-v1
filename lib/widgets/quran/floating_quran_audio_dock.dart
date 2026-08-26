import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/quran_model.dart';
import '../../providers/quran_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/jira_theme.dart';
import '../heartbeat_tap.dart';

class FloatingQuranAudioDock extends StatelessWidget {
  final Surah surah;
  final bool isCollapsed;
  final VoidCallback onExpand;

  const FloatingQuranAudioDock({
    super.key,
    required this.surah,
    this.isCollapsed = false,
    required this.onExpand,
  });

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    final minutes = duration.inMinutes.remainder(60).toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final quranProvider = context.watch<QuranProvider>();
    final isDark = themeProvider.isDarkMode;

    final isPlaying = quranProvider.playerState?.playing == true;
    final currentIndex = quranProvider.currentPlayingIndex ?? 0;
    final currentAyahNumber = quranProvider.ayahs.isNotEmpty && currentIndex < quranProvider.ayahs.length
        ? quranProvider.ayahs[currentIndex].numberInSurah
        : 1;

    final qariName = quranProvider.selectedQariObj.name;
    final shortQariName = qariName.split(' ').take(2).join(' ');

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.bottomRight,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            alignment: Alignment.bottomRight,
            child: child,
          ),
        );
      },
      child: isCollapsed
          ? _buildCollapsedMiniPlayer(
              key: const ValueKey('collapsed_player'),
              context: context,
              themeProvider: themeProvider,
              quranProvider: quranProvider,
              isDark: isDark,
              isPlaying: isPlaying,
              currentAyahNumber: currentAyahNumber,
            )
          : _buildExpandedDock(
              key: const ValueKey('expanded_dock'),
              context: context,
              themeProvider: themeProvider,
              quranProvider: quranProvider,
              isDark: isDark,
              isPlaying: isPlaying,
              currentIndex: currentIndex,
              currentAyahNumber: currentAyahNumber,
              shortQariName: shortQariName,
            ),
    );
  }

  // 1. Sleek Compact Bottom-Right Floating Player (Collapsed State)
  Widget _buildCollapsedMiniPlayer({
    required Key key,
    required BuildContext context,
    required ThemeProvider themeProvider,
    required QuranProvider quranProvider,
    required bool isDark,
    required bool isPlaying,
    required int currentAyahNumber,
  }) {
    return Align(
      key: key,
      alignment: Alignment.bottomRight,
      child: HeartbeatTap(
        onTap: () {
          HapticFeedback.selectionClick();
          onExpand();
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: (isDark ? JiraTheme.darkSurface : JiraTheme.lightSurface).withValues(alpha: 0.95),
            shape: BoxShape.circle,
            border: Border.all(
              color: isPlaying
                  ? JiraTheme.secondaryGreen.withValues(alpha: 0.6)
                  : (isDark ? JiraTheme.darkBorder : JiraTheme.lightBorder),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isPlaying
                    ? JiraTheme.secondaryGreen.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Circular Play/Pause indicator
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPlaying ? JiraTheme.secondaryGreen : (isDark ? JiraTheme.darkContainer : JiraTheme.lightContainer),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: isPlaying ? const Color(0xFF0B0E14) : themeProvider.textPrimary,
                    size: 22,
                  ),
                ),
              ),

              // Mini Verse Number Badge at top right of circle
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: JiraTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$currentAyahNumber',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Full Glassmorphic Dock (Expanded State)
  Widget _buildExpandedDock({
    required Key key,
    required BuildContext context,
    required ThemeProvider themeProvider,
    required QuranProvider quranProvider,
    required bool isDark,
    required bool isPlaying,
    required int currentIndex,
    required int currentAyahNumber,
    required String shortQariName,
  }) {
    return ClipRRect(
      key: key,
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: (isDark ? JiraTheme.darkSurface : JiraTheme.lightSurface).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: (isDark ? JiraTheme.darkBorderSubtle : JiraTheme.lightBorderSubtle),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row: Reciter Info + Audio Controls
              Row(
                children: [
                  // Left Reciter Avatar
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? JiraTheme.darkContainer : JiraTheme.lightContainer,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (isDark ? JiraTheme.darkBorderSubtle : JiraTheme.lightBorderSubtle),
                        width: 1.0,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.person_rounded,
                        size: 20,
                        color: themeProvider.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Middle Reciter Name & Verse Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          shortQariName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: themeProvider.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${surah.englishName} • Verse $currentAyahNumber',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                            color: themeProvider.textSecondary.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right Audio Controls: Previous, Play/Pause, Next
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Previous Ayah
                      HeartbeatTap(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          quranProvider.playPreviousAyah();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.skip_previous_rounded,
                            size: 22,
                            color: themeProvider.textPrimary.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Large Circular Play/Pause (Emerald Green)
                      HeartbeatTap(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          if (isPlaying) {
                            quranProvider.pauseAudio();
                          } else {
                            if (quranProvider.currentPlayingIndex == null) {
                              quranProvider.playAll();
                            } else {
                              quranProvider.togglePlayAyah(currentIndex);
                            }
                          }
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: JiraTheme.secondaryGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: JiraTheme.secondaryGreen.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: quranProvider.isAudioLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(0xFF0B0E14),
                                    ),
                                  )
                                : Icon(
                                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: const Color(0xFF0B0E14),
                                    size: 24,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Next Ayah
                      HeartbeatTap(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          if (currentIndex < quranProvider.ayahs.length - 1) {
                            quranProvider.selectAyah(currentIndex + 1);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.skip_next_rounded,
                            size: 22,
                            color: themeProvider.textPrimary.withValues(
                              alpha: currentIndex < quranProvider.ayahs.length - 1 ? 0.9 : 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Bottom Row: Timers + Live Scrubber + Speed Chip
              Row(
                children: [
                  Text(
                    _formatDuration(Duration(seconds: isPlaying ? 84 : 0)),
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.textSecondary.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Progress Scrubber Bar
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? JiraTheme.darkContainer : JiraTheme.lightContainer,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final totalAyahs = quranProvider.ayahs.length;
                          final progress = totalAyahs > 0 ? (currentIndex + 1) / totalAyahs : 0.0;
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFA4C6FB),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  Text(
                    _formatDuration(quranProvider.currentAudioDuration ?? const Duration(minutes: 3, seconds: 12)),
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.textSecondary.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Playback Speed Toggle Pill (1x / 1.5x / 2x)
                  HeartbeatTap(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final currentSpeed = quranProvider.playbackSpeed;
                      double nextSpeed = 1.0;
                      if (currentSpeed == 1.0) {
                        nextSpeed = 1.25;
                      } else if (currentSpeed == 1.25) {
                        nextSpeed = 1.5;
                      } else if (currentSpeed == 1.5) {
                        nextSpeed = 2.0;
                      } else {
                        nextSpeed = 1.0;
                      }
                      quranProvider.updatePlaybackSpeed(nextSpeed);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? JiraTheme.darkContainer : JiraTheme.lightContainer,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (isDark ? JiraTheme.darkBorder : JiraTheme.lightBorder).withValues(alpha: 0.7),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.speed_rounded,
                            size: 11,
                            color: themeProvider.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${quranProvider.playbackSpeed.toStringAsFixed(quranProvider.playbackSpeed == 1.0 || quranProvider.playbackSpeed == 2.0 ? 0 : 2)}x',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: themeProvider.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
