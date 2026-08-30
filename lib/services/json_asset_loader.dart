import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

/// Centralized utility for fast, transparent loading of JSON and GZipped JSON assets.
/// Automatically handles decompresion for `.gz` assets with zero overhead.
class JsonAssetLoader {
  JsonAssetLoader._();

  /// Loads a JSON asset string.
  /// If the path ends with `.gz`, or if a `.gz` variant exists, it decompresses it via [gzip].
  /// Otherwise, falls back to standard [rootBundle.loadString].
  static Future<String> loadString(String assetPath) async {
    if (assetPath.endsWith('.gz')) {
      final ByteData byteData = await rootBundle.load(assetPath);
      final Uint8List compressedBytes = byteData.buffer.asUint8List();
      final List<int> decompressedBytes = gzip.decode(compressedBytes);
      return utf8.decode(decompressedBytes);
    }

    try {
      final ByteData byteData = await rootBundle.load('$assetPath.gz');
      final Uint8List compressedBytes = byteData.buffer.asUint8List();
      final List<int> decompressedBytes = gzip.decode(compressedBytes);
      return utf8.decode(decompressedBytes);
    } catch (_) {
      return await rootBundle.loadString(assetPath);
    }
  }

  /// Loads and decodes a JSON asset into dynamic (Map or List).
  static Future<dynamic> loadJson(String assetPath) async {
    final String raw = await loadString(assetPath);
    return json.decode(raw);
  }

  /// Loads and decodes a JSON asset as a [Map<String, dynamic>].
  static Future<Map<String, dynamic>> loadJsonObject(String assetPath) async {
    final dynamic decoded = await loadJson(assetPath);
    return decoded as Map<String, dynamic>;
  }

  /// Loads and decodes a JSON asset as a [List<dynamic>].
  static Future<List<dynamic>> loadJsonList(String assetPath) async {
    final dynamic decoded = await loadJson(assetPath);
    return decoded as List<dynamic>;
  }
}
