import 'dart:async';
import 'dart:convert';
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
import '../theme/jira_theme.dart';
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

    // Pre-cache Quran surahs for smooth Ayah jump navigation
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

        // Show tip automatically on first opening
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
        Navigator.pop(context); // Close bottom modal
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
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
          decoration: const BoxDecoration(
            color: Color(0xFF161B22),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Color(0xFF30363D), width: 1),
              left: BorderSide(color: Color(0xFF30363D), width: 1),
              right: BorderSide(color: Color(0xFF30363D), width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF484F58),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Lightbulb Emblem
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
                    color: Color(0xFFFBBF24),
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Memorization & Tracking Tip',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF0F6FC),
                ),
              ),
              const SizedBox(height: 8),

              // Noble Hadith Quote
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D121D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'إِنَّ لِلَّهِ تِسْعَةً وَتِسْعِينَ اسْمًا مِائَةً إِلَّا وَاحِدًا مَنْ أَحْصَاهَا دَخَلَ الْجَنَّةَ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'HafsFont',
                        fontSize: 16,
                        color: Color(0xFF93C5FD),
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
                        color: const Color(0xFFC9D1D9),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '— Sahih al-Bukhari 2736',
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8B949E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // How to use Favorites as Tracker
              _buildTipStepRow(
                icon: Icons.touch_app_rounded,
                iconColor: const Color(0xFF60A5FA),
                title: 'Tap to Learn & Reflect',
                subtitle:
                    'Tap any Divine Name to view its sacred Arabic script, meaning, and Quran references.',
              ),
              const SizedBox(height: 10),

              _buildTipStepRow(
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFFEF4444),
                title: 'Mark as Memorized with ❤️',
                subtitle:
                    'Tap the heart icon on each card as you memorize and internalize them one by one.',
              ),
              const SizedBox(height: 10),

              _buildTipStepRow(
                icon: Icons.filter_list_rounded,
                iconColor: JiraTheme.secondaryGreen,
                title: 'Review Your Progress',
                subtitle:
                    'Tap the ❤️ counter pill at the top header anytime to filter and review your memorized list.',
              ),
              const SizedBox(height: 22),

              // Action Button
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
                    color: JiraTheme.secondaryGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'Got It • Start Memorizing',
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
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
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF0F6FC),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: const Color(0xFF8B949E),
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
    final references = _extractReferences(name.found);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isFav = _favoriteNames.contains(name.number);

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
              decoration: const BoxDecoration(
                color: Color(0xFF161B22),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: Color(0xFF30363D), width: 1),
                  left: BorderSide(color: Color(0xFF30363D), width: 1),
                  right: BorderSide(color: Color(0xFF30363D), width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Drag Handle & Favorite Button in Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF484F58),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      HeartbeatTap(
                        onTap: () {
                          _toggleFavorite(name.number);
                          setModalState(() {});
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2530),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF30363D)),
                          ),
                          child: Icon(
                            isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 18,
                            color: isFav
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF8B949E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 2. Majestic Glowing Arabic Calligraphy
                  Text(
                    name.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'HafsFont',
                      fontSize: 46,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFF0F6FC),
                      height: 1.15,
                      shadows: [
                        Shadow(
                          color:
                              const Color(0xFF93C5FD).withValues(alpha: 0.45),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 3. Transliteration in Radiant Emerald Green
                  Text(
                    name.transliteration,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: JiraTheme.secondaryGreen,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 4. English Description / Meaning
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      name.description.isNotEmpty
                          ? name.description
                          : name.meaning,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: const Color(0xFFC9D1D9),
                        height: 1.55,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 5. Clickable Quran Reference Pill Button
                  if (references.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: references.map((ref) {
                        return HeartbeatTap(
                          onTap: () => _navigateToAyah(context, ref),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F242C),
                              borderRadius: BorderRadius.circular(24),
                              border:
                                  Border.all(color: const Color(0xFF30363D)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.menu_book_rounded,
                                  size: 15,
                                  color: Color(0xFF93C5FD),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Quran Reference: ($ref)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFF0F6FC),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 11,
                                  color: JiraTheme.primaryBlue,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 28),

                  // 6. Action Button: CLOSE
                  HeartbeatTap(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: JiraTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: JiraTheme.primaryBlue.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'CLOSE',
                          style: GoogleFonts.outfit(
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
    final isMl = tp.isMalayalam;

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
      backgroundColor: const Color(0xFF0B0E14),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  HeartbeatTap(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF30363D)),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFFF0F6FC),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMl ? 'അസ്മാഉൽ ഹുസ്ന' : '99 NAMES OF ALLAH',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: const Color(0xFFF0F6FC),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'أَسْمَاءُ اللَّهِ الْحُسْنَى • The Divine Attributes',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF8B949E),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Memorization Tip Lightbulb Button
                  HeartbeatTap(
                    onTap: () => _showMemorizationTipDialog(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2530),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 18,
                          color: Color(0xFFFBBF24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Favorite Filter Switch Pill
                  HeartbeatTap(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _showFavoritesOnly = !_showFavoritesOnly;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: _showFavoritesOnly
                            ? const Color(0xFFEF4444).withValues(alpha: 0.18)
                            : const Color(0xFF1E2530),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _showFavoritesOnly
                              ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                              : const Color(0xFF30363D),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showFavoritesOnly
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 14,
                            color: _showFavoritesOnly
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF8B949E),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${_favoriteNames.length}',
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: _showFavoritesOnly
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFF0F6FC),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        size: 18, color: Color(0xFF8B949E)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: const Color(0xFFF0F6FC)),
                        cursorColor: JiraTheme.primaryBlue,
                        decoration: InputDecoration(
                          hintText: 'Search by Arabic, name, or meaning...',
                          hintStyle: GoogleFonts.inter(
                              fontSize: 12, color: const Color(0xFF64748B)),
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
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: Color(0xFF8B949E)),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // 3. Audio Player Header Card (Atif Aslam Recitation)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _isPlaying
                        ? JiraTheme.secondaryGreen.withValues(alpha: 0.6)
                        : const Color(0xFF2A323D),
                  ),
                  boxShadow: _isPlaying
                      ? [
                          BoxShadow(
                            color: JiraTheme.secondaryGreen
                                .withValues(alpha: 0.15),
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
                        // Play / Pause Action Button
                        HeartbeatTap(
                          onTap: _toggleAudio,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFF12161F),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isPlaying
                                    ? JiraTheme.secondaryGreen
                                    : const Color(0xFF384353),
                                width: 1.5,
                              ),
                              boxShadow: _isPlaying
                                  ? [
                                      BoxShadow(
                                        color: JiraTheme.secondaryGreen
                                            .withValues(alpha: 0.35),
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: _isAudioLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: JiraTheme.secondaryGreen,
                                      ),
                                    )
                                  : Icon(
                                      _isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: _isPlaying
                                          ? JiraTheme.secondaryGreen
                                          : const Color(0xFF93C5FD),
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
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFF0F6FC),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Atif Aslam',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: const Color(0xFF8B949E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Live Time Counter
                        Text(
                          '${_formatDuration(_position)} / ${_formatDuration(_duration.inMilliseconds > 0 ? _duration : const Duration(minutes: 3, seconds: 23))}',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _isPlaying
                                ? JiraTheme.secondaryGreen
                                : const Color(0xFF8B949E),
                          ),
                        ),
                      ],
                    ),

                    // Seek Slider
                    if (_duration.inMilliseconds > 0) ...[
                      const SizedBox(height: 4),
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5),
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 10),
                          activeTrackColor: JiraTheme.secondaryGreen,
                          inactiveTrackColor: const Color(0xFF1F242C),
                          thumbColor: JiraTheme.secondaryGreen,
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

            // 4. Grid of Names (Generous vertical card height)
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: JiraTheme.primaryBlue),
                    )
                  : filteredNames.isEmpty
                      ? Center(
                          child: Text(
                            _showFavoritesOnly
                                ? 'No favorite names added yet'
                                : 'No names match "$_searchQuery"',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: const Color(0xFF8B949E)),
                          ),
                        )
                      : GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(16, 6, 16, 24 + MediaQuery.paddingOf(context).bottom),
                          itemCount: filteredNames.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.90,
                          ),
                          itemBuilder: (context, index) {
                            // Compute RTL visual pairing:
                            // Left slot (col 0) gets name #2, Right slot (col 1) gets name #1
                            final row = index ~/ 2;
                            final isLeftCol = (index % 2 == 0);
                            final rtlIndex = isLeftCol
                                ? (row * 2 + 1 < filteredNames.length
                                    ? row * 2 + 1
                                    : row * 2)
                                : (row * 2);

                            final name = filteredNames[rtlIndex];
                            return _buildNameCard(context, name);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameCard(BuildContext context, AllahName name) {
    final isFav = _favoriteNames.contains(name.number);

    return Stack(
      children: [
        // Main Card Body (Click to open details)
        Positioned.fill(
          child: HeartbeatTap(
            onTap: () => _showNameDetail(context, name),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isFav
                      ? const Color(0xFFEF4444).withValues(alpha: 0.35)
                      : const Color(0xFF252D38),
                ),
              ),
              child: Column(
                children: [
                  // Top Row: Number badge on RIGHT (leaving space for heart on left)
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2530),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        name.number.toString().padLeft(2, '0'),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF93C5FD),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Centered Arabic Calligraphy
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      name.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'HafsFont',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF0F6FC),
                        height: 1.15,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Transliteration in Radiant Emerald Green
                  Text(
                    name.transliteration,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: JiraTheme.secondaryGreen,
                    ),
                  ),

                  const SizedBox(height: 3),

                  // English Meaning Subtitle
                  Text(
                    name.meaning,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF8B949E),
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ),

        // Dedicated Top-Left Favorite Button with generous tap area
        Positioned(
          top: 6,
          left: 6,
          child: HeartbeatTap(
            onTap: () => _toggleFavorite(name.number),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isFav
                    ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 19,
                  color: isFav
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
