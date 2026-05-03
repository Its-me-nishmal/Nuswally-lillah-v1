class LocationData {
  final LocationInfo location;
  final List<PrayerTime> prayerTimes;

  LocationData({
    required this.location,
    required this.prayerTimes,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      location: LocationInfo.fromJson(json['location']),
      prayerTimes: (json['prayer_times'] as List)
          .map((i) => PrayerTime.fromJson(i))
          .toList(),
    );
  }
}

class LocationInfo {
  final int id;
  final String name;
  final String district;
  final String state;
  final String country;

  LocationInfo({
    required this.id,
    required this.name,
    required this.district,
    required this.state,
    required this.country,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      id: json['id'],
      name: json['name'],
      district: json['district'],
      state: json['state'],
      country: json['country'],
    );
  }
}

class PrayerTime {
  final String date; // MM-DD
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;

  PrayerTime({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  factory PrayerTime.fromJson(Map<String, dynamic> json) {
    return PrayerTime(
      date: json['date'],
      fajr: json['fajr'],
      sunrise: json['sunrise'],
      dhuhr: json['dhuhr'],
      asr: json['asr'],
      maghrib: json['maghrib'],
      isha: json['isha'],
    );
  }
}
