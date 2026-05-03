import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/location_model.dart';
import '../models/prayer_time_model.dart';

class DataService {
  static const String _assetPath = 'assets/KERALA-AZAN-DATA-main';

  Future<List<District>> loadDistricts() async {
    final String response = await rootBundle.loadString('$_assetPath/index.json');
    final List<dynamic> data = json.decode(response);
    return data.map((json) => District.fromJson(json)).toList();
  }

  Future<LocationData> loadLocationData(int id) async {
    final String response = await rootBundle.loadString('$_assetPath/$id.json');
    final Map<String, dynamic> data = json.decode(response);
    return LocationData.fromJson(data);
  }
}
