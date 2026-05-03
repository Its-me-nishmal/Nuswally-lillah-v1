import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_model.dart';
import '../models/prayer_time_model.dart';
import '../services/data_service.dart';

class PrayerProvider with ChangeNotifier {
  final DataService _dataService = DataService();
  
  List<District> _districts = [];
  Location? _selectedLocation;
  LocationData? _currentLocationData;
  PrayerTime? _todayPrayerTimes;
  String _nextPrayerName = '';
  Duration _timeToNextPrayer = Duration.zero;
  bool _isPrayerActive = false;
  String _activePrayerName = '';
  bool _isLocationSet = false;
  Timer? _countdownTimer;

  List<District> get districts => _districts;
  Location? get selectedLocation => _selectedLocation;
  LocationData? get currentLocationData => _currentLocationData;
  PrayerTime? get todayPrayerTimes => _todayPrayerTimes;
  String get nextPrayerName => _nextPrayerName;
  Duration get timeToNextPrayer => _timeToNextPrayer;
  bool get isPrayerActive => _isPrayerActive;
  String get activePrayerName => _activePrayerName;
  bool get hasLocationSet => _isLocationSet;

  PrayerProvider() {
    _init();
  }

  Future<void> _init() async {
    _districts = await _dataService.loadDistricts();
    await _loadSavedLocation();
    _startCountdown();
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
    _calculateNextPrayerFixed();
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
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
