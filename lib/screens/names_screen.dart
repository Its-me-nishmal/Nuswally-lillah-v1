import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/allah_name.dart';
import '../models/quran_model.dart';
import '../providers/quran_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/heartbeat_tap.dart';
import 'surah_detail_screen.dart';

class NamesScreen extends StatefulWidget {
  const NamesScreen({super.key});

  @override
  State<NamesScreen> createState() => _NamesScreenState();
}

class _NamesScreenState extends State<NamesScreen> {
  static const String _spFavoritesKey = 'favorite_99_names_list';
  static const String _spTipSeenKey = 'has_seen_names_memorization_tip';

  List<AllahName> _allNames = [];
  Set<int> _favoriteNames = {};
  bool _isLoading = true;
  bool _showFavoritesOnly = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Audio Player
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isAudioLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;

  @override
  void initState() {
    super.initState();
    _loadNamesData();
    _initAudioStreams();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final qp = context.read<QuranProvider>();
      if (qp.surahs.isEmpty) {
        qp.fetchSurahs();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _playerStateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initAudioStreams() {
    _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing &&
              state.processingState != ProcessingState.completed;
          _isAudioLoading = state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering;
        });
      }
    });

    _posSub = _audioPlayer.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    _durSub = _audioPlayer.durationStream.listen((dur) {
      if (mounted && dur != null) setState(() => _duration = dur);
    });
  }

  Future<void> _toggleAudio() async {
    HapticFeedback.selectionClick();
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_audioPlayer.processingState == ProcessingState.idle) {
          setState(() => _isAudioLoading = true);
          await _audioPlayer.setAsset('assets/audio/asmaul_husna.mp3');
        }
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Error playing Asmaul Husna audio asset: $e');
    } finally {
      if (mounted) setState(() => _isAudioLoading = false);
    }
  }

  Future<void> _seekAudio(double value) async {
    final target = Duration(milliseconds: value.toInt());
    await _audioPlayer.seek(target);
  }

  Future<void> _loadNamesData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favList = prefs.getStringList(_spFavoritesKey) ?? [];
      final loadedFavs = favList
          .map((e) => int.tryParse(e))
          .whereType<int>()
          .toSet();

      final jsonString =
          await rootBundle.loadString('assets/data/99_names_of_allah.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final List<dynamic> list = jsonMap['data'] as List<dynamic>? ?? [];

      final hasSeenTip = prefs.getBool(_spTipSeenKey) ?? false;

      if (mounted) {
        setState(() {
          _favoriteNames = loadedFavs;
          _allNames = list
              .map((e) => AllahName.fromJson(e as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });

        if (!hasSeenTip) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showMemorizationTipDialog(context, autoOpened: true);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading 99 names JSON or favorites: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _toggleFavorite(int number) async {
    HapticFeedback.selectionClick();
    setState(() {
      if (_favoriteNames.contains(number)) {
        _favoriteNames.remove(number);
      } else {
        _favoriteNames.add(number);
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _spFavoritesKey,
        _favoriteNames.map((e) => e.toString()).toList(),
      );
    } catch (e) {
      debugPrint('Error saving favorite names: $e');
    }
  }

  List<String> _extractReferences(String foundStr) {
    if (foundStr.isEmpty) return [];
    final matches =
        RegExp(r'\(?\s*(\d+\s*:\s*\d+)\s*\)?').allMatches(foundStr);
    if (matches.isNotEmpty) {
      return matches.map((m) => m.group(1)!.replaceAll(' ', '')).toList();
    }
    final clean = foundStr.replaceAll(RegExp(r'[()]'), '').trim();
    return clean.isNotEmpty ? [clean] : [];
  }

  void _navigateToAyah(BuildContext context, String refStr) {
    final clean = refStr.replaceAll(RegExp(r'[^\d:]'), '').trim();
    final parts = clean.split(':');
    if (parts.length == 2) {
      final surahNum = int.tryParse(parts[0]);
      final ayahNum = int.tryParse(parts[1]);

      if (surahNum != null && ayahNum != null) {
        final quranProvider = context.read<QuranProvider>();
        Surah? targetSurah;

        try {
          targetSurah =
              quranProvider.surahs.firstWhere((s) => s.number == surahNum);
        } catch (_) {
          targetSurah = Surah(
            number: surahNum,
            name: '',
            englishName: 'Surah $surahNum',
            englishNameTranslation: '',
            numberOfAyahs: 0,
            revelationType: '',
          );
        }

        HapticFeedback.selectionClick();
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SurahDetailScreen(
              surah: targetSurah!,
              initialAyahIndex: ayahNum > 0 ? ayahNum - 1 : 0,
            ),
          ),
        );
      }
    }
  }

  void _showMemorizationTipDialog(BuildContext context,
      {bool autoOpened = false}) {
    HapticFeedback.selectionClick();
    final tp = context.read<ThemeProvider>();
    final isDark = tp.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            22,
            14,
            22,
            math.max(MediaQuery.paddingOf(ctx).bottom + 22.0, 36.0),
          ),
          decoration: BoxDecoration(
            color: tp.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: tp.borderColor, width: 0.8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: tp.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.lightbulb_rounded,
                    color: Color(0xFFF59E0B),
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Memorization & Tracking Tip',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: tp.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF151D24) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tp.borderColor, width: 0.8),
                ),
                child: Column(
                  children: [
                    Text(
                      'إِنَّ لِلَّهِ تِسْعَةً وَتِسْعِينَ اسْمًا مِائَةً إِلَّا وَاحِدًا مَنْ أَحْصَاهَا دَخَلَ الْجَنَّةَ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'HafsFont',
                        fontSize: 15.5,
                        color: isDark ? const Color(0xFFE2E8F0) : tp.primaryAccent,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '“Allah has ninety-nine names, one hundred less one. Whoever memorizes (comprehends) them will enter Paradise.”',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: tp.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '— Sahih al-Bukhari 2736',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: tp.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildTipStepRow(
                icon: Icons.touch_app_rounded,
                iconColor: tp.primaryAccent,
                title: 'Tap to Learn & Reflect',
                subtitle:
                    'Tap any Divine Name to view its sacred Arabic calligraphy, meaning, and Quran references.',
                tp: tp,
              ),
              const SizedBox(height: 10),

              _buildTipStepRow(
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFFEF4444),
                title: 'Mark as Memorized with ❤️',
                subtitle:
                    'Tap the heart icon on each card as you memorize and internalize each Attribute.',
                tp: tp,
              ),
              const SizedBox(height: 10),

              _buildTipStepRow(
                icon: Icons.filter_list_rounded,
                iconColor: tp.primaryAccent,
                title: 'Review Your Progress',
                subtitle:
                    'Tap the ❤️ counter pill at the top header anytime to filter and review your memorized list.',
                tp: tp,
              ),
              const SizedBox(height: 22),

              HeartbeatTap(
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(_spTipSeenKey, true);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: tp.primaryAccent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: tp.primaryAccent.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Got It • Start Memorizing',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTipStepRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required ThemeProvider tp,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: tp.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: tp.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showNameDetail(BuildContext context, AllahName name) {
    HapticFeedback.selectionClick();
    final tp = context.read<ThemeProvider>();
    final isDark = tp.isDarkMode;
    final references = _extractReferences(name.found);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        final isFav = _favoriteNames.contains(name.number);

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                22,
                14,
                22,
                math.max(MediaQuery.paddingOf(ctx).bottom + 22.0, 36.0),
              ),
              decoration: BoxDecoration(
                color: tp.surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: tp.borderColor, width: 0.8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 38),
                      Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: tp.borderColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      HeartbeatTap(
                        onTap: () {
                          _toggleFavorite(name.number);
                          setModalState(() {});
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isFav
                                ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                : tp.containerColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isFav
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                                  : tp.borderColor,
                              width: 0.8,
                            ),
                          ),
                          child: Icon(
                            isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 18,
                            color: isFav
                                ? const Color(0xFFEF4444)
                                : tp.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Text(
                    name.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'HafsFont',
                      fontSize: 44,
                      fontWeight: FontWeight.normal,
                      color: isDark ? const Color(0xFFF0F6FC) : const Color(0xFF0F172A),
                      height: 1.25,
                      shadows: [
                        Shadow(
                          color: tp.primaryAccent.withValues(alpha: 0.35),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    name.transliteration,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: tp.primaryAccent,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    name.meaning,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: tp.textSecondary,
                    ),
                  ),

                  if (name.description.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF151D24) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: tp.borderColor, width: 0.8),
                      ),
                      child: Text(
                        name.description,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: tp.textPrimary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],

                  if (references.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Mentioned in Quran:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: tp.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: references.map((ref) {
                        return HeartbeatTap(
                          onTap: () => _navigateToAyah(context, ref),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: tp.containerColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: tp.borderColor, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.menu_book_rounded,
                                    size: 13, color: tp.primaryAccent),
                                const SizedBox(width: 6),
                                Text(
                                  ref,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: tp.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 10,
                                  color: tp.primaryAccent,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 22),

                  HeartbeatTap(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: tp.primaryAccent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: tp.primaryAccent.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'CLOSE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final isDark = tp.isDarkMode;
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const double kTopBarHeight = 56.0;

    final query = _searchQuery.trim().toLowerCase();
    final filteredNames = _allNames.where((n) {
      if (_showFavoritesOnly && !_favoriteNames.contains(n.number)) {
        return false;
      }
      if (query.isEmpty) return true;
      return n.name.contains(query) ||
          n.transliteration.toLowerCase().contains(query) ||
          n.meaning.toLowerCase().contains(query) ||
          n.number.toString() == query;
    }).toList();

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

          // Central Soft Ambient Teal Glow
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            left: -40,
            right: -40,
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    tp.primaryAccent.withValues(alpha: isDark ? 0.08 : 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Scrollable Content
          Positioned.fill(
            child: Column(
              children: [
                SizedBox(height: topInset + kTopBarHeight + 8),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: tp.surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: tp.borderColor, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, size: 18, color: tp.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: tp.textPrimary,
                            ),
                            cursorColor: tp.primaryAccent,
                            decoration: InputDecoration(
                              hintText: 'Search by Arabic, name, or meaning...',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 12,
                                color: tp.textMuted,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: Icon(Icons.close_rounded, size: 16, color: tp.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // Audio Recitation Dock
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: tp.surfaceColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _isPlaying
                            ? tp.primaryAccent.withValues(alpha: 0.6)
                            : tp.borderColor,
                        width: 0.8,
                      ),
                      boxShadow: _isPlaying
                          ? [
                              BoxShadow(
                                color: tp.primaryAccent.withValues(alpha: 0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            HeartbeatTap(
                              onTap: _toggleAudio,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: tp.containerColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _isPlaying
                                        ? tp.primaryAccent
                                        : tp.borderColor,
                                    width: 1.2,
                                  ),
                                  boxShadow: _isPlaying
                                      ? [
                                          BoxShadow(
                                            color: tp.primaryAccent.withValues(alpha: 0.35),
                                            blurRadius: 10,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: _isAudioLoading
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: tp.primaryAccent,
                                          ),
                                        )
                                      : Icon(
                                          _isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          color: tp.primaryAccent,
                                          size: 22,
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Asma-ul-Husna Recitation',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: tp.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    'Atif Aslam',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: tp.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${_formatDuration(_position)} / ${_formatDuration(_duration.inMilliseconds > 0 ? _duration : const Duration(minutes: 3, seconds: 23))}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _isPlaying ? tp.primaryAccent : tp.textSecondary,
                              ),
                            ),
                          ],
                        ),

                        if (_duration.inMilliseconds > 0) ...[
                          const SizedBox(height: 4),
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                              activeTrackColor: tp.primaryAccent,
                              inactiveTrackColor: tp.borderColor.withValues(alpha: 0.4),
                              thumbColor: tp.primaryAccent,
                            ),
                            child: Slider(
                              value: _position.inMilliseconds
                                  .clamp(0, _duration.inMilliseconds)
                                  .toDouble(),
                              max: _duration.inMilliseconds.toDouble(),
                              onChanged: _seekAudio,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // Grid of 99 Names
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: tp.primaryAccent,
                          ),
                        )
                      : filteredNames.isEmpty
                          ? Center(
                              child: Text(
                                _showFavoritesOnly
                                    ? 'No memorized names marked yet'
                                    : 'No names match "$_searchQuery"',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: tp.textSecondary,
                                ),
                              ),
                            )
                          : GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                16,
                                6,
                                16,
                                math.max(bottomInset + 16.0, 32.0),
                              ),
                              itemCount: filteredNames.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.90,
                              ),
                              itemBuilder: (context, index) {
                                final row = index ~/ 2;
                                final isLeftCol = (index % 2 == 0);
                                final rtlIndex = isLeftCol
                                    ? (row * 2 + 1 < filteredNames.length
                                        ? row * 2 + 1
                                        : row * 2)
                                    : (row * 2);

                                final name = filteredNames[rtlIndex];
                                return _buildNameCard(context, name, tp, isDark);
                              },
                            ),
                ),
              ],
            ),
          ),

          // Universal 56px Frosted Top Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topInset + kTopBarHeight,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.only(top: topInset),
                  decoration: BoxDecoration(
                    color: tp.backgroundTop.withValues(alpha: isDark ? 0.85 : 0.90),
                    border: Border(
                      bottom: BorderSide(
                        color: tp.borderColor.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: Container(
                    height: 56.0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Back Button
                        HeartbeatTap(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: tp.surfaceColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: tp.borderColor, width: 0.8),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: tp.textPrimary,
                                size: 16,
                              ),
                            ),
                          ),
                        ),

                        // Title with Glowing Orb
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: tp.primaryAccent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: tp.primaryAccent.withValues(alpha: 0.8),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '99 NAMES OF ALLAH',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: tp.textPrimary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right Cluster (Tip Bulb & Fav Filter Pill)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HeartbeatTap(
                              onTap: () => _showMemorizationTipDialog(context),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: tp.surfaceColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: tp.borderColor, width: 0.8),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.lightbulb_outline_rounded,
                                    size: 16,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            HeartbeatTap(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _showFavoritesOnly = !_showFavoritesOnly;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _showFavoritesOnly
                                      ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                      : tp.surfaceColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _showFavoritesOnly
                                        ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                                        : tp.borderColor,
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _showFavoritesOnly
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      size: 13,
                                      color: _showFavoritesOnly
                                          ? const Color(0xFFEF4444)
                                          : tp.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_favoriteNames.length}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: _showFavoritesOnly
                                            ? const Color(0xFFEF4444)
                                            : tp.textPrimary,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameCard(BuildContext context, AllahName name, ThemeProvider tp, bool isDark) {
    final isFav = _favoriteNames.contains(name.number);

    return Stack(
      children: [
        Positioned.fill(
          child: HeartbeatTap(
            onTap: () => _showNameDetail(context, name),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: tp.surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isFav
                      ? const Color(0xFFEF4444).withValues(alpha: 0.35)
                      : tp.borderColor,
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: tp.primaryAccent.withValues(alpha: isDark ? 0.14 : 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        name.number.toString().padLeft(2, '0'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: tp.primaryAccent,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      name.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'HafsFont',
                        fontSize: 26,
                        fontWeight: FontWeight.normal,
                        color: isDark ? const Color(0xFFF0F6FC) : const Color(0xFF0F172A),
                        height: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    name.transliteration,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: tp.primaryAccent,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    name.meaning,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: tp.textSecondary,
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          top: 6,
          left: 6,
          child: HeartbeatTap(
            onTap: () => _toggleFavorite(name.number),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isFav
                    ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 17,
                  color: isFav
                      ? const Color(0xFFEF4444)
                      : tp.textMuted,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
