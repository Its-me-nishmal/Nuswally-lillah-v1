class AllahName {
  final int number;
  final String name; // Arabic text
  final String transliteration;
  final String found; // Quran reference
  final String meaning;
  final String description;

  const AllahName({
    required this.number,
    required this.name,
    required this.transliteration,
    required this.found,
    required this.meaning,
    required this.description,
  });

  factory AllahName.fromJson(Map<String, dynamic> json) {
    final en = json['en'] as Map<String, dynamic>? ?? {};
    return AllahName(
      number: json['number'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      transliteration: json['transliteration'] as String? ?? '',
      found: json['found'] as String? ?? '',
      meaning: en['meaning'] as String? ?? '',
      description: en['desc'] as String? ?? '',
    );
  }
}
