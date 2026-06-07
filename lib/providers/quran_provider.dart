import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quran_model.dart';
import '../services/notification_service.dart';

class QuranProvider with ChangeNotifier {
  static AudioPlayer? activeQuranPlayer;
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

  // Hifz & Playback Speed Enhancements
  int _hifzLoopCount = 1;
  int _currentHifzRepetition = 1;
  int _hifzDelaySeconds = 0;
  double _playbackSpeed = 1.0;
  bool _isDelayActive = false;
  Timer? _delayTimer;

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
  int? get currentViewingSurahNumber => _currentViewingSurahNumber;
  int? get lastReadSurahNumber => _lastReadSurahNumber;
  String? get lastReadSurahName => _lastReadSurahName;
  int get lastReadAyahIndex => _lastReadAyahIndex;

  // Hifz & Speed Getters
  int get hifzLoopCount => _hifzLoopCount;
  int get currentHifzRepetition => _currentHifzRepetition;
  int get hifzDelaySeconds => _hifzDelaySeconds;
  double get playbackSpeed => _playbackSpeed;
  bool get isDelayActive => _isDelayActive;

  QuranProvider() {
    activeQuranPlayer = _audioPlayer;
    _loadSettings();
    _audioPlayer.playerStateStream.listen((state) {
      _playerState = state;
      if (state.processingState == ProcessingState.completed) {
        _handleAyahCompletion();
      }
      _updateSystemNotification();
      notifyListeners();
    });
  }

  void _updateSystemNotification() {
    if (_currentViewingSurahNumber != null && _ayahs.isNotEmpty && _currentPlayingIndex != null) {
      final surah = _surahs.firstWhere(
        (s) => s.number == _currentViewingSurahNumber, 
        orElse: () => _surahs.first
      );
      final verseNum = _ayahs[_currentPlayingIndex!].numberInSurah;
      final isPlaying = _audioPlayer.playing;
      
      NotificationService.showQuranPlaybackNotification(
        surahName: surah.englishName,
        verseNum: verseNum,
        isPlaying: isPlaying,
      );
    } else {
      NotificationService.cancelQuranNotification();
    }
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

    // Hifz & Speed Settings
    _hifzLoopCount = prefs.getInt('quran_hifz_loop_count') ?? 1;
    _hifzDelaySeconds = prefs.getInt('quran_hifz_delay_seconds') ?? 0;
    _playbackSpeed = prefs.getDouble('quran_playback_speed') ?? 1.0;
    await _audioPlayer.setSpeed(_playbackSpeed);

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

  // Hifz State Modifiers
  Future<void> updateHifzLoopCount(int count) async {
    _hifzLoopCount = count;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quran_hifz_loop_count', count);
  }

  Future<void> updateHifzDelaySeconds(int seconds) async {
    _hifzDelaySeconds = seconds;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quran_hifz_delay_seconds', seconds);
  }

  Future<void> updatePlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _audioPlayer.setSpeed(speed);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('quran_playback_speed', speed);
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

      // Chunked loading to UI (5 by 5) for "streaming" effect
      for (int i = 0; i < allAyahs.length; i += 5) {
        int end = (i + 5 < allAyahs.length) ? i + 5 : allAyahs.length;
        _ayahs.addAll(allAyahs.sublist(i, end));
        notifyListeners();
        // Very small delay to allow UI to breathe and show the "stream"
        await Future.delayed(const Duration(milliseconds: 10));
      }

      _cachedAyahs[surahNumber] = allAyahs;

      // Auto initialize current playing index to last read verse index or verse 1
      if (_currentPlayingIndex == null || _currentPlayingIndex! >= allAyahs.length) {
        _currentPlayingIndex = (_lastReadSurahNumber == surahNumber) ? _lastReadAyahIndex.clamp(0, allAyahs.length - 1) : 0;
        _highlightedAyahIndex = _currentPlayingIndex;
      }

      // Preload current audio in player for zero buffering feel
      if (_currentPlayingIndex != null && _currentPlayingIndex! < allAyahs.length) {
        final startUrl = allAyahs[_currentPlayingIndex!].audio;
        await _audioPlayer.setSpeed(_playbackSpeed);
        _audioPlayer.setUrl(startUrl, preload: true).catchError((e) {
          debugPrint('Preload error: $e');
          return null;
        });
        
        // Background prefetch next 2-3 verses
        _prefetchNextAyahs(_currentPlayingIndex!);
      }
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
    if (_currentViewingSurahNumber != null && _surahs.isNotEmpty) {
      final surah = _surahs.firstWhere(
        (s) => s.number == _currentViewingSurahNumber,
        orElse: () => _surahs.first,
      );
      saveLastRead(_currentViewingSurahNumber!, surah.englishName, index);
    }
    notifyListeners();
  }

  Future<void> togglePlayAyah(int index) async {
    _delayTimer?.cancel();
    _isDelayActive = false;
    _currentHifzRepetition = 1;
    _highlightedAyahIndex = index;
    
    if (_currentPlayingIndex == index && _audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      _currentPlayingIndex = index;
      notifyListeners();
      try {
        await _audioPlayer.setSpeed(_playbackSpeed);
        await _audioPlayer.setUrl(_ayahs[index].audio);
        await _audioPlayer.play();
        
        // Background prefetch next 2-3 verses
        _prefetchNextAyahs(index);

        if (_currentViewingSurahNumber != null && _surahs.isNotEmpty) {
          final surah = _surahs.firstWhere(
            (s) => s.number == _currentViewingSurahNumber,
            orElse: () => _surahs.first,
          );
          saveLastRead(_currentViewingSurahNumber!, surah.englishName, index);
        }
      } catch (e) {
        debugPrint('Error playing audio: $e');
      }
    }
    notifyListeners();
  }

  Future<void> pauseAudio() async {
    _delayTimer?.cancel();
    _isDelayActive = false;
    await _audioPlayer.pause();
    notifyListeners();
  }

  Future<void> playAll() async {
    if (_ayahs.isEmpty) return;
    _delayTimer?.cancel();
    _isDelayActive = false;
    _currentHifzRepetition = 1;
    
    int startIndex = _highlightedAyahIndex ?? _currentPlayingIndex ?? 0;
    if (startIndex >= _ayahs.length) startIndex = 0;
    _currentPlayingIndex = startIndex;
    _highlightedAyahIndex = startIndex;
    try {
      await _audioPlayer.setSpeed(_playbackSpeed);
      await _audioPlayer.setUrl(_ayahs[startIndex].audio);
      await _audioPlayer.play();
      
      // Background prefetch next 2-3 verses
      _prefetchNextAyahs(startIndex);
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
    notifyListeners();
  }

  Future<void> playNextAyah() async {
    _delayTimer?.cancel();
    _isDelayActive = false;
    _currentHifzRepetition = 1;
    
    if (_currentPlayingIndex != null && _currentPlayingIndex! < _ayahs.length - 1) {
      _highlightedAyahIndex = _currentPlayingIndex! + 1;
      await togglePlayAyah(_currentPlayingIndex! + 1);
    } else {
      _currentPlayingIndex = null;
      notifyListeners();
    }
  }

  // Hifz Completion Logic
  void _handleAyahCompletion() {
    if (_currentPlayingIndex == null || _ayahs.isEmpty) return;

    if (_currentHifzRepetition < _hifzLoopCount) {
      // Loop repetition active
      _currentHifzRepetition++;
      if (_hifzDelaySeconds > 0) {
        _startHifzDelay(true);
      } else {
        _replayCurrentAyah();
      }
    } else {
      // Repeat count reached. Move to next verse
      _currentHifzRepetition = 1;
      if (_currentPlayingIndex! < _ayahs.length - 1) {
        if (_hifzDelaySeconds > 0) {
          _startHifzDelay(false);
        } else {
          playNextAyah();
        }
      } else {
        _currentPlayingIndex = null;
        notifyListeners();
      }
    }
  }

  void _startHifzDelay(bool repeatCurrent) {
    _delayTimer?.cancel();
    _isDelayActive = true;
    notifyListeners();

    _delayTimer = Timer(Duration(seconds: _hifzDelaySeconds), () {
      _isDelayActive = false;
      if (repeatCurrent) {
        _replayCurrentAyah();
      } else {
        // Move to next ayah
        if (_currentPlayingIndex != null && _currentPlayingIndex! < _ayahs.length - 1) {
          _highlightedAyahIndex = _currentPlayingIndex! + 1;
          togglePlayAyah(_currentPlayingIndex! + 1);
        }
      }
    });
  }

  Future<void> _replayCurrentAyah() async {
    if (_currentPlayingIndex == null || _ayahs.isEmpty) return;
    try {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.setSpeed(_playbackSpeed);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error replaying ayah: $e');
    }
    notifyListeners();
  }

  // Background Prefetcher for Gapless Playback feel
  void _prefetchNextAyahs(int currentIndex) {
    if (_ayahs.isEmpty) return;
    
    // Prefetch next 3 ayahs asynchronously
    for (int i = 1; i <= 3; i++) {
      int nextIndex = currentIndex + i;
      if (nextIndex < _ayahs.length) {
        final url = _ayahs[nextIndex].audio;
        _prefetchUrl(url);
      }
    }
  }

  Future<void> _prefetchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final request = await HttpClient().getUrl(uri);
      final response = await request.close();
      if (response.statusCode == 200) {
        // Read response body fully in the background to warm OS caching layer
        await response.drain();
        debugPrint('Prefetched and cached: $url');
      }
    } catch (e) {
      debugPrint('Prefetch failed: $e');
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _audioPlayer.dispose();
    NotificationService.cancelQuranNotification();
    super.dispose();
  }
}

// Top-level function for compute()
List<dynamic> _decodeJson(String response) {
  return json.decode(response) as List<dynamic>;
}
