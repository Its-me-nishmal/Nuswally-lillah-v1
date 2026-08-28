/// Formats a bundled prayer time for display.
///
/// The Kerala dataset stores **12-hour clock values with no meridiem**
/// (`"asr": "3:50"`, `"maghrib": "6:18"`), so AM/PM cannot be derived from the
/// hour alone — which prayer it is decides it. A value above 12 is treated as
/// unambiguous 24-hour time so the function is safe if the data ever changes.
String formatPrayerTime(String prayerName, String raw) {
  final parts = raw.split(':');
  if (parts.length < 2) return raw;
  final hour = int.tryParse(parts[0].trim());
  final minute = int.tryParse(parts[1].trim());
  if (hour == null || minute == null) return raw;

  final bool isPm;
  if (hour > 12) {
    isPm = true; // 24-hour value.
  } else if (hour == 12) {
    isPm = prayerName != 'Fajr' && prayerName != 'Sunrise';
  } else {
    switch (prayerName) {
      case 'Fajr':
      case 'Sunrise':
        isPm = false;
      case 'Dhuhr':
        // Dhuhr can legitimately fall at 11:xx in the morning.
        isPm = hour != 11;
      default:
        // Asr, Maghrib, Isha are always afternoon/evening here.
        isPm = true;
    }
  }

  var displayHour = hour > 12 ? hour - 12 : hour;
  if (displayHour == 0) displayHour = 12;

  return '$displayHour:${minute.toString().padLeft(2, '0')} ${isPm ? 'PM' : 'AM'}';
}

/// Parses a bundled prayer time into 24-hour components, applying the same
/// name-based meridiem rules as [formatPrayerTime]. Returns null if the value
/// cannot be read.
({int hour, int minute})? parsePrayerTime24(String prayerName, String raw) {
  final parts = raw.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0].trim());
  final minute = int.tryParse(parts[1].trim());
  if (hour == null || minute == null) return null;

  if (hour > 12) return (hour: hour, minute: minute);

  final bool isPm;
  if (hour == 12) {
    isPm = prayerName != 'Fajr' && prayerName != 'Sunrise';
  } else {
    switch (prayerName) {
      case 'Fajr':
      case 'Sunrise':
        isPm = false;
      case 'Dhuhr':
        isPm = hour != 11;
      default:
        isPm = true;
    }
  }

  var hour24 = hour % 12;
  if (isPm) hour24 += 12;
  return (hour: hour24, minute: minute);
}

/// Formats a 24-hour hour/minute pair as `h:mm AM/PM`.
String format24(int hour, int minute) {
  var displayHour = hour % 12;
  if (displayHour == 0) displayHour = 12;
  return '$displayHour:${minute.toString().padLeft(2, '0')} '
      '${hour >= 12 ? 'PM' : 'AM'}';
}
