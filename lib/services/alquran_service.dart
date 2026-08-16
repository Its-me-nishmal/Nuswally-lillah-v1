import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/quran_edition_model.dart';

class AlQuranService {
  static List<QuranEdition>? _cachedEditions;
  static List<SajdaInfo>? _cachedSajdas;
  static List<dynamic>? _cachedQuranJson;

  /// Load editions locally from bundled assets (Zero network call)
  static Future<List<QuranEdition>> fetchEditions({
    String? language,
    String? format,
    String? type,
  }) async {
    try {
      if (_cachedEditions == null) {
        final String raw = await rootBundle.loadString('assets/quran/editions.json');
        final List<dynamic> list = json.decode(raw) as List<dynamic>;
        _cachedEditions = list
            .map((e) => QuranEdition.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      List<QuranEdition> filtered = _cachedEditions!;
      if (format != null) {
        filtered = filtered.where((e) => e.format.toLowerCase() == format.toLowerCase()).toList();
      }
      if (language != null) {
        filtered = filtered.where((e) => e.language.toLowerCase() == language.toLowerCase()).toList();
      }
      if (type != null) {
        filtered = filtered.where((e) => e.type.toLowerCase() == type.toLowerCase()).toList();
      }
      return filtered;
    } catch (e) {
      debugPrint('AlQuranService fetchEditions error from assets: $e');
    }
    return [];
  }

  /// Load Sajda verses locally from bundled assets (Zero network call)
  static Future<List<SajdaInfo>> fetchSajdas({String edition = 'quran-uthmani'}) async {
    try {
      if (_cachedSajdas == null) {
        final String raw = await rootBundle.loadString('assets/quran/sajda.json');
        final List<dynamic> list = json.decode(raw) as List<dynamic>;
        _cachedSajdas = list
            .map((e) => SajdaInfo.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return _cachedSajdas ?? [];
    } catch (e) {
      debugPrint('AlQuranService fetchSajdas error from assets: $e');
    }
    return [];
  }

  /// 100% Offline Fast Search across all 114 Surahs and 6,236 Ayahs
  static Future<List<QuranSearchResult>> searchQuran(
    String query, {
    String edition = 'en.sahih',
    int? surahNumber,
  }) async {
    if (query.trim().isEmpty) return [];
    try {
      if (_cachedQuranJson == null) {
        final String raw = await rootBundle.loadString('assets/quran/quran.json');
        _cachedQuranJson = json.decode(raw) as List<dynamic>;
      }

      final cleanQuery = query.toLowerCase().trim();
      final List<QuranSearchResult> results = [];

      for (final surah in _cachedQuranJson!) {
        final int sNum = surah['id'] as int? ?? 0;
        if (surahNumber != null && surahNumber > 0 && sNum != surahNumber) {
          continue;
        }

        final sName = surah['name'] as String? ?? '';
        final sEng = surah['transliteration'] as String? ?? '';
        final verses = surah['verses'] as List<dynamic>? ?? [];

        for (final v in verses) {
          final int vNum = v['id'] as int? ?? 0;
          final String text = v['text'] as String? ?? '';
          final String trans = (v['translation'] ?? '').toString();
          final String transMl = (v['translation_ml'] ?? '').toString();

          if (text.contains(query) ||
              trans.toLowerCase().contains(cleanQuery) ||
              transMl.contains(query)) {
            results.add(QuranSearchResult(
              number: vNum,
              text: trans.isNotEmpty ? trans : text,
              numberInSurah: vNum,
              surahNumber: sNum,
              surahName: sName,
              surahEnglishName: sEng,
              editionIdentifier: edition,
            ));
          }
          if (results.length >= 100) break; // Limit search results for performance
        }
      }
      return results;
    } catch (e) {
      debugPrint('AlQuranService searchQuran error: $e');
    }
    return [];
  }
}
