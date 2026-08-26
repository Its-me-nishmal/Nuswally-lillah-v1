import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateInfo {
  final int versionCode;
  final String versionName;
  final int minSupportedVersionCode;
  final String releaseDate;
  final bool isCritical;
  final String downloadUrl;
  final String title;
  final String description;
  final List<String> features;
  final List<String> improvements;
  final List<String> bugFixes;

  const AppUpdateInfo({
    required this.versionCode,
    required this.versionName,
    required this.minSupportedVersionCode,
    required this.releaseDate,
    required this.isCritical,
    required this.downloadUrl,
    required this.title,
    required this.description,
    required this.features,
    required this.improvements,
    required this.bugFixes,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'] as List<dynamic>? ?? [];
    final rawImprovements = json['improvements'] as List<dynamic>? ?? [];
    final rawBugFixes = json['bug_fixes'] as List<dynamic>? ?? [];
    final rawChangelog = json['changelog'] as List<dynamic>? ?? [];

    final featuresList = rawFeatures.isNotEmpty
        ? rawFeatures.map((e) => e.toString()).toList()
        : rawChangelog.map((e) => e.toString()).toList();

    return AppUpdateInfo(
      versionCode: (json['version_code'] as num?)?.toInt() ?? 100,
      versionName: (json['version_name'] ?? '1.0.0').toString(),
      minSupportedVersionCode:
          (json['min_supported_version_code'] as num?)?.toInt() ?? 100,
      releaseDate: (json['release_date'] ?? '').toString(),
      isCritical: json['is_critical'] == true,
      downloadUrl: (json['download_url'] ??
              'https://play.google.com/store/apps/details?id=com.nuswallylillah')
          .toString(),
      title: (json['title'] ?? 'New Update Available').toString(),
      description: (json['description'] ?? '').toString(),
      features: featuresList,
      improvements: rawImprovements.map((e) => e.toString()).toList(),
      bugFixes: rawBugFixes.map((e) => e.toString()).toList(),
    );
  }

  /// Whether this update is mandatory and cannot be skipped
  bool isForceUpdate(int currentVersionCode) {
    return isCritical || currentVersionCode < minSupportedVersionCode;
  }
}

class AppUpdateService {
  static const String _localAssetPath = 'assets/data/app_update.json';
  static const String _spCachedUpdateKey = 'cached_app_update_json';

  /// Current installed version of the app
  static const int currentVersionCode = 202;
  static const String currentVersionName = '2.0.1';

  /// Remote API/Gist endpoint for checking app updates (hash-free for live sync)
  static String? apiUrl =
      'https://gist.githubusercontent.com/Its-me-nishmal/c0a93c2dfa355778e7e5de3fd1a88f1a/raw/v.json';

  static AppUpdateInfo? _cachedInfo;

  /// Sets or updates the remote API URL for app updates
  static void setApiUrl(String url) {
    apiUrl = url;
  }

  /// Checks whether an update is available (either from remote API or cached/local data)
  static Future<AppUpdateInfo?> fetchUpdateInfo({
    bool forceRemote = false,
  }) async {
    if (!forceRemote && _cachedInfo != null) {
      return _cachedInfo;
    }

    // 1. Try remote API if configured
    try {
      final String api = apiUrl ?? '';
      if (api.isNotEmpty) {
        final uri = Uri.parse(
          '$api${api.contains('?') ? '&' : '?'}t=${DateTime.now().millisecondsSinceEpoch}',
        );
        final response = await http
            .get(
              uri,
              headers: {'Cache-Control': 'no-cache, no-store, must-revalidate'},
            )
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic>) {
            final info = AppUpdateInfo.fromJson(decoded);
            _cachedInfo = info;

            // Cache to SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_spCachedUpdateKey, response.body);
            return info;
          }
        }
      }
    } catch (e) {
      debugPrint('Remote update check failed: $e');
    }

    // 2. Try SharedPreferences cache if remote failed
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString(_spCachedUpdateKey);
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final decoded = json.decode(cachedStr);
        if (decoded is Map<String, dynamic>) {
          final info = AppUpdateInfo.fromJson(decoded);
          _cachedInfo = info;
          return info;
        }
      }
    } catch (e) {
      debugPrint('Cache update check error: $e');
    }

    // 3. Fallback to bundled asset
    try {
      final raw = await rootBundle.loadString(_localAssetPath);
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final info = AppUpdateInfo.fromJson(decoded);
      _cachedInfo = info;
      return info;
    } catch (e) {
      debugPrint('Asset update check error: $e');
    }

    return _cachedInfo;
  }

  /// Returns true if the latest fetched version is newer than current installed version
  static bool isUpdateAvailable(AppUpdateInfo? info) {
    if (info == null) return false;
    return info.versionCode > currentVersionCode;
  }

  /// Returns true if this is a mandatory/forced update
  static bool isForceUpdate(AppUpdateInfo? info) {
    if (info == null) return false;
    return info.isForceUpdate(currentVersionCode);
  }

  /// Opens the download/release URL in external browser or store
  static Future<bool> launchDownload(String downloadUrl) async {
    if (downloadUrl.isEmpty) return false;
    try {
      final uri = Uri.parse(downloadUrl);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('AppUpdateService launchDownload error: $e');
    }
    return false;
  }
}
