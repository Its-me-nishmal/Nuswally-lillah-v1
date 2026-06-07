import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JournalHabit {
  final String id;
  final String title;
  final String time; // e.g. "07:30" (24-hour style)
  final bool showOnHomeTimeline;
  final Map<String, bool> completions; // dateStr -> completed

  JournalHabit({
    required this.id,
    required this.title,
    required this.time,
    this.showOnHomeTimeline = true,
    Map<String, bool>? completions,
  }) : completions = completions ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'time': time,
        'showOnHomeTimeline': showOnHomeTimeline,
        'completions': completions,
      };

  factory JournalHabit.fromJson(Map<String, dynamic> json) {
    final comps = Map<String, bool>.from(
      (json['completions'] as Map? ?? {}).map(
        (key, value) => MapEntry(key.toString(), value as bool),
      ),
    );
    return JournalHabit(
      id: json['id'] as String,
      title: json['title'] as String,
      time: json['time'] as String,
      showOnHomeTimeline: json['showOnHomeTimeline'] as bool? ?? true,
      completions: comps,
    );
  }

  JournalHabit copyWith({
    String? title,
    String? time,
    bool? showOnHomeTimeline,
    Map<String, bool>? completions,
  }) {
    return JournalHabit(
      id: id,
      title: title ?? this.title,
      time: time ?? this.time,
      showOnHomeTimeline: showOnHomeTimeline ?? this.showOnHomeTimeline,
      completions: completions ?? this.completions,
    );
  }
}

class JournalProvider with ChangeNotifier {
  List<JournalHabit> _habits = [];
  Map<String, List<String>> _completedPrayers = {}; // dateStr -> ['Fajr', 'Dhuhr', ...]

  List<JournalHabit> get habits => _habits;
  Map<String, List<String>> get completedPrayers => _completedPrayers;

  JournalProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Habits
    final habitsJson = prefs.getString('journal_habits');
    if (habitsJson != null) {
      try {
        final List decoded = json.decode(habitsJson);
        _habits = decoded.map((item) => JournalHabit.fromJson(item)).toList();
      } catch (e) {
        debugPrint('Error loading habits: $e');
      }
    } else {
      // Default initial daily habits for the user to enjoy instantly!
      _habits = [
        JournalHabit(
          id: 'h_1',
          title: 'Morning Adhkar 🌅',
          time: '06:00',
          showOnHomeTimeline: true,
        ),
        JournalHabit(
          id: 'h_2',
          title: 'Read Surah Mulk 📖',
          time: '21:30',
          showOnHomeTimeline: true,
        ),
      ];
      await _saveHabits();
    }

    // Load Completed Prayers
    final prayersJson = prefs.getString('completed_prayers');
    if (prayersJson != null) {
      try {
        final Map decoded = json.decode(prayersJson);
        _completedPrayers = decoded.map(
          (key, value) => MapEntry(key.toString(), List<String>.from(value)),
        );
      } catch (e) {
        debugPrint('Error loading completed prayers: $e');
      }
    }

    notifyListeners();
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _habits.map((h) => h.toJson()).toList();
    await prefs.setString('journal_habits', json.encode(data));
  }

  Future<void> _saveCompletedPrayers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('completed_prayers', json.encode(_completedPrayers));
  }

  // --- Prayer Methods ---
  bool isPrayerCompleted(String dateStr, String prayerName) {
    return _completedPrayers[dateStr]?.contains(prayerName) ?? false;
  }

  Future<void> togglePrayerCompletion(String dateStr, String prayerName) async {
    if (!_completedPrayers.containsKey(dateStr)) {
      _completedPrayers[dateStr] = [];
    }

    final list = _completedPrayers[dateStr]!;
    if (list.contains(prayerName)) {
      list.remove(prayerName);
    } else {
      list.add(prayerName);
    }

    notifyListeners();
    await _saveCompletedPrayers();
  }

  int getCompletedCountForDate(String dateStr) {
    return _completedPrayers[dateStr]?.length ?? 0;
  }

  // --- Habit Methods ---
  Future<void> addHabit(String title, String time) async {
    final newHabit = JournalHabit(
      id: 'h_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      time: time,
      showOnHomeTimeline: true,
    );
    _habits.add(newHabit);
    notifyListeners();
    await _saveHabits();
  }

  Future<void> deleteHabit(String id) async {
    _habits.removeWhere((h) => h.id == id);
    notifyListeners();
    await _saveHabits();
  }

  Future<void> toggleHabitTimelineVisibility(String id) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      _habits[index] = _habits[index].copyWith(
        showOnHomeTimeline: !_habits[index].showOnHomeTimeline,
      );
      notifyListeners();
      await _saveHabits();
    }
  }

  Future<void> toggleHabitCompletion(String id, String dateStr) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      final habit = _habits[index];
      final newCompletions = Map<String, bool>.from(habit.completions);
      final isCompleted = newCompletions[dateStr] ?? false;
      newCompletions[dateStr] = !isCompleted;

      _habits[index] = habit.copyWith(completions: newCompletions);
      notifyListeners();
      await _saveHabits();
    }
  }

  bool isHabitCompleted(String id, String dateStr) {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      return _habits[index].completions[dateStr] ?? false;
    }
    return false;
  }
}
