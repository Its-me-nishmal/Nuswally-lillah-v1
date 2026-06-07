import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_model.dart';
import '../models/prayer_time_model.dart';
import '../services/data_service.dart';
import 'quran_provider.dart';
import '../services/notification_service.dart';

class PrayerProvider with ChangeNotifier {
  final DataService _dataService = DataService();
  final AudioPlayer _alertPlayer = AudioPlayer();
  final Set<String> _triggeredAlerts = {};
  final Set<String> _temporarilyMutedAlerts = {};

  Set<String> get temporarilyMutedAlerts => _temporarilyMutedAlerts;

  void toggleTemporaryMute(String prayerName) {
    if (_temporarilyMutedAlerts.contains(prayerName)) {
      _temporarilyMutedAlerts.remove(prayerName);
    } else {
      _temporarilyMutedAlerts.add(prayerName);
    }
    notifyListeners();
    _scheduleNativeAlarms();
  }
  
  List<District> _districts = [];
  Location? _selectedLocation;
  LocationData? _currentLocationData;
  PrayerTime? _todayPrayerTimes;
  String _nextPrayerName = '';
  Duration _timeToNextPrayer = Duration.zero;
  bool _isPrayerActive = false;
  String _activePrayerName = '';
  bool _isLocationSet = false;
  bool _hasShownLocationSelection = false;
  Timer? _countdownTimer;
  bool _isInitialized = false;
  
  bool _showUpcomingAlertBanner = false;
  int _upcomingAlertMinutesRemaining = 0;
  int _upcomingAlertSecondsRemaining = 0;
  String _highlightedPrayerName = '';

  bool get isInitialized => _isInitialized;
  bool get showUpcomingAlertBanner => _showUpcomingAlertBanner;
  int get upcomingAlertMinutesRemaining => _upcomingAlertMinutesRemaining;
  int get upcomingAlertSecondsRemaining => _upcomingAlertSecondsRemaining;
  String get highlightedPrayerName => _highlightedPrayerName;

  final Map<String, int> _iqamahOffsets = {
    'Fajr': 20,
    'Dhuhr': 20,
    'Asr': 20,
    'Maghrib': 5,
    'Isha': 20,
  };

  final Map<String, String> _adhanNotificationSounds = {
    'Fajr': 'Full Adhan',
    'Dhuhr': 'Full Adhan',
    'Asr': 'Full Adhan',
    'Maghrib': 'Full Adhan',
    'Isha': 'Full Adhan',
  };

  final Map<String, int> _adhanNotificationOffsets = {
    'Fajr': 0,
    'Dhuhr': 0,
    'Asr': 0,
    'Maghrib': 0,
    'Isha': 0,
  };

  final Map<String, String> _iqamahNotificationSounds = {
    'Fajr': 'Chime',
    'Dhuhr': 'Chime',
    'Asr': 'Chime',
    'Maghrib': 'Chime',
    'Isha': 'Chime',
  };

  final Map<String, int> _iqamahNotificationOffsets = {
    'Fajr': 3,
    'Dhuhr': 3,
    'Asr': 3,
    'Maghrib': 3,
    'Isha': 3,
  };

  List<District> get districts => _districts;
  Location? get selectedLocation => _selectedLocation;
  LocationData? get currentLocationData => _currentLocationData;
  PrayerTime? get todayPrayerTimes => _todayPrayerTimes;
  String get nextPrayerName => _nextPrayerName;
  Duration get timeToNextPrayer => _timeToNextPrayer;
  bool get isPrayerActive => _isPrayerActive;
  String get activePrayerName => _activePrayerName;
  bool get hasLocationSet => _isLocationSet;
  bool get hasShownLocationSelection => _hasShownLocationSelection;
  Map<String, int> get iqamahOffsets => _iqamahOffsets;
  Map<String, String> get adhanNotificationSounds => _adhanNotificationSounds;
  Map<String, int> get adhanNotificationOffsets => _adhanNotificationOffsets;
  Map<String, String> get iqamahNotificationSounds => _iqamahNotificationSounds;
  Map<String, int> get iqamahNotificationOffsets => _iqamahNotificationOffsets;
  bool get isAlertSoundPlaying => _alertPlayer.playing;

  PrayerProvider() {
    _init();
  }

  Future<void> _init() async {
    NotificationService.onActionClicked = (actionId, payload) {
      if (actionId == 'mute_upcoming') {
        toggleTemporaryMute(payload);
      } else if (actionId == 'stop_active') {
        stopAlertSound();
      } else if (actionId == 'pause_quran') {
        QuranProvider.activeQuranPlayer?.pause();
      } else if (actionId == 'play_quran') {
        QuranProvider.activeQuranPlayer?.play();
      } else if (actionId == 'stop_quran') {
        QuranProvider.activeQuranPlayer?.stop();
      }
    };

    _alertPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed || !state.playing) {
        NotificationService.cancelActive();
      }
      notifyListeners();
    });
    _districts = await _dataService.loadDistricts();
    await _loadSavedLocation();
    await _loadLocationAskedStatus();
    await _loadIqamahOffsets();
    await _loadNotificationSettings();
    _startCountdown();
    await _scheduleNativeAlarms();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadIqamahOffsets() async {
    final prefs = await SharedPreferences.getInstance();
    _iqamahOffsets['Fajr'] = prefs.getInt('iqamah_Fajr') ?? 20;
    _iqamahOffsets['Dhuhr'] = prefs.getInt('iqamah_Dhuhr') ?? 20;
    _iqamahOffsets['Asr'] = prefs.getInt('iqamah_Asr') ?? 20;
    _iqamahOffsets['Maghrib'] = prefs.getInt('iqamah_Maghrib') ?? 5;
    _iqamahOffsets['Isha'] = prefs.getInt('iqamah_Isha') ?? 20;
    notifyListeners();
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    const prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    
    for (var prayer in prayers) {
      _adhanNotificationSounds[prayer] = prefs.getString('adhan_sound_$prayer') ?? 'Full Adhan';
      _adhanNotificationOffsets[prayer] = prefs.getInt('adhan_offset_$prayer') ?? 0;
      _iqamahNotificationSounds[prayer] = prefs.getString('iqamah_sound_$prayer') ?? 'Chime';
      _iqamahNotificationOffsets[prayer] = prefs.getInt('iqamah_offset_$prayer') ?? 3;
    }
    notifyListeners();
  }

  Future<void> updateIqamahOffset(String prayerName, int offsetMinutes) async {
    _iqamahOffsets[prayerName] = offsetMinutes;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('iqamah_$prayerName', offsetMinutes);
    await _scheduleNativeAlarms();
  }

  Future<void> updateAdhanSound(String prayerName, String sound) async {
    _adhanNotificationSounds[prayerName] = sound;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('adhan_sound_$prayerName', sound);
    await _scheduleNativeAlarms();
  }

  Future<void> updateAdhanOffset(String prayerName, int offsetMinutes) async {
    _adhanNotificationOffsets[prayerName] = offsetMinutes;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('adhan_offset_$prayerName', offsetMinutes);
    await _scheduleNativeAlarms();
  }

  Future<void> updateIqamahNotificationSound(String prayerName, String sound) async {
    _iqamahNotificationSounds[prayerName] = sound;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('iqamah_sound_$prayerName', sound);
    await _scheduleNativeAlarms();
  }

  Future<void> updateIqamahNotificationOffset(String prayerName, int offsetMinutes) async {
    _iqamahNotificationOffsets[prayerName] = offsetMinutes;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('iqamah_offset_$prayerName', offsetMinutes);
    await _scheduleNativeAlarms();
  }

  String getIqamahTime(String prayerName, String adhanTimeStr) {
    if (prayerName == 'Sunrise') return '';
    
    final offset = _iqamahOffsets[prayerName] ?? 20;
    
    try {
      final parts = adhanTimeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      final now = DateTime.now();
      final adhanDT = DateTime(now.year, now.month, now.day, hour, minute);
      final iqamahDT = adhanDT.add(Duration(minutes: offset));
      
      return DateFormat('HH:mm').format(iqamahDT);
    } catch (e) {
      return adhanTimeStr;
    }
  }

  Future<void> _loadLocationAskedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _hasShownLocationSelection = prefs.getBool('has_shown_location_selection') ?? false;
  }

  Future<void> markLocationAsAsked() async {
    _hasShownLocationSelection = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_shown_location_selection', true);
    notifyListeners();
  }

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getInt('selected_location_id');
    
    if (savedId != null) {
      for (var district in _districts) {
        for (var loc in district.locations) {
          if (loc.id == savedId) {
            _selectedLocation = loc;
            _currentLocationData = await _dataService.loadLocationData(loc.id);
            _updateTodayPrayerTimes();
            _isLocationSet = true;
            return;
          }
        }
      }
    }
    _isLocationSet = false;
  }

  Future<void> selectLocation(Location location) async {
    _selectedLocation = location;
    _currentLocationData = await _dataService.loadLocationData(location.id);
    _updateTodayPrayerTimes();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_location_id', location.id);
    
    _isLocationSet = true;
    _hasShownLocationSelection = true;
    await prefs.setBool('has_shown_location_selection', true);
    
    _calculateNextPrayerFixed();
    await _scheduleNativeAlarms();
    notifyListeners();
  }

  void _updateTodayPrayerTimes() {
    if (_currentLocationData == null) return;

    final now = DateTime.now();
    final todayStr = DateFormat('MM-dd').format(now);
    
    try {
      _todayPrayerTimes = _currentLocationData!.prayerTimes.firstWhere(
        (element) => element.date == todayStr,
      );
    } catch (e) {
      // If date not found (e.g. leap year issues), take the first one or handle appropriately
      _todayPrayerTimes = _currentLocationData!.prayerTimes[0];
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateNextPrayerFixed();
      notifyListeners();
    });
  }

  void _calculateNextPrayerFixed() {
    if (_todayPrayerTimes == null) return;

    final now = DateTime.now();
    
    DateTime getDT(String timeStr, int hourOffset) {
      final parts = timeStr.split(':');
      var h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      
      // Special case for Dhuhr: if it's 12:xx, it's PM but doesn't need +12
      // If it's 1:xx, it needs +12.
      if (hourOffset > 0) {
        if (h < 12) h += hourOffset;
      }
      
      return DateTime(now.year, now.month, now.day, h, m);
    }

    final fajr = getDT(_todayPrayerTimes!.fajr, 0);
    final sunrise = getDT(_todayPrayerTimes!.sunrise, 0);
    
    // Dhuhr handling
    var dhuhrH = int.parse(_todayPrayerTimes!.dhuhr.split(':')[0]);
    final dhuhr = getDT(_todayPrayerTimes!.dhuhr, dhuhrH < 11 ? 12 : 0);
    
    final asr = getDT(_todayPrayerTimes!.asr, 12);
    final maghrib = getDT(_todayPrayerTimes!.maghrib, 12);
    final isha = getDT(_todayPrayerTimes!.isha, 12);

    final List<MapEntry<String, DateTime>> times = [
      MapEntry('Fajr', fajr),
      MapEntry('Sunrise', sunrise),
      MapEntry('Dhuhr', dhuhr),
      MapEntry('Asr', asr),
      MapEntry('Maghrib', maghrib),
      MapEntry('Isha', isha),
    ];

    String nextName = '';
    DateTime? nextTime;

    for (var entry in times) {
      if (entry.value.isAfter(now)) {
        nextName = entry.key;
        nextTime = entry.value;
        break;
      }
    }

    if (nextTime == null) {
      nextName = 'Fajr';
      nextTime = fajr.add(const Duration(days: 1));
    }

    _nextPrayerName = nextName;
    _timeToNextPrayer = nextTime.difference(now);

    // --- SYSTEM NOTIFICATION DRAWER SYNC & UPCOMING ALERT BANNER ---
    final nextOffset = _adhanNotificationOffsets[_nextPrayerName] ?? 0;
    final nextAlarmTime = nextTime.subtract(Duration(minutes: nextOffset));
    final nextAlarmDiffSec = nextAlarmTime.difference(now).inSeconds;

    _showUpcomingAlertBanner = false;
    _upcomingAlertMinutesRemaining = 0;
    _upcomingAlertSecondsRemaining = 0;

    if (nextAlarmDiffSec > 0 && nextAlarmDiffSec <= 600) {
      final adhanSound = _adhanNotificationSounds[_nextPrayerName] ?? 'Default Alert';
      if (adhanSound != 'Silent') {
        final isMuted = _temporarilyMutedAlerts.contains(_nextPrayerName);
        
        _showUpcomingAlertBanner = true;
        _upcomingAlertMinutesRemaining = nextAlarmDiffSec ~/ 60;
        _upcomingAlertSecondsRemaining = nextAlarmDiffSec % 60;

        NotificationService.showUpcomingNotification(
          prayerName: _nextPrayerName,
          minutesRemaining: (nextAlarmDiffSec ~/ 60) + 1,
          soundType: adhanSound,
          isMuted: isMuted,
        );
      }
    } else {
      NotificationService.cancelUpcoming();
    }

    // Logic for "Active" prayer (within 20 minutes of start)
    _isPrayerActive = false;
    _activePrayerName = '';
    
    for (var entry in times) {
      final difference = now.difference(entry.value);
      if (difference.inMinutes >= 0 && difference.inMinutes < 20) {
        _isPrayerActive = true;
        _activePrayerName = entry.key;
        break;
      }
    }

    // --- HIGH-PERFORMANCE HIGHLIGHT ROW SYNCHRONIZER ---
    String highlighted = nextName;
    for (var entry in times) {
      if (entry.key == 'Sunrise') continue;
      
      final adhanDT = entry.value;
      final offset = _iqamahOffsets[entry.key] ?? 20;
      final iqamahDT = adhanDT.add(Duration(minutes: offset));
      
      if (now.isAfter(adhanDT) && now.isBefore(iqamahDT)) {
        highlighted = entry.key;
        break;
      }
    }
    _highlightedPrayerName = highlighted;

    // --- REAL-TIME OFFLINE SCHEDULER ENGINE ---
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    
    for (var entry in times) {
      final prayerName = entry.key;
      if (prayerName == 'Sunrise') continue; // Sunrise has no alerts
      
      final adhanTime = entry.value;
      final adhanOffset = _adhanNotificationOffsets[prayerName] ?? 0;
      final adhanSound = _adhanNotificationSounds[prayerName] ?? 'Default Alert';
      
      // Calculate Adhan alarm time (Adhan minus offset)
      final adhanAlarmTime = adhanTime.subtract(Duration(minutes: adhanOffset));
      final adhanDiffSec = now.difference(adhanAlarmTime).inSeconds;
      final adhanTriggerKey = '${todayKey}_adhan_${prayerName}_$adhanOffset';
      
      if (adhanDiffSec >= 0 && adhanDiffSec < 5 && !_triggeredAlerts.contains(adhanTriggerKey)) {
        _triggeredAlerts.add(adhanTriggerKey);
        final isMuted = _temporarilyMutedAlerts.contains(prayerName);
        _temporarilyMutedAlerts.remove(prayerName); // Clear temporary mute for tomorrow
        
        if (adhanSound != 'Silent' && !isMuted) {
          playAlertSound(adhanSound);
        }
      }
      
      // Calculate Iqamah alarm time
      final iqamahMinutesAfterAdhan = _iqamahOffsets[prayerName] ?? 20;
      final iqamahTime = adhanTime.add(Duration(minutes: iqamahMinutesAfterAdhan));
      final iqamahOffset = _iqamahNotificationOffsets[prayerName] ?? 0;
      final iqamahSound = _iqamahNotificationSounds[prayerName] ?? 'Default Alert';
      
      final iqamahAlarmTime = iqamahTime.subtract(Duration(minutes: iqamahOffset));
      final iqamahDiffSec = now.difference(iqamahAlarmTime).inSeconds;
      final iqamahTriggerKey = '${todayKey}_iqamah_${prayerName}_$iqamahOffset';
      
      if (iqamahDiffSec >= 0 && iqamahDiffSec < 5 && !_triggeredAlerts.contains(iqamahTriggerKey)) {
        _triggeredAlerts.add(iqamahTriggerKey);
        if (iqamahSound != 'Silent') {
          playAlertSound(iqamahSound);
        }
      }
    }
  }

  Future<void> playAlertSound(String soundType) async {
    try {
      if (QuranProvider.activeQuranPlayer?.playing == true) {
        await QuranProvider.activeQuranPlayer?.pause();
      }
      await _alertPlayer.stop();
      if (soundType == 'Silent') return;
      
      // Post active system alarm drawer notification
      NotificationService.showActiveNotification(_nextPrayerName);
      
      final assetPath = (soundType == 'Full Adhan') 
          ? 'assets/audio/adhan.mp3' 
          : 'assets/audio/chime.mp3';
          
      await _alertPlayer.setAsset(assetPath);
      await _alertPlayer.play();
    } catch (e) {
      debugPrint('Error playing alert sound: $e');
    }
  }

  Future<void> stopAlertSound() async {
    await _alertPlayer.stop();
    NotificationService.cancelActive();
    notifyListeners();
  }

  Future<void> _scheduleNativeAlarms() async {
    if (_currentLocationData == null) return;
    try {
      await NotificationService.schedulePrayerNotifications(
        prayerTimes: _currentLocationData!.prayerTimes,
        adhanSounds: _adhanNotificationSounds,
        adhanOffsets: _adhanNotificationOffsets,
        iqamahSounds: _iqamahNotificationSounds,
        iqamahOffsets: _iqamahOffsets,
        iqamahNotificationOffsets: _iqamahNotificationOffsets,
        temporarilyMutedAlerts: _temporarilyMutedAlerts,
      );
    } catch (e) {
      debugPrint('Error scheduling native alarms: $e');
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _alertPlayer.dispose();
    super.dispose();
  }
}
