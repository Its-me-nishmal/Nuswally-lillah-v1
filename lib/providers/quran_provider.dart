import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quran_model.dart';

class QuranProvider with ChangeNotifier {
  List<Surah> _surahs = [];
  bool _isLoadingSurahs = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  List<Ayah> _ayahs = [];
  bool _isLoadingAyahs = false;
  List<dynamic>? _cachedFullQuran;
  
  int? _currentPlayingIndex;
  int? _highlightedAyahIndex;
  PlayerState? _playerState;
  double _fontSize = 28.0;
  double _autoScrollSpeed = 30.0;
  String _selectedQari = 'Alafasy_128kbps';
  int? _currentViewingSurahNumber;
  Set<int> _bookmarkedSurahNumbers = {};

  static const Map<String, String> availableQaris = {
    'Alafasy_128kbps': 'Mishary Rashid Alafasy',
    'Abdul_Basit_Murattal_192kbps': 'Abdul Basit',
    'Abdurrahmaan_As-Sudais_192kbps': 'Abdurrahmaan As-Sudais',
    'Minshawy_Murattal_128kbps': 'Muhammad Siddiq al-Minshawi',
    'Abu_Bakr_Ash-Shaatree_128kbps': 'Abu Bakr al-Shatri',
  };

  // Last read tracking
  int? _lastReadSurahNumber;
  String? _lastReadSurahName;
  int _lastReadAyahIndex = 0;

  List<Surah> get surahs => _surahs;
  bool get isLoadingSurahs => _isLoadingSurahs;
  List<Ayah> get ayahs => _ayahs;
  bool get isLoadingAyahs => _isLoadingAyahs;
  int? get currentPlayingIndex => _currentPlayingIndex;
  int? get highlightedAyahIndex => _highlightedAyahIndex;
  PlayerState? get playerState => _playerState;
  Duration? get currentAudioDuration => _audioPlayer.duration;
  double get fontSize => _fontSize;
  double get autoScrollSpeed => _autoScrollSpeed;
  String get selectedQari => _selectedQari;
  Set<int> get bookmarkedSurahNumbers => _bookmarkedSurahNumbers;
  int? get lastReadSurahNumber => _lastReadSurahNumber;
  String? get lastReadSurahName => _lastReadSurahName;
  int get lastReadAyahIndex => _lastReadAyahIndex;

  QuranProvider() {
    _loadSettings();
    _audioPlayer.playerStateStream.listen((state) {
      _playerState = state;
      if (state.processingState == ProcessingState.completed) {
        playNextAyah();
      }
      notifyListeners();
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble('quran_font_size') ?? 28.0;
    _autoScrollSpeed = prefs.getDouble('quran_auto_scroll_speed') ?? 30.0;
    _selectedQari = prefs.getString('quran_selected_qari') ?? 'Alafasy_128kbps';
    final saved = prefs.getStringList('bookmarked_surahs') ?? [];
    _bookmarkedSurahNumbers = saved.map((s) => int.parse(s)).toSet();
    _lastReadSurahNumber = prefs.getInt('last_read_surah');
    _lastReadSurahName = prefs.getString('last_read_surah_name');
    _lastReadAyahIndex = prefs.getInt('last_read_ayah') ?? 0;
    notifyListeners();
  }

  Future<void> toggleBookmark(int surahNumber) async {
    if (_bookmarkedSurahNumbers.contains(surahNumber)) {
      _bookmarkedSurahNumbers.remove(surahNumber);
    } else {
      _bookmarkedSurahNumbers.add(surahNumber);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'bookmarked_surahs',
      _bookmarkedSurahNumbers.map((n) => n.toString()).toList(),
    );
  }

  bool isBookmarked(int surahNumber) => _bookmarkedSurahNumbers.contains(surahNumber);

  Future<void> updateFontSize(double newSize) async {
    _fontSize = newSize;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('quran_font_size', newSize);
  }

  Future<void> updateAutoScrollSpeed(double newSpeed) async {
    _autoScrollSpeed = newSpeed;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('quran_auto_scroll_speed', newSpeed);
  }

  Future<void> updateQari(String newQariId) async {
    if (_selectedQari == newQariId) return;
    
    // Stop audio if playing
    if (_audioPlayer.playing) await _audioPlayer.pause();
    
    _selectedQari = newQariId;
    _cachedAyahs.clear(); // Clear cache to force URL rebuild
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quran_selected_qari', newQariId);
    
    // If we are currently viewing a surah, reload it with new audio URLs
    if (_currentViewingSurahNumber != null) {
      await fetchSurahDetails(_currentViewingSurahNumber!);
    }
  }

  final Map<int, List<Ayah>> _cachedAyahs = {};

  Future<void> fetchSurahs() async {
    if (_surahs.isNotEmpty) return; // Don't reload if already loaded
    
    _isLoadingSurahs = true;
    notifyListeners();

    try {
      final String response = await rootBundle.loadString('assets/quran/surahs.json');
      // Use compute for parsing to keep UI responsive
      final List<dynamic> chapters = await compute(_decodeJson, response);
      
      _surahs = chapters.map((c) => Surah(
        number: c['id'],
        name: c['name'],
        englishName: c['transliteration'],
        englishNameTranslation: c['translation'],
        numberOfAyahs: c['total_verses'],
        revelationType: c['type'].toString().toUpperCase(),
      )).toList();
    } catch (e) {
      debugPrint('Error loading surahs from assets: $e');
    } finally {
      _isLoadingSurahs = false;
      notifyListeners();
    }
  }

  Future<void> saveLastRead(int surahNumber, String surahName, int ayahIndex) async {
    _lastReadSurahNumber = surahNumber;
    _lastReadSurahName = surahName;
    _lastReadAyahIndex = ayahIndex;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_read_surah', surahNumber);
    await prefs.setString('last_read_surah_name', surahName);
    await prefs.setInt('last_read_ayah', ayahIndex);
  }

  Future<void> fetchSurahDetails(int surahNumber) async {
    _currentViewingSurahNumber = surahNumber;
    
    if (_cachedAyahs.containsKey(surahNumber)) {
      _ayahs = _cachedAyahs[surahNumber]!;
      notifyListeners();
      return;
    }

    _isLoadingAyahs = true;
    _ayahs = [];
    notifyListeners();

    try {
      if (_cachedFullQuran == null) {
        final String response = await rootBundle.loadString('assets/quran/quran.json');
        _cachedFullQuran = await compute(_decodeJson, response);
      }
      
      final surahData = _cachedFullQuran!.firstWhere((s) => s['id'] == surahNumber);
      final List<dynamic> verses = surahData['verses'];
      
      final List<Ayah> allAyahs = verses.map((v) {
        int verseNum = v['id'];
        String sPad = surahNumber.toString().padLeft(3, '0');
        String vPad = verseNum.toString().padLeft(3, '0');
        String audioUrl = 'https://www.everyayah.com/data/$_selectedQari/$sPad$vPad.mp3';
        
        return Ayah(
          number: verseNum,
          text: v['text'], 
          numberInSurah: verseNum,
          juz: 0,
          audio: audioUrl,
        );
      }).toList();

      // Chunked loading to UI (3 by 3) for "streaming" effect
      for (int i = 0; i < allAyahs.length; i += 5) {
        int end = (i + 5 < allAyahs.length) ? i + 5 : allAyahs.length;
        _ayahs.addAll(allAyahs.sublist(i, end));
        notifyListeners();
        // Very small delay to allow UI to breathe and show the "stream"
        await Future.delayed(const Duration(milliseconds: 10));
      }

      _cachedAyahs[surahNumber] = allAyahs;
    } catch (e) {
      debugPrint('Error loading ayah details from assets: $e');
    } finally {
      _isLoadingAyahs = false;
      notifyListeners();
    }
  }

  Future<void> selectAyah(int index) async {
    // Just highlight — no scroll, no audio
    _highlightedAyahIndex = index;
    notifyListeners();
  }

  Future<void> togglePlayAyah(int index) async {
    _highlightedAyahIndex = index;
    if (_currentPlayingIndex == index && _audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      _currentPlayingIndex = index;
      notifyListeners();
      try {
        await _audioPlayer.setUrl(_ayahs[index].audio);
        await _audioPlayer.play();
      } catch (e) {
        debugPrint('Error playing audio: $e');
      }
    }
    notifyListeners();
  }

  Future<void> pauseAudio() async {
    await _audioPlayer.pause();
    notifyListeners();
  }

  Future<void> playAll() async {
    if (_ayahs.isEmpty) return;
    int startIndex = _highlightedAyahIndex ?? _currentPlayingIndex ?? 0;
    if (startIndex >= _ayahs.length) startIndex = 0;
    _currentPlayingIndex = startIndex;
    _highlightedAyahIndex = startIndex;
    try {
      await _audioPlayer.setUrl(_ayahs[startIndex].audio);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
    notifyListeners();
  }

  Future<void> playNextAyah() async {
    if (_currentPlayingIndex != null && _currentPlayingIndex! < _ayahs.length - 1) {
      _highlightedAyahIndex = _currentPlayingIndex! + 1;
      await togglePlayAyah(_currentPlayingIndex! + 1);
    } else {
      _currentPlayingIndex = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

// Top-level function for compute()
List<dynamic> _decodeJson(String response) {
  return json.decode(response) as List<dynamic>;
}
