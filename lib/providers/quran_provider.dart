import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/juz_model.dart';
import '../models/qari_model.dart';
import '../models/quran_edition_model.dart';
import '../models/quran_model.dart';
import '../services/alquran_service.dart';
import '../services/notification_service.dart';
import '../services/quran_audio_cache_service.dart';

class QuranProvider with ChangeNotifier {
  static AudioPlayer? activeQuranPlayer;
  List<Surah> _surahs = [];
  bool _isLoadingSurahs = false;
  List<JuzModel> _juzs = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  List<Ayah> _ayahs = [];
  bool _isLoadingAyahs = false;
  List<dynamic>? _cachedFullQuran;
  final Map<int, List<Ayah>> _cachedAyahs = {};
  
  int? _currentPlayingIndex;
  int? _highlightedAyahIndex;
  PlayerState? _playerState;
  double _fontSize = 30.0;
  double _autoScrollSpeed = 30.0;
  
  // Qari & QuranicAudio Integration
  List<Qari> _qaris = [];
  Qari? _selectedQariObj;
  String _selectedQari = 'Alafasy_128kbps';
  bool _isLoadingQaris = false;

  int? _currentViewingSurahNumber;
  Set<int> _bookmarkedSurahNumbers = {};

  // Hifz & Playback Speed Enhancements
  int _hifzLoopCount = 1;
  int _currentHifzRepetition = 1;
  int _hifzDelaySeconds = 0;
  double _playbackSpeed = 1.0;
  bool _isDelayActive = false;
  bool _isChangingTrack = false;
  int? _lastHandledCompletionIndex;
  int? _lastHandledCompletionSurah;
  Timer? _delayTimer;

  // Fallback Popular Qaris List (offline out-of-the-box ready)
  static final List<Qari> defaultQaris = [
    const Qari(id: 5, name: 'Mishari Rashid al-`Afasy', arabicName: 'مشاري راشد العفاسي', relativePath: 'mishaari_raashid_al_3afaasee/'),
    const Qari(id: 7, name: 'Abdur-Rahman as-Sudais', arabicName: 'عبدالرحمن السديس', relativePath: 'abdurrahmaan_as-sudays/'),
    const Qari(id: 6, name: 'Muhammad Siddiq al-Minshawi', arabicName: 'محمد صديق المنشاوي', relativePath: 'muhammad_siddeeq_al-minshaawee/'),
    const Qari(id: 3, name: 'Abu Bakr al-Shatri', arabicName: 'أبو بكر الشاطرى', relativePath: 'abu_bakr_ash-shaatree/'),
    const Qari(id: 4, name: 'Sa`ud ash-Shuraym', arabicName: 'سعود الشريم', relativePath: 'sa3ood_al-shuraym/'),
    const Qari(id: 1, name: 'Abdullah Awad al-Juhani', arabicName: 'عبدالله عواد الجهني', relativePath: 'abdullaah_3awwaad_al-juhaynee/'),
    const Qari(id: 2, name: 'Abdullah Basfar', arabicName: 'عبدالله بصفر', relativePath: 'abdullaah_basfar/'),
    const Qari(id: 8, name: 'Saad al-Ghamdi', arabicName: 'سعد الغامدي', relativePath: 'sa3d_al-ghaamidee/'),
    const Qari(id: 9, name: 'Maher al-Muaiqly', arabicName: 'ماهر المعيقلي', relativePath: 'maahir_al-mu3ayqlee/'),
    const Qari(id: 10, name: 'Ali al-Hudhaifi', arabicName: 'علي بن عبدالرحمن الحذيفي', relativePath: '3alee_al_hudhayfee/'),
    const Qari(id: 11, name: 'Yasser al-Dosari', arabicName: 'ياسر الدوسري', relativePath: 'yaasir_ad-dawsaree/'),
    const Qari(id: 12, name: 'Mahmoud Khalil al-Husary', arabicName: 'محمود خليل الحصري', relativePath: 'mahmood_khaleel_al-husaree/'),
    const Qari(id: 13, name: 'Abdul-Basit Abdus-Samad', arabicName: 'عبدالباسط عبدالصمد', relativePath: 'abdul_baasit_murattal/'),
    const Qari(id: 14, name: 'Hani ar-Rifai', arabicName: 'هاني الرفاعي', relativePath: 'haanee_ar-rifaa3ee/'),
    const Qari(id: 15, name: 'Khalid al-Qahtani', arabicName: 'خالد القحطاني', relativePath: 'khaalid_al-qahtaanee/'),
    const Qari(id: 16, name: 'Nasser al-Qatami', arabicName: 'ناصر القطامي', relativePath: 'naasir_al-qatamee/'),
    const Qari(id: 17, name: 'Salah Bukhatir', arabicName: 'صلاح بو خاطر', relativePath: 'salah_bukhatir/'),
    const Qari(id: 18, name: 'Bandar Baleela', arabicName: 'بندر بليلة', relativePath: 'bandar_baleela/'),
  ];

  static Map<String, String> get availableQaris {
    final map = <String, String>{};
    for (final q in defaultQaris) {
      map[q.relativePath] = q.name;
    }
    return map;
  }

  // Last read tracking
  int? _lastReadSurahNumber;
  String? _lastReadSurahName;
  int _lastReadAyahIndex = 0;

  List<Surah> get surahs => _surahs;
  bool get isLoadingSurahs => _isLoadingSurahs;
  List<JuzModel> get juzs => _juzs;
  List<Ayah> get ayahs => _ayahs;
  bool get isLoadingAyahs => _isLoadingAyahs;
  int? get currentPlayingIndex => _currentPlayingIndex;
  int? get highlightedAyahIndex => _highlightedAyahIndex;
  PlayerState? get playerState => _playerState;
  Duration? get currentAudioDuration => _audioPlayer.duration;
  double get fontSize => _fontSize;
  double get autoScrollSpeed => _autoScrollSpeed;
  String get selectedQari => _selectedQari;
  List<Qari> get qaris => _qaris.isNotEmpty ? _qaris : defaultQaris;
  Qari get selectedQariObj => _selectedQariObj ?? defaultQaris.first;
  bool get isLoadingQaris => _isLoadingQaris;

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
  bool get isChangingTrack => _isChangingTrack;
  bool get isAudioLoading =>
      _isChangingTrack ||
      _playerState?.processingState == ProcessingState.loading ||
      _playerState?.processingState == ProcessingState.buffering;
  AudioPlayer get audioPlayer => _audioPlayer;

  QuranProvider() {
    activeQuranPlayer = _audioPlayer;
    _loadSettings();
    fetchQaris();
    _audioPlayer.playerStateStream.listen((state) {
      _playerState = state;
      if (!_isChangingTrack && state.processingState == ProcessingState.completed) {
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

  Future<void> fetchQaris() async {
    try {
      final String raw = await rootBundle.loadString('assets/quran/qaris.json');
      final List<dynamic> list = json.decode(raw) as List<dynamic>;
      _qaris = list.map((e) => Qari.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading qaris from assets: $e');
      _qaris = defaultQaris;
    } finally {
      _syncSelectedQariObject();
      _isLoadingQaris = false;
      notifyListeners();
    }
  }

  void _syncSelectedQariObject() {
    final list = _qaris.isNotEmpty ? _qaris : defaultQaris;
    try {
      _selectedQariObj = list.firstWhere(
        (q) => q.relativePath == _selectedQari || q.name.toLowerCase().contains(_selectedQari.toLowerCase()),
      );
    } catch (_) {
      _selectedQariObj = list.first;
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble('quran_font_size') ?? 30.0;
    _autoScrollSpeed = prefs.getDouble('quran_auto_scroll_speed') ?? 30.0;
    _selectedQari = prefs.getString('quran_selected_qari') ?? 'mishaari_raashid_al_3afaasee/';
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

    _syncSelectedQariObject();
    notifyListeners();
  }

  Future<void> updateQariObject(Qari qari) async {
    final wasPlaying = _audioPlayer.playing;
    final currentAyah = _currentPlayingIndex ?? 0;

    _delayTimer?.cancel();
    _isDelayActive = false;
    _isChangingTrack = true;

    // Immediately stop old audio player stream
    try {
      await _audioPlayer.stop();
    } catch (_) {}

    _selectedQariObj = qari;
    _selectedQari = qari.relativePath;
    _cachedAyahs.clear();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quran_selected_qari', qari.relativePath);

    if (_currentViewingSurahNumber != null) {
      await fetchSurahDetails(_currentViewingSurahNumber!, initialIndex: currentAyah);

      // If audio was playing, immediately switch to and play the new Qari's stream!
      if (wasPlaying && _ayahs.isNotEmpty) {
        final targetIndex = currentAyah.clamp(0, _ayahs.length - 1);
        await playAyahDirectly(targetIndex);
      }
    }
  }

  Future<void> updateQari(String newQariId) async {
    final wasPlaying = _audioPlayer.playing;
    final currentAyah = _currentPlayingIndex ?? 0;

    _delayTimer?.cancel();
    _isDelayActive = false;
    _isChangingTrack = true;

    try {
      await _audioPlayer.stop();
    } catch (_) {}

    _selectedQari = newQariId;
    _syncSelectedQariObject();
    _cachedAyahs.clear();
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quran_selected_qari', newQariId);
    
    if (_currentViewingSurahNumber != null) {
      await fetchSurahDetails(_currentViewingSurahNumber!, initialIndex: currentAyah);

      // If audio was playing, instantly switch to and play the new Qari's stream!
      if (wasPlaying && _ayahs.isNotEmpty) {
        final targetIndex = currentAyah.clamp(0, _ayahs.length - 1);
        await playAyahDirectly(targetIndex);
      }
    }
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

  Future<void> updateHifzSettings(int loopCount, int delaySeconds) async {
    _hifzLoopCount = loopCount;
    _hifzDelaySeconds = delaySeconds;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quran_hifz_loop_count', loopCount);
    await prefs.setInt('quran_hifz_delay_seconds', delaySeconds);
  }

  Future<void> updatePlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _audioPlayer.setSpeed(speed);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('quran_playback_speed', speed);
  }

  Future<void> fetchSurahs() async {
    if (_surahs.isNotEmpty) return;
    
    _isLoadingSurahs = true;
    notifyListeners();

    try {
      if (_cachedFullQuran == null) {
        final String response = await rootBundle.loadString('assets/quran/quran.json');
        _cachedFullQuran = json.decode(response) as List<dynamic>;
      }
      
      _surahs = _cachedFullQuran!
          .map((s) => Surah.fromJson(s as Map<dynamic, dynamic>))
          .toList();

      if (_juzs.isEmpty) {
        try {
          final String juzRaw = await rootBundle.loadString('assets/quran/juzs.json');
          final List<dynamic> jList = json.decode(juzRaw) as List<dynamic>;
          _juzs = jList.map((j) => JuzModel.fromJson(j as Map<dynamic, dynamic>)).toList();
        } catch (_) {}
      }
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

  String getSurahAudioUrl(int surahNumber) {
    if (_selectedQariObj != null) {
      return _selectedQariObj!.getSurahAudioUrl(surahNumber);
    }
    final sPad = surahNumber.toString().padLeft(3, '0');
    return 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/$sPad.mp3';
  }

  static const List<int> _surahVerseCounts = [
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
    112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45, 83, 182, 88, 75, 85,
    54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
    14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
    29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
    11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6
  ];

  static int getGlobalAyahNumber(int surahNumber, int verseInSurah) {
    if (surahNumber < 1 || surahNumber > 114) return verseInSurah;
    int offset = 0;
    for (int i = 0; i < surahNumber - 1; i++) {
      offset += _surahVerseCounts[i];
    }
    return offset + verseInSurah;
  }

  Future<void> fetchSurahDetails(int surahNumber, {int? initialIndex}) async {
    _currentViewingSurahNumber = surahNumber;
    
    if (_cachedAyahs.containsKey(surahNumber)) {
      _ayahs = _cachedAyahs[surahNumber]!;
      if (initialIndex != null && initialIndex >= 0 && initialIndex < _ayahs.length) {
        _currentPlayingIndex = initialIndex;
        _highlightedAyahIndex = initialIndex;
      }
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
      
      final qari = selectedQariObj;

      final List<Ayah> allAyahs = verses.map((v) {
        int verseNum = v['id'];
        int globalNumber = getGlobalAyahNumber(surahNumber, verseNum);
        String audioUrl = qari.getAyahAudioUrl(surahNumber, verseNum, globalNumber: globalNumber);
        
        return Ayah(
          number: globalNumber,
          text: v['text'] ?? '', 
          numberInSurah: verseNum,
          juz: v['juz'] ?? 1,
          audio: audioUrl,
          translationEn: v['translation'] ?? '',
          translationMl: v['translation_ml'] ?? '',
        );
      }).toList();

      _ayahs = allAyahs;
      _cachedAyahs[surahNumber] = allAyahs;

      if (initialIndex != null && initialIndex >= 0 && initialIndex < allAyahs.length) {
        _currentPlayingIndex = initialIndex;
        _highlightedAyahIndex = initialIndex;
      } else if (_currentPlayingIndex == null || _currentPlayingIndex! >= allAyahs.length) {
        _currentPlayingIndex = (_lastReadSurahNumber == surahNumber) ? _lastReadAyahIndex.clamp(0, allAyahs.length - 1) : 0;
        _highlightedAyahIndex = _currentPlayingIndex;
      }

      notifyListeners();

      if (_currentPlayingIndex != null && _currentPlayingIndex! < allAyahs.length) {
        QuranAudioCacheService.preloadUpcomingAyahs(
          qari: qari,
          surahNumber: surahNumber,
          currentAyahIndex: _currentPlayingIndex! - 1,
          ayahs: allAyahs,
          count: 4,
        );
      }
    } catch (e) {
      debugPrint('Error loading ayah details from assets: $e');
    } finally {
      _isLoadingAyahs = false;
      notifyListeners();
    }
  }

  Future<void> selectAyah(int index) async {
    _highlightedAyahIndex = index;
    if (_currentViewingSurahNumber != null && _surahs.isNotEmpty) {
      final surah = _surahs.firstWhere(
        (s) => s.number == _currentViewingSurahNumber,
        orElse: () => _surahs.first,
      );
      saveLastRead(_currentViewingSurahNumber!, surah.englishName, index);
    }
    notifyListeners();
    await playAyahDirectly(index);
  }

  Future<void> togglePlayAyah(int index) async {
    if (_currentPlayingIndex == index && _audioPlayer.playing) {
      await _audioPlayer.pause();
      notifyListeners();
    } else {
      await playAyahDirectly(index);
    }
  }

  Future<void> playAyahDirectly(int index) async {
    if (_ayahs.isEmpty || index < 0 || index >= _ayahs.length) return;

    _delayTimer?.cancel();
    _isDelayActive = false;
    _currentHifzRepetition = 1;
    _highlightedAyahIndex = index;
    _currentPlayingIndex = index;
    _isChangingTrack = true;
    notifyListeners();

    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
      }
      await _audioPlayer.setSpeed(_playbackSpeed);

      final surahNum = _currentViewingSurahNumber ?? 1;
      final verseNum = _ayahs[index].numberInSurah;
      final cachedPath = QuranAudioCacheService.getCachedFilePath(
        selectedQariObj.relativePath,
        surahNum,
        verseNum,
      );

      if (cachedPath != null) {
        // Instant 0ms playback from local cache
        await _audioPlayer.setFilePath(cachedPath);
      } else {
        final targetUrl = _ayahs[index].audio;
        try {
          await _audioPlayer.setUrl(targetUrl);
        } catch (e) {
          final errStr = e.toString().toLowerCase();
          if (!errStr.contains('abort') && !errStr.contains('cancel')) {
            debugPrint('Primary ayah audio failed, trying fallback: $e');
            final sPad = surahNum.toString().padLeft(3, '0');
            final vPad = verseNum.toString().padLeft(3, '0');
            final dir = selectedQariObj.getAyahDirectory();
            await _audioPlayer.setUrl('https://everyayah.com/data/$dir/$sPad$vPad.mp3');
          }
        }
      }
      _isChangingTrack = false;
      await _audioPlayer.play();
      
      // Fast non-blocking background pre-fetch for next 5 ayahs!
      QuranAudioCacheService.preloadUpcomingAyahs(
        qari: selectedQariObj,
        surahNumber: surahNum,
        currentAyahIndex: index,
        ayahs: _ayahs,
        count: 5,
      );

      if (_currentViewingSurahNumber != null && _surahs.isNotEmpty) {
        final surah = _surahs.firstWhere(
          (s) => s.number == _currentViewingSurahNumber,
          orElse: () => _surahs.first,
        );
        saveLastRead(_currentViewingSurahNumber!, surah.englishName, index);
      }
    } catch (e) {
      _isChangingTrack = false;
      final errStr = e.toString().toLowerCase();
      if (!errStr.contains('abort') && !errStr.contains('cancel')) {
        debugPrint('Error playing audio: $e');
      }
    }
    notifyListeners();
  }

  Future<void> playSurahFullAudio(int surahNumber) async {
    final primaryUrl = getSurahAudioUrl(surahNumber);
    try {
      _isChangingTrack = true;
      await _audioPlayer.setSpeed(_playbackSpeed);
      try {
        await _audioPlayer.setUrl(primaryUrl);
      } catch (err) {
        debugPrint('QuranicAudio primary stream failed, trying fallback: $err');
        final sPad = surahNumber.toString().padLeft(3, '0');
        await _audioPlayer.setUrl('https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/$sPad.mp3');
      }
      _isChangingTrack = false;
      await _audioPlayer.play();
    } catch (e) {
      _isChangingTrack = false;
      debugPrint('Error playing full surah audio: $e');
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
    _isChangingTrack = true;
    _currentPlayingIndex = startIndex;
    _highlightedAyahIndex = startIndex;
    try {
      await _audioPlayer.setSpeed(_playbackSpeed);
      await _audioPlayer.setUrl(_ayahs[startIndex].audio);
      _isChangingTrack = false;
      await _audioPlayer.play();
      
      _prefetchNextAyahs(startIndex);
    } catch (e) {
      _isChangingTrack = false;
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
      await playAyahDirectly(_currentPlayingIndex! + 1);
    } else {
      await _playNextSurah();
    }
  }

  Future<void> playPreviousAyah() async {
    _delayTimer?.cancel();
    _isDelayActive = false;
    _currentHifzRepetition = 1;

    if (_currentPlayingIndex != null && _currentPlayingIndex! > 0) {
      _highlightedAyahIndex = _currentPlayingIndex! - 1;
      await playAyahDirectly(_currentPlayingIndex! - 1);
    } else if (_currentViewingSurahNumber != null && _currentViewingSurahNumber! > 1) {
      _isChangingTrack = true;
      _lastHandledCompletionIndex = null;
      _lastHandledCompletionSurah = null;
      final prevSurahNum = _currentViewingSurahNumber! - 1;
      await fetchSurahDetails(prevSurahNum);
      final lastIndex = _ayahs.isNotEmpty ? _ayahs.length - 1 : 0;
      _currentPlayingIndex = lastIndex;
      _highlightedAyahIndex = lastIndex;
      notifyListeners();
      await playAyahDirectly(lastIndex);
    }
  }

  Future<void> _playNextSurah() async {
    if (_currentViewingSurahNumber != null && _currentViewingSurahNumber! < 114) {
      _isChangingTrack = true;
      _lastHandledCompletionIndex = null;
      _lastHandledCompletionSurah = null;
      _currentPlayingIndex = 0;
      _highlightedAyahIndex = 0;
      
      final nextSurahNum = _currentViewingSurahNumber! + 1;
      await fetchSurahDetails(nextSurahNum);
      _currentPlayingIndex = 0;
      _highlightedAyahIndex = 0;
      notifyListeners();
      await playAyahDirectly(0);
    } else {
      _currentPlayingIndex = null;
      notifyListeners();
    }
  }

  // Hifz Completion Logic
  void _handleAyahCompletion() {
    if (_isChangingTrack || _currentPlayingIndex == null || _ayahs.isEmpty) return;

    final currentSurah = _currentViewingSurahNumber;
    if (_lastHandledCompletionIndex == _currentPlayingIndex &&
        _lastHandledCompletionSurah == currentSurah &&
        _currentHifzRepetition >= _hifzLoopCount) {
      return;
    }

    if (_currentHifzRepetition < _hifzLoopCount) {
      _currentHifzRepetition++;
      if (_hifzDelaySeconds > 0) {
        _startHifzDelay(true);
      } else {
        _replayCurrentAyah();
      }
    } else {
      _lastHandledCompletionIndex = _currentPlayingIndex;
      _lastHandledCompletionSurah = currentSurah;
      _currentHifzRepetition = 1;
      if (_currentPlayingIndex! < _ayahs.length - 1) {
        if (_hifzDelaySeconds > 0) {
          _startHifzDelay(false);
        } else {
          playNextAyah();
        }
      } else {
        // Current Surah completed -> automatically transition to next Surah starting at Ayah 0!
        _playNextSurah();
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
        if (_currentPlayingIndex != null && _currentPlayingIndex! < _ayahs.length - 1) {
          _highlightedAyahIndex = _currentPlayingIndex! + 1;
          playAyahDirectly(_currentPlayingIndex! + 1);
        } else {
          _playNextSurah();
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

  void _prefetchNextAyahs(int currentIndex) {
    if (_ayahs.isEmpty) return;
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
        await response.drain();
      }
    } catch (e) {
      debugPrint('Prefetch failed: $e');
    }
  }

  Future<void> seekForward10() async {
    final current = _audioPlayer.position;
    final total = _audioPlayer.duration ?? const Duration(seconds: 30);
    final target = current + const Duration(seconds: 10);
    await _audioPlayer.seek(target < total ? target : total);
    notifyListeners();
  }

  Future<void> seekBackward10() async {
    final current = _audioPlayer.position;
    final target = current - const Duration(seconds: 10);
    await _audioPlayer.seek(target > Duration.zero ? target : Duration.zero);
    notifyListeners();
  }

  /// Search Quran text across all Ayahs or within a specific Surah (AlQuran Cloud API)
  Future<List<QuranSearchResult>> searchQuran(
    String query, {
    String edition = 'en.sahih',
    int? surahNumber,
  }) async {
    return await AlQuranService.searchQuran(query, edition: edition, surahNumber: surahNumber);
  }

  /// Fetch all Sajda (prostration) Ayahs (AlQuran Cloud API)
  Future<List<SajdaInfo>> fetchSajdas({String edition = 'quran-uthmani'}) async {
    return await AlQuranService.fetchSajdas(edition: edition);
  }

  /// Fetch available editions / translations (AlQuran Cloud API)
  Future<List<QuranEdition>> fetchAvailableEditions({String? language, String? format, String? type}) async {
    return await AlQuranService.fetchEditions(language: language, format: format, type: type);
  }



  @override
  void dispose() {
    _delayTimer?.cancel();
    _audioPlayer.dispose();
    NotificationService.cancelQuranNotification();
    super.dispose();
  }
}

List<dynamic> _decodeJson(String response) {
  return json.decode(response) as List<dynamic>;
}
