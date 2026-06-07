import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../providers/quran_provider.dart';
import '../models/quran_model.dart';
import '../providers/theme_provider.dart';

class AudioQuranScreen extends StatefulWidget {
  const AudioQuranScreen({super.key});

  @override
  State<AudioQuranScreen> createState() => _AudioQuranScreenState();
}

class _AudioQuranScreenState extends State<AudioQuranScreen> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  bool _isSurahLoading = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    Future.microtask(() async {
      if (!mounted) return;
      final provider = Provider.of<QuranProvider>(context, listen: false);
      await provider.fetchSurahs();
      if (!mounted) return;
      if (provider.currentViewingSurahNumber == null && provider.surahs.isNotEmpty) {
        setState(() => _isSurahLoading = true);
        await provider.fetchSurahDetails(1);
        if (!mounted) return;
        setState(() => _isSurahLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _selectSurah(QuranProvider provider, Surah surah) async {
    setState(() => _isSurahLoading = true);
    await provider.fetchSurahDetails(surah.number);
    setState(() => _isSurahLoading = false);
    // Auto play from beginning
    if (provider.ayahs.isNotEmpty) {
      provider.togglePlayAyah(0);
    }
  }

  void _showAyahJumpDialog(BuildContext context, QuranProvider provider, int totalAyahs) {
    final colorScheme = Theme.of(context).colorScheme;
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Jump to Verse',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter a verse number between 1 and $totalAyahs:',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'e.g. 5',
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(textController.text);
              if (val != null && val >= 1 && val <= totalAyahs) {
                provider.togglePlayAyah(val - 1);
                Navigator.pop(context);
              } else {
                HapticFeedback.vibrate();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'JUMP',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<QuranProvider>();
    final isPlaying = provider.playerState?.playing == true;

    // Control rotating animation based on playback state
    if (isPlaying) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    } else {
      if (_rotationController.isAnimating) {
        _rotationController.stop();
      }
    }

    final activeSurah = provider.surahs.isEmpty
        ? null
        : provider.surahs.firstWhere(
            (s) => s.number == (provider.currentViewingSurahNumber ?? 1),
            orElse: () => provider.surahs.first,
          );

    final totalAyahs = provider.ayahs.length;
    final currentIndex = provider.currentPlayingIndex != null && provider.currentPlayingIndex! < totalAyahs
        ? provider.currentPlayingIndex!
        : 0;

    final currentAyah = provider.ayahs.isNotEmpty &&
                        provider.currentPlayingIndex != null &&
                        provider.currentPlayingIndex! < totalAyahs
        ? provider.ayahs[provider.currentPlayingIndex!]
        : null;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.4,
            colors: [
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
              colorScheme.surface,
            ],
          ),
          image: const DecorationImage(
            image: AssetImage('assets/images/islamic_bg.png'),
            opacity: 0.02,
            repeat: ImageRepeat.repeat,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: _isSurahLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 10),
                            _buildPlayerDisc(context, isPlaying),
                            const SizedBox(height: 24),
                            _buildVisualizer(context, isPlaying),
                            const SizedBox(height: 16),
                            _buildMetadata(context, activeSurah, currentAyah),
                            const SizedBox(height: 32),
                            _buildTimelineSeekbar(context, provider, currentIndex, totalAyahs),
                            const SizedBox(height: 24),
                            _buildControlButtons(context, provider, activeSurah, currentIndex, totalAyahs),
                            const SizedBox(height: 24),
                            _buildHifzAndSpeedControls(context, provider),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.primary),
          ),
          Text(
            'QURAN PLAYER',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: colorScheme.primary,
            ),
          ),
          IconButton(
            onPressed: () => _showRecitersSheet(context),
            icon: Icon(Icons.record_voice_over_rounded, color: colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerDisc(BuildContext context, bool isPlaying) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationController.value * 2 * math.pi,
            child: child,
          );
        },
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: isPlaying ? 0.25 : 0.08),
                blurRadius: isPlaying ? 25 : 15,
                spreadRadius: isPlaying ? 3 : 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.15),
              width: 3,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Vinyl grooves
              ...List.generate(3, (index) {
                double size = 130 - (index * 30);
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.onSurface.withValues(alpha: 0.04),
                      width: 1,
                    ),
                  ),
                );
              }),
              // Central golden artwork
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 3,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.star_border_purple500_rounded,
                    color: Colors.white70,
                    size: 24,
                  ),
                ),
              ),
              // Central spindle hole
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF0F1717) : Colors.grey[200],
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisualizer(BuildContext context, bool isPlaying) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 24,
      child: isPlaying
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(7, (index) {
                return _VisualizerBar(color: colorScheme.primary);
              }),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(7, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 3,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
    );
  }

  Widget _buildMetadata(BuildContext context, Surah? activeSurah, Ayah? currentAyah) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    if (activeSurah == null) return const SizedBox();

    return Column(
      children: [
        Text(
          activeSurah.englishName.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${activeSurah.englishNameTranslation} • ${activeSurah.numberOfAyahs} Verses',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showRecitersSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.15)),
            ),
            child: Consumer<QuranProvider>(
              builder: (context, provider, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      QuranProvider.availableQaris[provider.selectedQari] ?? '',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        if (currentAyah != null) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              currentAyah.text,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'HafsFont',
                fontSize: 24,
                height: 1.8,
                color: themeProvider.primaryAccent,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimelineSeekbar(
    BuildContext context,
    QuranProvider provider,
    int currentIndex,
    int totalAyahs,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (totalAyahs == 0) {
      return const SizedBox(
        height: 60,
        child: Center(child: Text('Loading track details...')),
      );
    }

    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.1),
            thumbColor: colorScheme.primary,
            overlayColor: colorScheme.primary.withValues(alpha: 0.15),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: currentIndex.clamp(0, totalAyahs - 1).toDouble(),
            min: 0,
            max: (totalAyahs - 1).toDouble(),
            divisions: totalAyahs > 1 ? totalAyahs - 1 : 1,
            onChanged: (val) {
              provider.togglePlayAyah(val.toInt());
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _showAyahJumpDialog(context, provider, totalAyahs),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorScheme.primary.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Verse ${currentIndex + 1}',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit_rounded,
                          size: 10,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Text(
                'Verse $totalAyahs',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons(
    BuildContext context,
    QuranProvider provider,
    Surah? activeSurah,
    int currentIndex,
    int totalAyahs,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPlaying = provider.playerState?.playing == true;
    final processingState = provider.playerState?.processingState;
    final isLoading = processingState == ProcessingState.loading ||
        processingState == ProcessingState.buffering;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Playlist/Queue
        IconButton(
          icon: Icon(Icons.playlist_play_rounded, size: 28, color: colorScheme.primary.withValues(alpha: 0.8)),
          onPressed: () => _showSurahsSheet(context, provider),
        ),
        // Previous Ayah
        IconButton(
          icon: Icon(Icons.skip_previous_rounded, size: 36, color: colorScheme.primary),
          onPressed: totalAyahs > 0
              ? () {
                  int prevIndex = currentIndex - 1;
                  if (prevIndex < 0) prevIndex = totalAyahs - 1;
                  provider.togglePlayAyah(prevIndex);
                }
              : null,
        ),
        // Play / Pause glowing button
        GestureDetector(
          onTap: () {
            if (isPlaying) {
              provider.pauseAudio();
            } else {
              provider.playAll();
            }
          },
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  )
                : Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
          ),
        ),
        // Next Ayah
        IconButton(
          icon: Icon(Icons.skip_next_rounded, size: 36, color: colorScheme.primary),
          onPressed: totalAyahs > 0
              ? () {
                  int nextIndex = currentIndex + 1;
                  if (nextIndex >= totalAyahs) nextIndex = 0;
                  provider.togglePlayAyah(nextIndex);
                }
              : null,
        ),
        // Auto-play / repeat label toggle info
        IconButton(
          icon: Icon(Icons.repeat_rounded, size: 28, color: colorScheme.primary.withValues(alpha: 0.8)),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ayah auto-continuous mode is active by default.'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showSurahsSheet(BuildContext context, QuranProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredSurahs = provider.surahs.where((surah) {
              final query = searchQuery.toLowerCase();
              return surah.englishName.toLowerCase().contains(query) ||
                  surah.englishNameTranslation.toLowerCase().contains(query) ||
                  surah.number.toString().contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Select Chapter (Surah)',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  // Search Input
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: TextField(
                      onChanged: (val) {
                        setModalState(() {
                          searchQuery = val;
                        });
                      },
                      style: GoogleFonts.outfit(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search Surah by name or number...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: colorScheme.primary),
                        ),
                        filled: true,
                        fillColor: isDark ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : Colors.grey[50],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: filteredSurahs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final surah = filteredSurahs[index];
                        final isCurrent = provider.currentViewingSurahNumber == surah.number;

                        return Container(
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? colorScheme.primary.withValues(alpha: 0.08)
                                : (isDark ? colorScheme.surfaceContainerHighest : Colors.grey[50]),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCurrent ? colorScheme.primary : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isCurrent ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.08),
                              child: Text(
                                surah.number.toString(),
                                style: GoogleFonts.outfit(
                                  color: isCurrent ? Colors.white : colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            title: Text(
                              surah.englishName,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              '${surah.englishNameTranslation} • ${surah.numberOfAyahs} Ayahs',
                              style: GoogleFonts.outfit(fontSize: 11),
                            ),
                            trailing: Text(
                              surah.name,
                              style: TextStyle(
                                fontFamily: 'HafsFont',
                                fontSize: 20,
                                color: Provider.of<ThemeProvider>(context, listen: false).primaryAccent,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _selectSurah(provider, surah);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRecitersSheet(BuildContext context) {
    final provider = context.read<QuranProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Reciter (Qari)',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...QuranProvider.availableQaris.entries.map((entry) {
                    final isSelected = provider.selectedQari == entry.key;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.08)
                            : (isDark ? colorScheme.surfaceContainerHighest : Colors.grey[50]),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? colorScheme.primary : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.record_voice_over_rounded,
                          color: isSelected ? colorScheme.primary : Colors.grey,
                        ),
                        title: Text(
                          entry.value,
                          style: GoogleFonts.outfit(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
                            : null,
                        onTap: () {
                          provider.updateQari(entry.key);
                          setModalState(() {});
                          setState(() {}); // refresh the player screen qari text
                          Navigator.pop(context);
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHifzAndSpeedControls(BuildContext context, QuranProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Delay Active pulsing indicator
        if (provider.isDelayActive) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Hifz Silent Delay Active... Recite now!',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.psychology_rounded, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'HIFZ MEMORIZATION ASSISTANT',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 0.5),

              // Loop Count & Delay row
              Row(
                children: [
                  // Loop Count Control
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verse Repetitions',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildHifzMiniButton(
                              context,
                              icon: Icons.remove_rounded,
                              onPressed: provider.hifzLoopCount > 1
                                  ? () => provider.updateHifzLoopCount(provider.hifzLoopCount - 1)
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '${provider.hifzLoopCount}x',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            _buildHifzMiniButton(
                              context,
                              icon: Icons.add_rounded,
                              onPressed: provider.hifzLoopCount < 10
                                  ? () => provider.updateHifzLoopCount(provider.hifzLoopCount + 1)
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Delay Gap Control
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recitation Delay',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildHifzMiniButton(
                              context,
                              icon: Icons.remove_rounded,
                              onPressed: provider.hifzDelaySeconds > 0
                                  ? () => provider.updateHifzDelaySeconds(
                                        provider.hifzDelaySeconds == 3 ? 0 : provider.hifzDelaySeconds - 3,
                                      )
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                provider.hifzDelaySeconds == 0 ? 'Off' : '${provider.hifzDelaySeconds}s',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            _buildHifzMiniButton(
                              context,
                              icon: Icons.add_rounded,
                              onPressed: provider.hifzDelaySeconds < 30
                                  ? () => provider.updateHifzDelaySeconds(provider.hifzDelaySeconds + 3)
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              // Playback Speed Slider / Pills
              Text(
                'Recitation Playback Speed',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [0.8, 1.0, 1.25, 1.5].map((speed) {
                  final isSelected = provider.playbackSpeed == speed;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => provider.updatePlaybackSpeed(speed),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primary
                                : (isDark ? colorScheme.surface : Colors.grey[200]),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? colorScheme.primary : Colors.transparent,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              speed == 1.0 ? 'Normal' : '${speed}x',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHifzMiniButton(BuildContext context, {required IconData icon, VoidCallback? onPressed}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 16),
        color: colorScheme.primary,
        onPressed: onPressed,
      ),
    );
  }
}

class _VisualizerBar extends StatefulWidget {
  final Color color;
  const _VisualizerBar({required this.color});

  @override
  State<_VisualizerBar> createState() => _VisualizerBarState();
}

class _VisualizerBarState extends State<_VisualizerBar> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _heightAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + math.Random().nextInt(300)),
    )..repeat(reverse: true);

    _heightAnim = Tween<double>(begin: 4, end: 20 + math.Random().nextDouble() * 12).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _heightAnim,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 3.5,
          height: _heightAnim.value,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
