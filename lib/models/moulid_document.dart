class MoulidCouplet {
  final String hemistich1;
  final String hemistich2;

  const MoulidCouplet({
    required this.hemistich1,
    required this.hemistich2,
  });

  factory MoulidCouplet.fromJson(Map<String, dynamic> json) {
    return MoulidCouplet(
      hemistich1: json['hemistich1'] as String? ?? '',
      hemistich2: json['hemistich2'] as String? ?? '',
    );
  }
}

enum MoulidSectionType { fathiha, prose, baith, qiyam, dua }

class MoulidSection {
  final int id;
  final int? page;
  final MoulidSectionType type;
  final String title;
  final String titleArabic;
  final String titleMalayalam;
  final String? arabic;
  final List<String> paragraphs;
  final String? refrain;
  final List<MoulidCouplet> couplets;

  const MoulidSection({
    required this.id,
    this.page,
    required this.type,
    required this.title,
    required this.titleArabic,
    required this.titleMalayalam,
    this.arabic,
    this.paragraphs = const [],
    this.refrain,
    this.couplets = const [],
  });

  factory MoulidSection.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'prose';
    final type = MoulidSectionType.values.firstWhere(
      (e) => e.name.toLowerCase() == typeStr.toLowerCase(),
      orElse: () => MoulidSectionType.prose,
    );

    final rawCouplets = json['couplets'] as List<dynamic>? ?? [];
    final couplets = rawCouplets
        .map((c) => MoulidCouplet.fromJson(c as Map<String, dynamic>))
        .toList();

    final rawParagraphs = json['paragraphs'] as List<dynamic>? ?? [];
    final paragraphs = rawParagraphs.map((p) => p.toString()).toList();

    return MoulidSection(
      id: json['id'] as int? ?? 0,
      page: json['page'] as int?,
      type: type,
      title: json['title'] as String? ?? '',
      titleArabic: json['titleArabic'] as String? ?? '',
      titleMalayalam: json['titleMalayalam'] as String? ?? '',
      arabic: json['arabic'] as String?,
      paragraphs: paragraphs,
      refrain: json['refrain'] as String?,
      couplets: couplets,
    );
  }
}

class MoulidDocument {
  final String id;
  final String title;
  final String titleArabic;
  final String titleMalayalam;
  final String author;
  final String authorEn;
  final String description;
  final List<MoulidSection> sections;

  const MoulidDocument({
    required this.id,
    required this.title,
    required this.titleArabic,
    required this.titleMalayalam,
    required this.author,
    required this.authorEn,
    required this.description,
    required this.sections,
  });

  factory MoulidDocument.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'] as List<dynamic>? ?? [];
    final sections = rawSections
        .map((s) => MoulidSection.fromJson(s as Map<String, dynamic>))
        .toList();

    return MoulidDocument(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      titleArabic: json['titleArabic'] as String? ?? '',
      titleMalayalam: json['titleMalayalam'] as String? ?? '',
      author: json['author'] as String? ?? '',
      authorEn: json['authorEn'] as String? ?? '',
      description: json['description'] as String? ?? '',
      sections: sections,
    );
  }
}
