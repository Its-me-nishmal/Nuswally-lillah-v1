class JuzModel {
  final int id;
  final String nameAr;
  final String nameEn;
  final int startSurahNumber;
  final String startSurahName;
  final int startAyah;
  final int endSurahNumber;
  final String endSurahName;
  final int endAyah;

  const JuzModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.startSurahNumber,
    required this.startSurahName,
    required this.startAyah,
    required this.endSurahNumber,
    required this.endSurahName,
    required this.endAyah,
  });

  String get rangeDisplay => '$startSurahName $startSurahNumber:$startAyah — $endSurahName $endSurahNumber:$endAyah';

  factory JuzModel.fromJson(Map<dynamic, dynamic> json) {
    return JuzModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '1') ?? 1,
      nameAr: (json['name_ar'] ?? '').toString(),
      nameEn: (json['name_en'] ?? '').toString(),
      startSurahNumber: json['start_surah_number'] is int ? json['start_surah_number'] : int.tryParse(json['start_surah_number']?.toString() ?? '1') ?? 1,
      startSurahName: (json['start_surah_name'] ?? '').toString(),
      startAyah: json['start_ayah'] is int ? json['start_ayah'] : int.tryParse(json['start_ayah']?.toString() ?? '1') ?? 1,
      endSurahNumber: json['end_surah_number'] is int ? json['end_surah_number'] : int.tryParse(json['end_surah_number']?.toString() ?? '1') ?? 1,
      endSurahName: (json['end_surah_name'] ?? '').toString(),
      endAyah: json['end_ayah'] is int ? json['end_ayah'] : int.tryParse(json['end_ayah']?.toString() ?? '1') ?? 1,
    );
  }
}
