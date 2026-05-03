class HaddadItem {
  final int id;
  final String arabic;
  final String translation;
  final int count;

  HaddadItem({
    required this.id,
    required this.arabic,
    required this.translation,
    required this.count,
  });

  factory HaddadItem.fromJson(Map<String, dynamic> json) {
    return HaddadItem(
      id: json['id'],
      arabic: json['arabic'],
      translation: json['translation'],
      count: json['count'],
    );
  }
}
