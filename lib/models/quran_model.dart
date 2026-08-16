class Surah {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final String malayalamName;
  final String malayalamNameTranslation;
  final int numberOfAyahs;
  final String revelationType;

  const Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    this.malayalamName = '',
    this.malayalamNameTranslation = '',
    required this.numberOfAyahs,
    required this.revelationType,
  });

  /// AlQuran Cloud CDN Surah Audio URL
  String getAlQuranCloudSurahAudioUrl({String edition = 'ar.alafasy', int bitrate = 128}) {
    return 'https://cdn.islamic.network/quran/audio-surah/$bitrate/$edition/$number.mp3';
  }

  factory Surah.fromJson(Map<dynamic, dynamic> json) {
    return Surah(
      number: json['number'] ?? json['id'] ?? 0,
      name: (json['name'] ?? '').toString(),
      englishName: (json['englishName'] ?? json['transliteration'] ?? '').toString(),
      englishNameTranslation: (json['englishNameTranslation'] ?? json['translation'] ?? '').toString(),
      malayalamName: (json['malayalamName'] ?? json['name_ml'] ?? '').toString(),
      malayalamNameTranslation: (json['malayalamNameTranslation'] ?? json['translation_ml'] ?? '').toString(),
      numberOfAyahs: json['numberOfAyahs'] ?? json['total_verses'] ?? 0,
      revelationType: (json['revelationType'] ?? json['type'] ?? '').toString().toUpperCase(),
    );
  }
}

class Ayah {
  final int number; // Global number (1 to 6236)
  final String text;
  final int numberInSurah;
  final int juz;
  final String audio;
  final int page;
  final int manzil;
  final int ruku;
  final int hizbQuarter;
  final bool sajda;
  final String translationEn;
  final String translationMl;

  const Ayah({
    required this.number,
    required this.text,
    required this.numberInSurah,
    required this.juz,
    required this.audio,
    this.page = 1,
    this.manzil = 1,
    this.ruku = 1,
    this.hizbQuarter = 1,
    this.sajda = false,
    this.translationEn = '',
    this.translationMl = '',
  });

  /// AlQuran Cloud CDN Ayah Audio URL
  String getAlQuranCloudAudioUrl({String edition = 'ar.alafasy', int bitrate = 128}) {
    return 'https://cdn.islamic.network/quran/audio/$bitrate/$edition/$number.mp3';
  }

  factory Ayah.fromJson(Map<dynamic, dynamic> json) {
    return Ayah(
      number: json['number'] ?? json['id'] ?? 0,
      text: (json['text'] ?? '').toString(),
      numberInSurah: json['numberInSurah'] ?? json['id'] ?? 0,
      juz: json['juz'] ?? 1,
      audio: (json['audio'] ?? '').toString(),
      page: json['page'] ?? 1,
      manzil: json['manzil'] ?? 1,
      ruku: json['ruku'] ?? 1,
      hizbQuarter: json['hizbQuarter'] ?? 1,
      sajda: json['sajda'] is bool ? json['sajda'] : json['sajda'] != null,
      translationEn: (json['translationEn'] ?? json['translation'] ?? '').toString(),
      translationMl: (json['translationMl'] ?? json['translation_ml'] ?? '').toString(),
    );
  }
}
