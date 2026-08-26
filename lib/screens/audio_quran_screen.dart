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
        alignment: 0.42,
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
          context.read<QuranProvider>().pauseAudio();
          setState(() {
            _sleepTimerMinutes = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sleep timer ended • Audio stopped'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sleep timer set for $minutes minutes'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showSleepTimerPicker(BuildContext context, ThemeProvider tp) {
    final durations = [15, 30, 45, 60, 0];

    showModalBottomSheet(
      context: context,
      backgroundColor: tp.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Icon(Icons.bedtime_outlined, color: tp.primaryAccent, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Sleep Timer',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: tp.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              ...durations.map((mins) {
                final isSelected = mins == _sleepTimerMinutes || (mins == 0 && _sleepTimerMinutes == null);
                final label = mins == 0 ? 'Turn Off Timer' : '$mins Minutes';

                return ListTile(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                    _setSleepTimer(mins);
                  },
                  leading: Icon(
                    mins == 0 ? Icons.timer_off_outlined : Icons.timer_outlined,
                    color: isSelected ? tp.primaryAccent : tp.textSecondary,
                  ),
                  title: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? tp.primaryAccent : tp.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_rounded, color: tp.primaryAccent)
                      : null,
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showSurahPlaylistDrawer(BuildContext context, QuranProvider provider, ThemeProvider tp) {
    final isDark = tp.isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: tp.surfaceColor,
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
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
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
                Divider(height: 1, color: tp.borderColor),
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
                            color: isCurrent
                                ? tp.primaryAccent.withValues(alpha: isDark ? 0.15 : 0.12)
                                : tp.containerColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCurrent ? tp.primaryAccent : tp.borderColor,
                              width: 0.8,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              surah.number.toString().padLeft(2, '0'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isCurrent ? tp.primaryAccent : tp.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          surah.englishName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                            color: isCurrent ? tp.primaryAccent : tp.textPrimary,
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
                            fontSize: 17,
                            color: isCurrent ? tp.primaryAccent : tp.textPrimary,
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

  void _showQariPickerSheet(BuildContext context) {
    ReciterPickerSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final isDark = tp.isDarkMode;
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

    if (quranProvider.currentPlayingIndex != null && quranProvider.currentPlayingIndex != _lastScrolledIndex) {
      _lastScrolledIndex = quranProvider.currentPlayingIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCenterIndex(quranProvider.currentPlayingIndex!);
      });
    }

    return Scaffold(
      backgroundColor: tp.backgroundTop,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [tp.backgroundTop, tp.backgroundBottom],
                ),
              ),
            ),
          ),

          // Central Soft Ambient Teal Radial Glow
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
                    tp.primaryAccent.withValues(alpha: isDark ? 0.12 : 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Screen Flow
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(
                  context: context,
                  surah: currentSurah,
                  qariShortName: qariShortName,
                  quranProvider: quranProvider,
                  tp: tp,
                  isDark: isDark,
                ),

                // Center Stage: Synced Lyrics Stream or Disc
                Expanded(
                  child: _viewMode == AudioPlayerViewMode.lyrics
                      ? _buildLiveSyncedLyricsStream(
                          context: context,
                          quranProvider: quranProvider,
                          currentPlayingIndex: currentAyahIndex,
                          tp: tp,
                          isDark: isDark,
                        )
                      : _buildCelestialDiscView(
                          context: context,
                          surah: currentSurah,
                          isPlaying: isPlaying,
                          tp: tp,
                          isDark: isDark,
                        ),
                ),

                // Bottom Playback Console
                _buildBottomPlaybackConsole(
                  context: context,
                  quranProvider: quranProvider,
                  isPlaying: isPlaying,
                  currentAyahIndex: currentAyahIndex,
                  surah: currentSurah,
                  tp: tp,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar({
    required BuildContext context,
    required Surah surah,
    required String qariShortName,
    required QuranProvider quranProvider,
    required ThemeProvider tp,
    required bool isDark,
  }) {
    final arabicTitle = surah.name.replaceAll('سُورَةُ ', '');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Minimize Button
          HeartbeatTap(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tp.surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(color: tp.borderColor, width: 0.8),
              ),
              child: Center(
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 24,
                  color: tp.textPrimary,
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
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: tp.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'سُورَةُ $arabicTitle',
                      style: TextStyle(
                        fontFamily: 'HafsFont',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFE2E8F0) : tp.primaryAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),

                // Reciter Capsule Chip
                HeartbeatTap(
                  onTap: () => _showQariPickerSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF151D24) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: tp.borderColor,
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
                            color: tp.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 13,
                          color: tp.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Two-Mode Toggle Capsule ([💬 Lyrics] / [💿 Disc])
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: tp.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tp.borderColor, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HeartbeatTap(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _viewMode = AudioPlayerViewMode.lyrics);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _viewMode == AudioPlayerViewMode.lyrics
                          ? tp.primaryAccent.withValues(alpha: isDark ? 0.15 : 0.12)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 15,
                        color: _viewMode == AudioPlayerViewMode.lyrics ? tp.primaryAccent : tp.textSecondary,
                      ),
                    ),
                  ),
                ),
                HeartbeatTap(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _viewMode = AudioPlayerViewMode.disc);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _viewMode == AudioPlayerViewMode.disc
                          ? tp.primaryAccent.withValues(alpha: isDark ? 0.15 : 0.12)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.album_outlined,
                        size: 16,
                        color: _viewMode == AudioPlayerViewMode.disc ? tp.primaryAccent : tp.textSecondary,
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

  Widget _buildLiveSyncedLyricsStream({
    required BuildContext context,
    required QuranProvider quranProvider,
    required int currentPlayingIndex,
    required ThemeProvider tp,
    required bool isDark,
  }) {
    if (quranProvider.isLoadingAyahs) {
      return Center(
        child: CircularProgressIndicator(color: tp.primaryAccent),
      );
    }

    if (quranProvider.ayahs.isEmpty) {
      return Center(
        child: Text(
          'No verses loaded',
          style: GoogleFonts.plusJakartaSans(color: tp.textSecondary),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? tp.primaryAccent.withValues(alpha: isDark ? 0.15 : 0.12) : Colors.transparent,
                        border: Border.all(
                          color: isActive ? tp.primaryAccent : tp.borderColor.withValues(alpha: 0.5),
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
                            color: isActive ? tp.primaryAccent : tp.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    Flexible(
                      child: Text(
                        ayah.text,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'HafsFont',
                          fontSize: isActive ? 26 : 20,
                          fontWeight: FontWeight.normal,
                          height: 1.9,
                          color: isActive
                              ? (isDark ? const Color(0xFFF0F6FC) : const Color(0xFF0F172A))
                              : tp.textSecondary.withValues(alpha: 0.45),
                          shadows: isActive
                              ? [
                                  BoxShadow(
                                    color: tp.primaryAccent.withValues(alpha: 0.35),
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

                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isActive ? 1.0 : 0.3,
                  child: Text(
                    'Verse ${ayah.numberInSurah}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: isActive ? 13.5 : 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? tp.textPrimary : tp.textSecondary,
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

  Widget _buildCelestialDiscView({
    required BuildContext context,
    required Surah surah,
    required bool isPlaying,
    required ThemeProvider tp,
    required bool isDark,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _waveformController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: isPlaying ? _waveformController.value * 2 * math.pi : 0.0,
                    child: Container(
                      width: 230,
                      height: 230,
                      decoration: BoxDecoration(
                        color: tp.surfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: tp.borderColor,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: tp.primaryAccent.withValues(alpha: isPlaying ? 0.25 : 0.05),
                            blurRadius: 36,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: tp.borderColor.withValues(alpha: 0.5),
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
                                color: tp.borderColor.withValues(alpha: 0.3),
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

              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: tp.backgroundTop,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: tp.borderColor,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    surah.name.replaceAll('سُورَةُ ', ''),
                    style: TextStyle(
                      fontFamily: 'HafsFont',
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      color: isDark ? const Color(0xFFE2E8F0) : tp.primaryAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            surah.englishName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: tp.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${surah.revelationType} • ${surah.numberOfAyahs} VERSES',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tp.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPlaybackConsole({
    required BuildContext context,
    required QuranProvider quranProvider,
    required bool isPlaying,
    required int currentAyahIndex,
    required Surah surah,
    required ThemeProvider tp,
    required bool isDark,
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
              color: tp.surfaceColor.withValues(alpha: isDark ? 0.94 : 0.96),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: tp.borderColor,
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<Duration>(
                  stream: quranProvider.audioPlayer.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final total = quranProvider.currentAudioDuration ?? const Duration(minutes: 3, seconds: 12);
                    final remaining = total - position;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: tp.textSecondary,
                          ),
                        ),

                        _buildWaveformEqualizer(isPlaying, tp),

                        Text(
                          '-${_formatDuration(remaining > Duration.zero ? remaining : Duration.zero)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: tp.textSecondary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
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
                          color: quranProvider.hifzLoopCount > 1 ? tp.primaryAccent : tp.textSecondary,
                        ),
                      ),
                    ),

                    HeartbeatTap(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        quranProvider.seekBackward10();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.replay_10_rounded,
                          size: 26,
                          color: tp.textPrimary,
                        ),
                      ),
                    ),

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
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: tp.primaryAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: tp.primaryAccent.withValues(alpha: 0.45),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: quranProvider.isAudioLoading
                              ? const SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3.0,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  size: 34,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),

                    HeartbeatTap(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        quranProvider.seekForward10();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.forward_10_rounded,
                          size: 26,
                          color: tp.textPrimary,
                        ),
                      ),
                    ),

                    HeartbeatTap(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _showSurahPlaylistDrawer(context, quranProvider, tp);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.queue_music_rounded,
                          size: 24,
                          color: tp.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                          color: isDark ? const Color(0xFF151D24) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: tp.borderColor, width: 0.8),
                        ),
                        child: Text(
                          '${quranProvider.playbackSpeed.toStringAsFixed(quranProvider.playbackSpeed == 1.0 || quranProvider.playbackSpeed == 2.0 ? 0 : 2)}x',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: tp.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    HeartbeatTap(
                      onTap: () => _showSleepTimerPicker(context, tp),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _sleepTimerMinutes != null
                              ? tp.primaryAccent.withValues(alpha: isDark ? 0.15 : 0.12)
                              : (isDark ? const Color(0xFF151D24) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _sleepTimerMinutes != null ? tp.primaryAccent : tp.borderColor,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bedtime_outlined,
                              size: 14,
                              color: _sleepTimerMinutes != null ? tp.primaryAccent : tp.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _sleepTimerMinutes != null ? '${_sleepTimerMinutes}m' : 'Sleep',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: _sleepTimerMinutes != null ? tp.primaryAccent : tp.textPrimary,
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
      ),
    );
  }

  Widget _buildWaveformEqualizer(bool isPlaying, ThemeProvider tp) {
    return AnimatedBuilder(
      animation: _waveformController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(14, (index) {
            final waveSeed = (index * 0.22) + (_waveformController.value * math.pi);
            final barHeight = isPlaying ? 6.0 + (math.sin(waveSeed).abs() * 16.0) : 4.0;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3.0,
              height: barHeight,
              decoration: BoxDecoration(
                color: isPlaying
                    ? tp.primaryAccent.withValues(alpha: 0.5 + (math.sin(waveSeed).abs() * 0.5))
                    : tp.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
