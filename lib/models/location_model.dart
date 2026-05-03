class District {
  final int id;
  final String name;
  final List<Location> locations;

  District({
    required this.id,
    required this.name,
    required this.locations,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'],
      name: json['name'],
      locations: (json['locations'] as List)
          .map((i) => Location.fromJson(i, json['name']))
          .toList(),
    );
  }
}

class Location {
  final int id;
  final String name;
  final String district;

  Location({
    required this.id,
    required this.name,
    required this.district,
  });

  factory Location.fromJson(Map<String, dynamic> json, String districtName) {
    return Location(
      id: json['id'],
      name: json['name'],
      district: districtName,
    );
  }
}
