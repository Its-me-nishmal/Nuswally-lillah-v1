import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/adhkaar.dart';
import '../models/allah_name.dart';

class AdhkaarProvider extends ChangeNotifier {
  AdhkaarBundle? _bundle;
  List<AllahName> _allahNames = [];
  bool _isLoading = false;
  String? _error;

  AdhkaarBundle? get bundle => _bundle;
  List<AllahName> get allahNames => _allahNames;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalDuas => _bundle?.duas.length ?? 0;
  int get totalCategories => _bundle?.categories.length ?? 0;
  int get totalAllahNames => _allahNames.length;

  Future<void> load() async {
    if (_bundle != null || _isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final raw = await rootBundle.loadString('assets/data/adhkaar.json');
      _bundle = AdhkaarBundle.fromRaw(raw);

      // Load 99 Names of Allah from dedicated dataset
      final namesJsonRaw = await rootBundle.loadString('assets/data/99_names_of_allah.json');
      final Map<String, dynamic> namesMap = json.decode(namesJsonRaw);
      final List<dynamic> namesList = namesMap['data'] as List<dynamic>? ?? [];
      _allahNames = namesList.map((e) => AllahName.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e, stack) {
      debugPrint('Error parsing Adhkaar / 99 Names JSON: $e\n$stack');
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
}
