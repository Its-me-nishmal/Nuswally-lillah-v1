class QuranEdition {
  final String identifier;
  final String language;
  final String name;
  final String englishName;
  final String format; // 'text' or 'audio'
  final String type; // 'translation', 'quran', 'tafsir', 'versebyverse'
  final String? direction; // 'rtl' or 'ltr'

  const QuranEdition({
    required this.identifier,
    required this.language,
    required this.name,
    required this.englishName,
    required this.format,
    required this.type,
    this.direction,
  });

  factory QuranEdition.fromJson(Map<String, dynamic> json) {
    return QuranEdition(
      identifier: json['identifier'] as String? ?? '',
      language: json['language'] as String? ?? 'ar',
      name: json['name'] as String? ?? '',
      englishName: json['englishName'] as String? ?? '',
      format: json['format'] as String? ?? 'text',
      type: json['type'] as String? ?? 'translation',
      direction: json['direction'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'identifier': identifier,
        'language': language,
        'name': name,
        'englishName': englishName,
        'format': format,
        'type': type,
        'direction': direction,
      };
}

class QuranSearchResult {
  final int number; // Global ayah number
  final String text;
  final int numberInSurah;
  final int surahNumber;
  final String surahName;
  final String surahEnglishName;
  final String editionIdentifier;

  const QuranSearchResult({
    required this.number,
    required this.text,
    required this.numberInSurah,
    required this.surahNumber,
    required this.surahName,
    required this.surahEnglishName,
    required this.editionIdentifier,
  });

  factory QuranSearchResult.fromJson(Map<String, dynamic> json, {String edition = 'en.sahih'}) {
    final surahMap = json['surah'] as Map<String, dynamic>? ?? {};
    return QuranSearchResult(
      number: json['number'] as int? ?? 0,
      text: json['text'] as String? ?? '',
      numberInSurah: json['numberInSurah'] as int? ?? 0,
      surahNumber: surahMap['number'] as int? ?? 0,
      surahName: surahMap['name'] as String? ?? '',
      surahEnglishName: surahMap['englishName'] as String? ?? '',
      editionIdentifier: edition,
    );
  }
}

class SajdaInfo {
  final int ayahNumber;
  final int numberInSurah;
  final int surahNumber;
  final String surahName;
  final String text;
  final bool recommended;
  final bool obligatory;

  const SajdaInfo({
    required this.ayahNumber,
    required this.numberInSurah,
    required this.surahNumber,
    required this.surahName,
    required this.text,
    this.recommended = true,
    this.obligatory = false,
  });

  factory SajdaInfo.fromJson(Map<String, dynamic> json) {
    final surahMap = json['surah'] as Map<String, dynamic>? ?? {};
    final sajdaVal = json['sajda'];
    bool rec = true;
    bool oblig = false;

    if (sajdaVal is Map<String, dynamic>) {
      rec = sajdaVal['recommended'] as bool? ?? true;
      oblig = sajdaVal['obligatory'] as bool? ?? false;
    }

    return SajdaInfo(
      ayahNumber: json['number'] as int? ?? 0,
      numberInSurah: json['numberInSurah'] as int? ?? 0,
      surahNumber: surahMap['number'] as int? ?? 0,
      surahName: surahMap['name'] as String? ?? '',
      text: json['text'] as String? ?? '',
      recommended: rec,
      obligatory: oblig,
    );
  }
}
