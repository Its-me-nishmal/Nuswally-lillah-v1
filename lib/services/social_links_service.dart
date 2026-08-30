import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'json_asset_loader.dart';

class VideoChapter {
  final String title;
  final String timestamp;
  final int startSeconds;
  final int endSeconds;
  final String? thumbnail;

  const VideoChapter({
    required this.title,
    required this.timestamp,
    required this.startSeconds,
    required this.endSeconds,
    this.thumbnail,
  });

  factory VideoChapter.fromJson(Map<String, dynamic> json) {
    return VideoChapter(
      title: (json['title'] ?? '').toString(),
      timestamp: (json['timestamp'] ?? '').toString(),
      startSeconds: (json['startSeconds'] as num?)?.toInt() ?? 0,
      endSeconds: (json['endSeconds'] as num?)?.toInt() ?? 0,
      thumbnail: json['thumbnail']?.toString(),
    );
  }
}

class KeyDua {
  final String title;
  final String arabic;
  final String translation;

  const KeyDua({
    required this.title,
    required this.arabic,
    required this.translation,
  });

  factory KeyDua.fromJson(Map<String, dynamic> json) {
    return KeyDua(
      title: (json['title'] ?? '').toString(),
      arabic: (json['arabic'] ?? '').toString(),
      translation: (json['translation'] ?? '').toString(),
    );
  }
}

class SocialLink {
  final String id;
  final String platform;
  final String title;
  final String url;
  final String category;
  final String episode;
  final String speaker;
  final String speakerAvatar;
  final bool verified;
  final String views;
  final String publishedAt;
  final String likesCount;
  final String duration;
  final String thumbnail;
  final List<VideoChapter> chapters;
  final String transcript;
  final List<KeyDua> keyDuas;

  const SocialLink({
    this.id = '',
    required this.platform,
    required this.title,
    required this.url,
    this.category = 'Islamic Lecture',
    this.episode = 'Ep. 01',
    this.speaker = 'Nuswally Media',
    this.speakerAvatar = 'assets/images/developer.jpg',
    this.verified = true,
    this.views = '12K Views',
    this.publishedAt = 'Recently',
    this.likesCount = '1.2k',
    this.duration = '10:00',
    this.thumbnail = '',
    this.chapters = const [],
    this.transcript = '',
    this.keyDuas = const [],
  });

  factory SocialLink.fromJson(Map<String, dynamic> json) {
    final rawChapters = json['chapters'] as List<dynamic>? ?? [];
    final rawDuas = json['keyDuas'] as List<dynamic>? ?? [];

    return SocialLink(
      id: (json['id'] ?? '').toString(),
      platform: (json['platform'] ?? 'youtube').toString().toLowerCase(),
      title: (json['title'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      category: (json['category'] ?? 'Tafseer Series').toString(),
      episode: (json['episode'] ?? 'Ep. 08').toString(),
      speaker: (json['speaker'] ?? 'Sh. Ahmad Al-Khatib').toString(),
      speakerAvatar:
          (json['speakerAvatar'] ?? 'assets/images/developer.jpg').toString(),
      verified: json['verified'] == true || json['verified'] == null,
      views: (json['views'] ?? '142K Views').toString(),
      publishedAt: (json['publishedAt'] ?? '2 days ago').toString(),
      likesCount: (json['likesCount'] ?? '3.4k').toString(),
      duration: (json['duration'] ?? '45:20').toString(),
      thumbnail: (json['thumbnail'] ?? '').toString(),
      chapters: rawChapters
          .whereType<Map<String, dynamic>>()
          .map(VideoChapter.fromJson)
          .toList(),
      transcript: (json['transcript'] ?? '').toString(),
      keyDuas: rawDuas
          .whereType<Map<String, dynamic>>()
          .map(KeyDua.fromJson)
          .toList(),
    );
  }

  /// Automatically retrieves high-res YouTube thumbnail or configured image
  String get effectiveThumbnail {
    if (thumbnail.isNotEmpty && thumbnail.startsWith('http')) {
      return thumbnail;
    }
    final ytId = _extractYoutubeId(url);
    if (ytId != null && ytId.isNotEmpty) {
      return 'https://img.youtube.com/vi/$ytId/hqdefault.jpg';
    }
    return thumbnail;
  }

  static String? _extractYoutubeId(String videoUrl) {
    if (videoUrl.isEmpty) return null;
    if (videoUrl.contains('youtu.be/')) {
      final parts = videoUrl.split('youtu.be/').last.split('?').first.split('&').first;
      return parts.trim();
    }
    if (videoUrl.contains('watch?v=')) {
      final parts = videoUrl.split('watch?v=').last.split('&').first;
      return parts.trim();
    }
    final uri = Uri.tryParse(videoUrl);
    if (uri != null && uri.queryParameters.containsKey('v')) {
      return uri.queryParameters['v'];
    }
    return null;
  }
}

class VideoCategory {
  final String id;
  final String name;
  final String icon;
  final List<SocialLink> items;

  const VideoCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.items,
  });

  factory VideoCategory.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return VideoCategory(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      icon: (json['icon'] ?? 'play_circle_outline').toString(),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(SocialLink.fromJson)
          .toList(),
    );
  }
}

class SocialLinksService {
  static const String _localAssetPath = 'assets/data/social_links.json';
  static const String _spCachedJsonKey = 'cached_social_links_json';
  static const String _spVersionKey = 'cached_social_links_version';

  /// Remote API endpoint URL for downloading latest JSON & version check (hash-free for live sync)
  static String? apiUrl =
      'https://gist.githubusercontent.com/Its-me-nishmal/12a98c6a24c4e7912f439ebe6ebbc089/raw/nuswally_lillah_media.json';

  static List<SocialLink>? _cache;
  static List<VideoCategory>? _categoriesCache;
  static int _currentVersion = 1;

  /// Get the active data version
  static int get currentVersion => _currentVersion;

  /// Set or update the remote API URL
  static void setApiUrl(String url) {
    apiUrl = url;
  }

  /// Fetches all social links with offline-first caching and automatic remote sync
  static Future<List<SocialLink>> fetchSocialLinks() async {
    if (_cache != null && _cache!.isNotEmpty) return _cache!;

    try {
      final data = await _loadLocalOrCachedData();
      final List<SocialLink> links = _extractLinksFromData(data);

      _cache = links;

      // Trigger background update check if API URL is set
      if (apiUrl != null && apiUrl!.isNotEmpty) {
        unawaited(checkForUpdates());
      }

      return links;
    } catch (e) {
      debugPrint('SocialLinksService fetchSocialLinks error: $e');
    }
    return const <SocialLink>[];
  }

  /// Fetches categorized media content
  static Future<List<VideoCategory>> fetchCategories() async {
    if (_categoriesCache != null && _categoriesCache!.isNotEmpty) {
      return _categoriesCache!;
    }

    try {
      final data = await _loadLocalOrCachedData();
      final categoriesList = data['categories'] as List<dynamic>? ?? [];
      final categories = categoriesList
          .whereType<Map<String, dynamic>>()
          .map(VideoCategory.fromJson)
          .where((cat) => cat.items.isNotEmpty)
          .toList();

      if (categories.isNotEmpty) {
        _categoriesCache = categories;
        if (apiUrl != null && apiUrl!.isNotEmpty) {
          unawaited(checkForUpdates());
        }
        return categories;
      }

      // Default category fallback
      final allLinks = await fetchSocialLinks();
      if (allLinks.isNotEmpty) {
        final defaultCat = VideoCategory(
          id: 'all_media',
          name: 'Featured Videos',
          icon: 'play_circle_outline',
          items: allLinks,
        );
        _categoriesCache = [defaultCat];
        return _categoriesCache!;
      }
    } catch (e) {
      debugPrint('SocialLinksService fetchCategories error: $e');
    }
    return const <VideoCategory>[];
  }

  /// Check remote API for version changes and automatically download & cache new JSON
  static Future<bool> checkForUpdates() async {
    final String api = apiUrl ?? '';
    if (api.isEmpty) return false;

    try {
      final uri = Uri.parse(
        '$api${api.contains('?') ? '&' : '?'}t=${DateTime.now().millisecondsSinceEpoch}',
      );
      final response = await http.get(
        uri,
        headers: {'Cache-Control': 'no-cache, no-store, must-revalidate'},
      ).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        debugPrint(
            'SocialLinksService: API responded with status ${response.statusCode}');
        return false;
      }

      final dynamic decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) return false;

      final int remoteVersion =
          (decoded['version'] as num?)?.toInt() ?? _currentVersion;

      // If remote version is newer or different from local version, save & update
      if (remoteVersion > _currentVersion ||
          (!_hasCachedJson() && remoteVersion >= _currentVersion)) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_spCachedJsonKey, response.body);
        await prefs.setInt(_spVersionKey, remoteVersion);

        _currentVersion = remoteVersion;

        // Refresh in-memory cache
        final newLinks = _extractLinksFromData(decoded);
        _cache = newLinks;

        final categoriesList = decoded['categories'] as List<dynamic>? ?? [];
        _categoriesCache = categoriesList
            .whereType<Map<String, dynamic>>()
            .map(VideoCategory.fromJson)
            .where((cat) => cat.items.isNotEmpty)
            .toList();

        debugPrint(
            'SocialLinksService: Successfully updated to remote version $remoteVersion');
        return true;
      }
    } catch (e) {
      debugPrint('SocialLinksService checkForUpdates error: $e');
    }
    return false;
  }

  /// Loads data from SharedPreferences cache first; falls back to bundled asset
  static Future<Map<String, dynamic>> _loadLocalOrCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJsonStr = prefs.getString(_spCachedJsonKey);
      final cachedVer = prefs.getInt(_spVersionKey);

      if (cachedJsonStr != null && cachedJsonStr.isNotEmpty) {
        final decoded = json.decode(cachedJsonStr);
        if (decoded is Map<String, dynamic>) {
          _currentVersion =
              cachedVer ?? (decoded['version'] as num?)?.toInt() ?? 1;
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('SocialLinksService: Error loading cached JSON: $e');
    }

    // Baseline from bundled assets
    final Map<String, dynamic> assetData =
        await JsonAssetLoader.loadJsonObject(_localAssetPath);
    _currentVersion = (assetData['version'] as num?)?.toInt() ?? 1;
    return assetData;
  }

  static bool _hasCachedJson() {
    return _cache != null && _cache!.isNotEmpty;
  }

  static List<SocialLink> _extractLinksFromData(Map<String, dynamic> data) {
    final List<SocialLink> links = [];

    // Check categories first
    final categoriesList = data['categories'] as List<dynamic>?;
    if (categoriesList != null) {
      for (final catJson in categoriesList) {
        if (catJson is Map<String, dynamic>) {
          final items = catJson['items'] as List<dynamic>? ?? [];
          for (final item in items) {
            if (item is Map<String, dynamic>) {
              links.add(SocialLink.fromJson(item));
            }
          }
        }
      }
    }

    // Fallback to social_links list
    if (links.isEmpty) {
      final rawList = (data['social_links'] as List<dynamic>? ?? <dynamic>[]);
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          links.add(SocialLink.fromJson(item));
        }
      }
    }

    return links.where((link) => link.url.isNotEmpty).toList();
  }

  /// Clear all cache and reset to default bundled version
  static Future<void> clearCache() async {
    _cache = null;
    _categoriesCache = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_spCachedJsonKey);
    await prefs.remove(_spVersionKey);
  }
}
