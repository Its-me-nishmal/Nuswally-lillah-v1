import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/quran_model.dart';
import '../providers/quran_provider.dart';

class SurahDetailScreen extends StatefulWidget {
  final Surah surah;
  final int initialAyahIndex;
  const SurahDetailScreen({
    super.key,
    required this.surah,
    this.initialAyahIndex = 0,
  });

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasInitialScrolled = false;
  bool _isAutoScrolling = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final provider = context.read<QuranProvider>();
      provider.fetchSurahDetails(widget.surah.number);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleAutoScroll(QuranProvider provider) {
    setState(() {
      _isAutoScrolling = !_isAutoScrolling;
    });
    if (_isAutoScrolling) {
      _runAutoScroll(provider);
    } else {
      if (_scrollController.hasClients) {
        _scrollController.position.hold(() {});
      }
    }
  }

  void _runAutoScroll(QuranProvider provider) {
    if (!_isAutoScrolling || !_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final remaining = maxScroll - _scrollController.offset;
    if (remaining <= 0) {
      setState(() { _isAutoScrolling = false; });
      return;
    }
    
    final speed = provider.autoScrollSpeed > 0 ? provider.autoScrollSpeed : 30.0;
    final durationSeconds = remaining / speed;
    
    _scrollController.animateTo(
      maxScroll,
      duration: Duration(milliseconds: (durationSeconds * 1000).toInt()),
      curve: Curves.linear,
    ).then((_) {
      if (mounted && _isAutoScrolling) {
        setState(() { _isAutoScrolling = false; });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          image: const DecorationImage(
            image: AssetImage('assets/images/islamic_bg.png'),
            opacity: 0.05,
            repeat: ImageRepeat.repeat,
          ),
        ),
        child: SafeArea(
          child: Consumer<QuranProvider>(
            builder: (context, provider, child) {
              // Auto-scroll to top when loaded, or to last read position
              if (!provider.isLoadingAyahs && provider.ayahs.isNotEmpty && !_hasInitialScrolled) {
                _hasInitialScrolled = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_scrollController.hasClients) return;
                  if (widget.initialAyahIndex > 0) {
                    final maxScroll = _scrollController.position.maxScrollExtent;
                    final ratio = widget.initialAyahIndex / (provider.ayahs.length - 1);
                    _scrollController.jumpTo((maxScroll * ratio).clamp(0, maxScroll));
                  } else {
                    _scrollController.jumpTo(0);
                  }
                });
              }

          // Auto-scroll only during audio playback (if auto-scroll is not active)
              if (provider.currentPlayingIndex != null && provider.playerState?.playing == true && !_isAutoScrolling) {
                final audioDuration = provider.currentAudioDuration ?? const Duration(seconds: 5);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToAyah(
                    provider.currentPlayingIndex!,
                    provider.ayahs.length,
                    audioDuration,
                  );
                });
              }

              return Column(
                children: [
                  _buildAppBar(context, provider),
                  Expanded(
                    child: NotificationListener<UserScrollNotification>(
                      onNotification: (notification) {
                        if (_isAutoScrolling && notification.direction != ScrollDirection.idle) {
                          setState(() { _isAutoScrolling = false; });
                        }
                        return false;
                      },
                      child: provider.isLoadingAyahs
                          ? const Center(child: CircularProgressIndicator())
                          : provider.ayahs.isEmpty
                              ? _buildErrorView(context, provider)
                              : _buildFullTextFlow(context, provider),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, QuranProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPlaying = provider.playerState?.playing == true;
    final isBookmarked = provider.isBookmarked(widget.surah.number);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.primary),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              widget.surah.englishName,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          // Bookmark
          IconButton(
            onPressed: () => provider.toggleBookmark(widget.surah.number),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                key: ValueKey(isBookmarked),
                color: colorScheme.primary,
              ),
            ),
          ),
          // Auto Scroll
          IconButton(
            onPressed: () => _toggleAutoScroll(provider),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                _isAutoScrolling ? Icons.pause_circle_outline_rounded : Icons.move_down_rounded,
                key: ValueKey(_isAutoScrolling),
                color: _isAutoScrolling ? colorScheme.secondary : colorScheme.primary,
              ),
            ),
          ),
          // Reading Settings
          IconButton(
            onPressed: () => _showReadingSettings(context, provider),
            icon: Icon(Icons.format_size_rounded, color: colorScheme.primary),
          ),
          // Global Audio Controls
          IconButton(
            onPressed: () {
              if (isPlaying) {
                provider.pauseAudio();
              } else {
                provider.playAll();
              }
            },
            icon: Icon(
              isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
              color: colorScheme.primary,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  void _showReadingSettings(BuildContext context, QuranProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Reading Settings',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Reciter (Qari)',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: provider.selectedQari,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).colorScheme.primary),
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        items: QuranProvider.availableQaris.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              style: GoogleFonts.outfit(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            provider.updateQari(newValue);
                            setModalState(() {});
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Font Size: ${provider.fontSize.toInt()}px',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: provider.fontSize,
                    min: 20,
                    max: 50,
                    onChanged: (value) {
                      provider.updateFontSize(value);
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Auto-Scroll Speed',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: provider.autoScrollSpeed,
                    min: 10,
                    max: 100,
                    onChanged: (value) {
                      provider.updateAutoScrollSpeed(value);
                      setModalState(() {});
                      // Update scroll speed live while dragging
                      if (_isAutoScrolling) {
                        _runAutoScroll(provider);
                      }
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Slow', style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5))),
                      Text('Fast', style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5))),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSimpleHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          if (widget.surah.number != 1 && widget.surah.number != 9)
            Text(
              'بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ',
              style: TextStyle(
                fontFamily: 'HafsFont',
                color: colorScheme.primary,
                fontSize: 32,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            '${widget.surah.revelationType} • ${widget.surah.numberOfAyahs} VERSES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: colorScheme.primary.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullTextFlow(BuildContext context, QuranProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Column(
        children: [
          _buildSimpleHeader(context),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text.rich(
              textAlign: TextAlign.justify,
              TextSpan(
                children: List.generate(provider.ayahs.length, (index) {
                  final ayah = provider.ayahs[index];
                  final isHighlighted = provider.highlightedAyahIndex == index;
                  final isPlaying = provider.currentPlayingIndex == index;

                  return TextSpan(
                    children: [
                      TextSpan(
                        text: ayah.text,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => provider.selectAyah(index),
                        style: TextStyle(
                          fontFamily: 'HafsFont',
                          fontSize: provider.fontSize,
                          height: 2.2,
                          color: colorScheme.onSurface,
                          backgroundColor: isHighlighted || isPlaying
                              ? colorScheme.primary.withValues(alpha: 0.08)
                              : Colors.transparent,
                          fontWeight: (isHighlighted || isPlaying) ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isHighlighted || isPlaying
                                ? colorScheme.primary.withValues(alpha: 0.1)
                                : Colors.transparent,
                            border: Border.all(
                              color: isHighlighted || isPlaying
                                  ? colorScheme.primary
                                  : colorScheme.primary.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            ayah.numberInSurah.toString(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isHighlighted || isPlaying
                                  ? colorScheme.primary
                                  : colorScheme.primary.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Teleprompter scroll: glides for the full duration of the audio clip
  void _scrollToAyah(int index, int total, Duration audioDuration) {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final viewportHeight = _scrollController.position.viewportDimension;

    // Proportional position of this ayah in the full text
    final ratio = total > 1 ? index / (total - 1) : 0.0;
    final rawTarget = maxScroll * ratio;

    // Center it on screen
    final centeredTarget = (rawTarget - viewportHeight / 2).clamp(0.0, maxScroll);

    // Animate for the exact duration of the audio — constant speed, no easing
    _scrollController.animateTo(
      centeredTarget,
      duration: audioDuration,
      curve: Curves.linear,
    );
  }

  Widget _buildErrorView(BuildContext context, QuranProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 64, color: colorScheme.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('Failed to load verses.'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => provider.fetchSurahDetails(widget.surah.number),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
