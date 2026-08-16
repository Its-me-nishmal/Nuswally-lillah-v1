import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/qari_model.dart';
import '../models/quran_model.dart';

/// High-performance non-blocking background audio preloader & disk cache.
class QuranAudioCacheService {
  static final Map<String, bool> _activeDownloads = {};
  static final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10)
    ..idleTimeout = const Duration(seconds: 15);

  /// Get the cache directory for Quran audio files
  static Directory _getCacheDir() {
    final tempDir = Directory.systemTemp;
    final dir = Directory('${tempDir.path}/quran_audio_cache');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Get cached file path if it exists and is valid (> 2KB)
  static String? getCachedFilePath(String qariId, int surah, int ayah) {
    try {
      final safeQari = qariId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      final cacheDir = _getCacheDir();
      final file = File('${cacheDir.path}/${safeQari}_${surah}_$ayah.mp3');
      if (file.existsSync() && file.lengthSync() > 2048) {
        return file.path;
      }
    } catch (_) {}
    return null;
  }

  /// Preload upcoming Ayahs sequentially in background without UI blocking
  static void preloadUpcomingAyahs({
    required Qari qari,
    required int surahNumber,
    required int currentAyahIndex,
    required List<Ayah> ayahs,
    int count = 5,
  }) {
    // Run completely decoupled from UI thread
    Future.microtask(() async {
      final safeQari = qari.relativePath.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      final cacheDir = _getCacheDir();

      for (int i = 1; i <= count; i++) {
        final targetIndex = currentAyahIndex + i;
        if (targetIndex >= ayahs.length) break;

        final targetAyah = ayahs[targetIndex];
        final file = File('${cacheDir.path}/${safeQari}_${surahNumber}_${targetAyah.numberInSurah}.mp3');

        // Skip if already cached
        if (file.existsSync() && file.lengthSync() > 2048) {
          continue;
        }

        final downloadKey = '${safeQari}_${surahNumber}_${targetAyah.numberInSurah}';
        if (_activeDownloads[downloadKey] == true) {
          continue;
        }

        _activeDownloads[downloadKey] = true;
        try {
          final url = targetAyah.audio;
          await _downloadFile(url, file);
        } catch (e) {
          // Benign background prefetch fail
          debugPrint('Prefetch failed for Ayah ${targetAyah.numberInSurah}: $e');
        } finally {
          _activeDownloads.remove(downloadKey);
        }
      }
    });
  }

  static Future<void> _downloadFile(String url, File targetFile) async {
    try {
      final uri = Uri.parse(url);
      final request = await _httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final tempFile = File('${targetFile.path}.tmp');
        final sink = tempFile.openWrite();
        await response.pipe(sink);
        await sink.close();

        if (tempFile.existsSync() && tempFile.lengthSync() > 2048) {
          if (targetFile.existsSync()) {
            targetFile.deleteSync();
          }
          tempFile.renameSync(targetFile.path);
        } else if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      }
    } catch (e) {
      // Clean up tmp file on error
      final tempFile = File('${targetFile.path}.tmp');
      if (tempFile.existsSync()) {
        try {
          tempFile.deleteSync();
        } catch (_) {}
      }
    }
  }

  /// Clean old cache files if cache exceeds 100MB
  static Future<void> pruneCacheIfNeeded() async {
    Future.microtask(() {
      try {
        final dir = _getCacheDir();
        final files = dir.listSync().whereType<File>().toList();
        int totalSize = 0;
        for (final f in files) {
          totalSize += f.lengthSync();
        }

        // Limit to 100MB
        if (totalSize > 100 * 1024 * 1024) {
          files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
          int deletedSize = 0;
          for (final f in files) {
            final sz = f.lengthSync();
            f.deleteSync();
            deletedSize += sz;
            if (totalSize - deletedSize < 50 * 1024 * 1024) {
              break;
            }
          }
        }
      } catch (_) {}
    });
  }
}
