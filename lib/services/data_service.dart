import '../models/location_model.dart';
import '../models/prayer_time_model.dart';
import 'json_asset_loader.dart';

class DataService {
  static const String _gzipAssetPath = 'assets/data/kerala_azan.json.gz';
  
  Map<String, dynamic>? _cachedDatabase;

  Future<Map<String, dynamic>> _getDatabase() async {
    if (_cachedDatabase != null) return _cachedDatabase!;
    _cachedDatabase = await JsonAssetLoader.loadJsonObject(_gzipAssetPath);
    return _cachedDatabase!;
  }

  Future<List<District>> loadDistricts() async {
    final db = await _getDatabase();
    final List<dynamic> data = db['index'] as List<dynamic>;
    return data.map((json) => District.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<LocationData> loadLocationData(int id) async {
    final db = await _getDatabase();
    final locations = db['locations'] as Map<String, dynamic>;
    final dynamic locJson = locations['$id'] ?? locations.values.first;
    return LocationData.fromJson(locJson as Map<String, dynamic>);
  }
}
