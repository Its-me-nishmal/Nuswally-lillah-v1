/// Gregorian → Hijri conversion using the tabular (Kuwaiti) Islamic calendar.
///
/// This replaces the previous fixed-29-day-month approximation, which drifted
/// roughly six days a year away from a hardcoded anchor date.
///
/// A tabular calendar is arithmetic, so it can sit one day either side of a
/// locally sighted date — that is inherent to the method, not a defect. Kerala
/// follows local sighting, so [HijriDate.today] takes an `offsetDays` nudge
/// that the user controls in Settings.
class HijriDate {
  final int year;
  final int month; // 1..12
  final int day; // 1..30

  const HijriDate(this.year, this.month, this.day);

  static const List<String> monthNames = [
    'Muharram',
    'Safar',
    'Rabi al-Awwal',
    'Rabi al-Thani',
    'Jumada al-Awwal',
    'Jumada al-Thani',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhu al-Qi'dah",
    'Dhu al-Hijjah',
  ];

  String get monthName => monthNames[(month - 1).clamp(0, 11)];

  /// e.g. `15 Rabi al-Awwal 1448 AH`
  String get formatted => '$day $monthName $year AH';

  /// Converts a Gregorian date, optionally shifted by [offsetDays].
  factory HijriDate.fromGregorian(DateTime date, {int offsetDays = 0}) {
    final shifted = DateTime(
      date.year,
      date.month,
      date.day,
    ).add(Duration(days: offsetDays));
    return HijriDate._fromJulianDay(
      _gregorianToJulianDay(shifted.year, shifted.month, shifted.day),
    );
  }

  factory HijriDate.today({int offsetDays = 0}) =>
      HijriDate.fromGregorian(DateTime.now(), offsetDays: offsetDays);

  static int _gregorianToJulianDay(int year, int month, int day) {
    var y = year;
    var m = month;
    if (m < 3) {
      y -= 1;
      m += 12;
    }
    final a = y ~/ 100;
    final b = 2 - a + a ~/ 4; // Gregorian correction
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day +
        b -
        1524;
  }

  /// Standard tabular-calendar arithmetic; 1948440 is the Julian day of
  /// 1 Muharram 1 AH (16 July 622 CE, civil epoch).
  factory HijriDate._fromJulianDay(int julianDay) {
    final l0 = julianDay - 1948440 + 10632;
    final n = (l0 - 1) ~/ 10631;
    var l = l0 - 10631 * n + 354;
    final j =
        ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) +
        (l ~/ 5670) * ((43 * l) ~/ 15238);
    l =
        l -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) +
        29;
    final month = (24 * l) ~/ 709;
    final day = l - (709 * month) ~/ 24;
    final year = 30 * n + j - 30;
    return HijriDate(year, month, day);
  }
}
