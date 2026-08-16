import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/quran_model.dart';
import '../providers/quran_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/jira_theme.dart';
import '../widgets/heartbeat_tap.dart';
import '../widgets/quran/reciter_picker_sheet.dart';

enum AudioPlayerViewMode { lyrics, disc }

class AudioQuranScreen extends StatefulWidget {
  final int? initialSurahNumber;

  const AudioQuranScreen({
    super.key,
    this.initialSurahNumber,
  });

  @override
  State<AudioQuranScreen> createState() => _AudioQuranScreenState();
}

class _AudioQuranScreenState extends State<AudioQuranScreen> with SingleTickerProviderStateMixin {
  final ScrollController _lyricsScrollController = ScrollController();
  final Map<int, GlobalKey> _ayahKeys = {};
  AudioPlayerViewMode _viewMode = AudioPlayerViewMode.lyrics;
  int? _lastScrolledIndex;
  Timer? _sleepTimer;
  int? _sleepTimerMinutes;
  late AnimationController _waveformController;

  @override
  void initState() {
    super.initState();
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    Future.microtask(() async {
      if (!mounted) return;
      final provider = context.read<QuranProvider>();
      if (provider.surahs.isEmpty) {
        await provider.fetchSurahs();
      }
      final targetSurah = widget.initialSurahNumber ?? provider.currentViewingSurahNumber ?? 1;
      if (provider.currentViewingSurahNumber != targetSurah || provider.ayahs.isEmpty) {
        await provider.fetchSurahDetails(targetSurah);
      }
      // If nothing is playing, start from beginning
      if (provider.playerState?.playing != true && provider.ayahs.isNotEmpty) {
        provider.togglePlayAyah(0);
      }
    });
  }

  @override
  void dispose() {
    _waveformController.dispose();
    _lyricsScrollController.dispose();
    _sleepTimer?.cancel();
    super.dispose();
  }

  void _scrollToCenterIndex(int index) {
    if (!_lyricsScrollController.hasClients) return;
    final key = _ayahKeys[index];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        alignment: 0.42, // Exactly in the focal center area of the screen
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _toArabicDigits(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((c) {
      final val = int.tryParse(c);
      return val != null ? arabicDigits[val] : c;
    }).join();
  }

  void _setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    setState(() {
      _sleepTimerMinutes = minutes;
    });
    if (minutes > 0) {
      _sleepTimer = Timer(Duration(minutes: minutes), () {
        if (mounted) {
          final provider = context.read<QuranProvider>();
          provider.pauseAudio();
          setState(() {
            _sleepTimerMinutes = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sleep timer ended. Audio paused.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

  void _showSleepTimerSheet(BuildContext context) {
    final tp = context.read<ThemeProvider>();
    final isDark = tp.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? JiraTheme.darkSurface : JiraTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: tp.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sleep Timer',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: tp.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [15, 30, 45, 60].map((mins) {
                  final isSelected = _sleepTimerMinutes == mins;
                  return HeartbeatTap(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _setSleepTimer(mins);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? JiraTheme.primaryBlue : (isDark ? JiraTheme.darkContainer : JiraTheme.lightContainer),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? JiraTheme.primaryBlue : tp.borderColor,
                        ),
                      ),
                      child: Text(
                        '🌙 $mins Minutes',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : tp.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_sleepTimerMinutes != null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    _setSleepTimer(0);
                    Navigator.pop(context);
                  },
                  child: const Text('Turn Off Sleep Timer', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showSurahPlaylistDrawer(BuildContext context, QuranProvider provider) {
    final tp = context.read<ThemeProvider>();
    final isDark = tp.isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? JiraTheme.darkSurface : JiraTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.92,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tp.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quran Surahs (114)',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: tp.textPrimary,
                        ),
                      ),
                      Text(
                        '${provider.surahs.length} Chapters',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: tp.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: provider.surahs.length,
                    itemBuilder: (context, index) {
                      final surah = provider.surahs[index];
                      final isCurrent = provider.currentViewingSurahNumber == surah.number;

                      return ListTile(
                        onTap: () async {
                          HapticFeedback.selectionClick();
                          Navigator.pop(context);
                          await provider.fetchSurahDetails(surah.number);
                          provider.togglePlayAyah(0);
                        },
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isCurrent ? JiraTheme.primaryBlue : (isDark ? JiraTheme.darkContainer : JiraTheme.lightContainer),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              surah.number.toString().padLeft(2, '0'),
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isCurrent ? Colors.white : tp.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          surah.englishName,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                            color: isCurrent ? JiraTheme.primaryBlue : tp.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '${surah.revelationType} • ${surah.numberOfAyahs} Verses',
                          style: GoogleFonts.inter(fontSize: 11, color: tp.textSecondary),
                        ),
                        trailing: Text(
                          surah.name,
                          style: TextStyle(
                            fontFamily: 'HafsFont',
                            fontSize: 18,
                            color: isCurrent ? JiraTheme.primaryBlue : tp.textPrimary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showQariPickerSheet(BuildContext context, QuranProvider provider) {
    ReciterPickerSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final quranProvider = context.watch<QuranProvider>();

    final isPlaying = quranProvider.playerState?.playing == true;
    final currentAyahIndex = quranProvider.currentPlayingIndex ?? 0;
    final currentSurahNumber = quranProvider.currentViewingSurahNumber ?? 1;

    final currentSurah = quranProvider.surahs.firstWhere(
      (s) => s.number == currentSurahNumber,
      orElse: () => Surah(
        number: 55,
        name: 'سُورَةُ الرَّحْمَٰنِ',
        englishName: 'Ar-Rahman',
        englishNameTranslation: 'The Beneficent',
        numberOfAyahs: 78,
        revelationType: 'MECCAN',
      ),
    );

    final qariFullName = quranProvider.selectedQariObj.name;
    final qariShortName = qariFullName.split(' ').take(2).join(' ');

    // Auto-scroll lyrics stream smoothly to center when active verse changes
    if (quranProvider.currentPlayingIndex != null && quranProvider.currentPlayingIndex != _lastScrolledIndex) {
      _lastScrolledIndex = quranProvider.currentPlayingIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCenterIndex(quranProvider.currentPlayingIndex!);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: Stack(
        children: [
          // 1. Ambient Background Glow Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0B0E14),
                  Color(0xFF0D121D),
                  Color(0xFF070A10),
                ],
              ),
            ),
          ),

          // 2. Central Soft Ambient Radial Aura
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: -50,
            right: -50,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0C66E4).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 3. Main Screen Flow
          SafeArea(
            child: Column(
              children: [
                // Top Floating Navigation Bar
                _buildTopBar(
                  context: context,
                  surah: currentSurah,
                  qariShortName: qariShortName,
                  quranProvider: quranProvider,
                ),

                // Center Stage: Live Synced Lyrics Stream or Disc
                Expanded(
                  child: _viewMode == AudioPlayerViewMode.lyrics
                      ? _buildLiveSyncedLyricsStream(
                          context: context,
                          quranProvider: quranProvider,
                          currentPlayingIndex: currentAyahIndex,
                        )
                      : _buildCelestialDiscView(
                          context: context,
                          surah: currentSurah,
                          isPlaying: isPlaying,
                        ),
                ),

                // Bottom Floating Glassmorphic Playback Console
                _buildBottomPlaybackConsole(
                  context: context,
                  quranProvider: quranProvider,
                  isPlaying: isPlaying,
                  currentAyahIndex: currentAyahIndex,
                  surah: currentSurah,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Top Bar with Minimize Down-Chevron, Surah Header, and Mode Switcher
  Widget _buildTopBar({
    required BuildContext context,
    required Surah surah,
    required String qariShortName,
    required QuranProvider quranProvider,
  }) {
    final arabicTitle = surah.name.replaceAll('سُورَةُ ', '');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Minimize Down-Chevron Button
          HeartbeatTap(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF161B22).withValues(alpha: 0.85),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF30363D).withValues(alpha: 0.7),
                  width: 1.0,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 26,
                  color: Color(0xFFF0F6FC),
                ),
              ),
            ),
          ),

          // Center Surah Title & Reciter Capsule
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'SURAH ${surah.englishName.toUpperCase()} • ',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFF0F6FC),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'سُورَةُ $arabicTitle',
                      style: const TextStyle(
                        fontFamily: 'HafsFont',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC7D2FE),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Reciter Capsule Chip (Clickable to switch)
                HeartbeatTap(
                  onTap: () => _showQariPickerSheet(context, quranProvider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F242C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF30363D).withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          qariShortName,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8B949E),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 13,
                          color: Color(0xFF8B949E),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right Two-Mode Toggle Capsule ([💬 Lyrics] / [💿 Disc])
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF30363D),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lyrics Icon Button
                HeartbeatTap(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _viewMode = AudioPlayerViewMode.lyrics);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _viewMode == AudioPlayerViewMode.lyrics ? const Color(0xFF1F2A38) : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 16,
                        color: _viewMode == AudioPlayerViewMode.lyrics ? const Color(0xFFA4C6FB) : const Color(0xFF8B949E),
                      ),
                    ),
                  ),
                ),

                // Disc Artwork Button
                HeartbeatTap(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _viewMode = AudioPlayerViewMode.disc);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _viewMode == AudioPlayerViewMode.disc ? const Color(0xFF1F2A38) : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.album_outlined,
                        size: 17,
                        color: _viewMode == AudioPlayerViewMode.disc ? const Color(0xFFA4C6FB) : const Color(0xFF8B949E),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. Live Synced Lyrics Stream (Apple Music / Spotify Style Karaoke Flow)
  Widget _buildLiveSyncedLyricsStream({
    required BuildContext context,
    required QuranProvider quranProvider,
    required int currentPlayingIndex,
  }) {
    if (quranProvider.isLoadingAyahs) {
      return const Center(
        child: CircularProgressIndicator(color: JiraTheme.primaryBlue),
      );
    }

    if (quranProvider.ayahs.isEmpty) {
      return Center(
        child: Text(
          'No verses loaded',
          style: GoogleFonts.outfit(color: const Color(0xFF8B949E)),
        ),
      );
    }

    return ListView.builder(
      controller: _lyricsScrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      itemCount: quranProvider.ayahs.length,
      itemBuilder: (context, index) {
        final ayah = quranProvider.ayahs[index];
        final isActive = currentPlayingIndex == index;
        final arabicNumeral = _toArabicDigits(ayah.numberInSurah);

        return Container(
          key: _ayahKeys.putIfAbsent(index, () => GlobalKey()),
          margin: EdgeInsets.symmetric(vertical: isActive ? 22 : 12),
          child: HeartbeatTap(
            onTap: () {
              HapticFeedback.selectionClick();
              quranProvider.togglePlayAyah(index);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Arabic Calligraphy Line + Verse Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Verse Number Badge (Left in row)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? const Color(0xFF1E293B) : Colors.transparent,
                        border: Border.all(
                          color: isActive ? const Color(0xFF38BDF8).withValues(alpha: 0.6) : const Color(0xFF334155).withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          arabicNumeral,
                          style: TextStyle(
                            fontFamily: 'HafsFont',
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: isActive ? const Color(0xFF93C5FD) : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Arabic Sacred Verse Calligraphy (Un-bolded, Clean Hafs Flow)
                    Flexible(
                      child: Text(
                        ayah.text,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'HafsFont',
                          fontSize: isActive ? 26 : 20,
                          fontWeight: FontWeight.normal, // Clean regular weight, no bold
                          height: 1.9,
                          color: isActive ? Colors.white : const Color(0xFF64748B).withValues(alpha: 0.4),
                          shadows: isActive
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                                    blurRadius: 18,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // English / Translation Lyrics Subtitle Line
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isActive ? 1.0 : 0.28,
                  child: Text(
                    'Verse ${ayah.numberInSurah}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: isActive ? 14 : 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? const Color(0xFFE2E8F0) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 2. Celestial Sacred Geometry Disc View (Vinyl / Artwork Mode)
  // Outer vinyl disc rotates, while the inner center label with Surah name stays stationary!
  Widget _buildCelestialDiscView({
    required BuildContext context,
    required Surah surah,
    required bool isPlaying,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer Rotating Vinyl Disc & Grooves
              AnimatedBuilder(
                animation: _waveformController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: isPlaying ? _waveformController.value * 2 * math.pi : 0.0,
                    child: Container(
                      width: 230,
                      height: 230,
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF30363D),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: JiraTheme.secondaryGreen.withValues(alpha: isPlaying ? 0.25 : 0.08),
                            blurRadius: 36,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Concentric vinyl groove rings
                          Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF30363D).withValues(alpha: 0.5),
                                width: 1.0,
                              ),
                            ),
                          ),
                          Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF30363D).withValues(alpha: 0.3),
                                width: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Inner Stationary Surah Name Label (DOES NOT ROTATE - Stays perfectly upright)
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0E14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF30363D).withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    surah.name.replaceAll('سُورَةُ ', ''),
                    style: const TextStyle(
                      fontFamily: 'HafsFont',
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFFC7D2FE),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            surah.englishName,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${surah.revelationType} • ${surah.numberOfAyahs} VERSES',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8B949E),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // 3. Floating Glassmorphic Playback Console (Waveform + Hero Button + Toolbar)
  Widget _buildBottomPlaybackConsole({
    required BuildContext context,
    required QuranProvider quranProvider,
    required bool isPlaying,
    required int currentAyahIndex,
    required Surah surah,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFF30363D).withValues(alpha: 0.85),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Timestamps + Pulsating Audio Waveform Bars
                StreamBuilder<Duration>(
                  stream: quranProvider.audioPlayer.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final total = quranProvider.currentAudioDuration ?? const Duration(minutes: 3, seconds: 12);
                    final remaining = total - position;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Elapsed Time
                        Text(
                          _formatDuration(position),
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8B949E),
                          ),
                        ),

                        // Center Pulsating Waveform Equalizer
                        _buildWaveformEqualizer(isPlaying),

                        // Remaining Time
                        Text(
                          '-${_formatDuration(remaining > Duration.zero ? remaining : Duration.zero)}',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8B949E),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Main Controls Row (Repeat, Replay 10s, Hero Play/Pause, Forward 10s, Playlist)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Repeat Ayah Mode
                    HeartbeatTap(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        final currentLoop = quranProvider.hifzLoopCount;
                        final next = currentLoop == 1 ? 3 : (currentLoop == 3 ? 5 : 1);
                        quranProvider.updateHifzSettings(next, quranProvider.hifzDelaySeconds);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          quranProvider.hifzLoopCount > 1 ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                          size: 22,
                          color: quranProvider.hifzLoopCount > 1 ? JiraTheme.secondaryGreen : const Color(0xFF8B949E),
                        ),
                      ),
                    ),

                    // Replay 10s Button
                    HeartbeatTap(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        quranProvider.seekBackward10();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.replay_10_rounded,
                          size: 26,
                          color: Color(0xFFF0F6FC),
                        ),
                      ),
                    ),

                    // Center Hero Emerald Play/Pause Button
                    HeartbeatTap(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        if (isPlaying) {
                          quranProvider.pauseAudio();
                        } else {
                          quranProvider.togglePlayAyah(currentAyahIndex);
                        }
                      },
                      child: Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          color: JiraTheme.secondaryGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: JiraTheme.secondaryGreen.withValues(alpha: 0.45),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 36,
                            color: const Color(0xFF0B0E14),
                          ),
                        ),
                      ),
                    ),

                    // Forward 10s Button
                    HeartbeatTap(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        quranProvider.seekForward10();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.forward_10_rounded,
                          size: 26,
                          color: Color(0xFFF0F6FC),
                        ),
                      ),
                    ),

                    // Playlist / Queue Drawer
                    HeartbeatTap(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _showSurahPlaylistDrawer(context, quranProvider);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.queue_music_rounded,
                          size: 24,
                          color: Color(0xFF8B949E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Bottom Micro-Utility Toolbar (Speed Pill, Sleep Timer, Output Cast)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Playback Speed Pill
                    HeartbeatTap(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        final currentSpeed = quranProvider.playbackSpeed;
                        double next = 1.0;
                        if (currentSpeed == 1.0) {
                          next = 1.25;
                        } else if (currentSpeed == 1.25) {
                          next = 1.5;
                        } else if (currentSpeed == 1.5) {
                          next = 2.0;
                        }
                        quranProvider.updatePlaybackSpeed(next);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F242C),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF30363D).withValues(alpha: 0.7),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          '${quranProvider.playbackSpeed.toStringAsFixed(quranProvider.playbackSpeed == 1.0 || quranProvider.playbackSpeed == 2.0 ? 0 : 2)}x',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF0F6FC),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Sleep Timer Pill
                    HeartbeatTap(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _showSleepTimerSheet(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F242C),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _sleepTimerMinutes != null ? JiraTheme.primaryBlue : const Color(0xFF30363D).withValues(alpha: 0.7),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🌙', style: TextStyle(fontSize: 11)),
                            const SizedBox(width: 4),
                            Text(
                              _sleepTimerMinutes != null ? '${_sleepTimerMinutes}m' : '30m',
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: _sleepTimerMinutes != null ? JiraTheme.primaryBlue : const Color(0xFFF0F6FC),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // AirPlay / Cast Output Icon
                    HeartbeatTap(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Audio routed to device speaker / Bluetooth output.'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: const Icon(
                          Icons.airplay_rounded,
                          size: 18,
                          color: Color(0xFF8B949E),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Pulsating Audio Equalizer Waveform Bars
  Widget _buildWaveformEqualizer(bool isPlaying) {
    const barHeights = [10.0, 16.0, 22.0, 14.0, 26.0, 18.0, 12.0, 8.0];

    return AnimatedBuilder(
      animation: _waveformController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(barHeights.length, (i) {
            final base = barHeights[i];
            final factor = isPlaying ? math.sin((_waveformController.value * math.pi * 2) + (i * 0.6)).abs() : 0.3;
            final height = (base * (0.4 + factor * 0.6)).clamp(4.0, 28.0);
            final isCenter = i == 3 || i == 4;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: 3.5,
              height: height,
              decoration: BoxDecoration(
                color: isCenter ? Colors.white : (isPlaying ? const Color(0xFF93C5FD) : const Color(0xFF475569)),
                borderRadius: BorderRadius.circular(3),
                boxShadow: isCenter && isPlaying
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        );
      },
    );
  }
}
