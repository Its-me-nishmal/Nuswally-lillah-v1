import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/prayer_time_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Function(String? actionId, String payload)? onActionClicked;

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // Initialize timezone database
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('NotificationService: Local timezone initialized to $timeZoneName');
    } catch (e) {
      debugPrint('NotificationService: Failed to get local timezone, falling back to Asia/Kolkata: $e');
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    }

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload ?? '';
        final actionId = response.actionId;
        
        debugPrint('Notification Action Triggered: $actionId for payload: $payload');
        onActionClicked?.call(actionId, payload);
      },
    );

    // Create notification channels for custom Azan sounds
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Create channel for Full Adhan
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'adhan_full_channel',
          'Adhan Full Alarm',
          description: 'Alarms that play the full Adhan sound',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('adhan'),
          playSound: true,
        ),
      );

      // Create channel for Chime
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'adhan_chime_channel',
          'Adhan Chime Alarm',
          description: 'Alarms that play the Chime sound',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('chime'),
          playSound: true,
        ),
      );

      // Create channel for silent notifications
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'silent_upcoming_channel',
          'Silent Upcoming Reminders',
          description: 'Silent reminders shown 10 minutes before prayer alerts',
          importance: Importance.low,
          playSound: false,
        ),
      );

      // Create channel for default system alarms
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'adhan_default_channel',
          'Default Adhan Alarms',
          description: 'Alarms that use the default system sound',
          importance: Importance.max,
          playSound: true,
        ),
      );
    }
  }

  static Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Request standard notification posting permission (required for Android 13+)
      try {
        await androidImplementation.requestNotificationsPermission();
      } catch (e) {
        debugPrint('NotificationService: Error requesting notifications permission: $e');
      }

      // Request exact alarm permission (required for Android 13/14+)
      try {
        final bool? isExactAlarmPermitted = await androidImplementation.canScheduleExactNotifications();
        if (isExactAlarmPermitted == false) {
          debugPrint('NotificationService: Exact alarms not permitted. Prompting user...');
          await androidImplementation.requestExactAlarmsPermission();
        } else {
          debugPrint('NotificationService: Exact alarms permission is already granted.');
        }
      } catch (e) {
        debugPrint('NotificationService: Error checking or requesting exact alarm permission: $e');
      }
    }
  }

  static Future<void> schedulePrayerNotifications({
    required List<PrayerTime> prayerTimes,
    required Map<String, String> adhanSounds,
    required Map<String, int> adhanOffsets,
    required Map<String, String> iqamahSounds,
    required Map<String, int> iqamahOffsets,
    required Map<String, int> iqamahNotificationOffsets,
    required Set<String> temporarilyMutedAlerts,
  }) async {
    // Cancel all previously scheduled alarms to avoid overlapping schedules
    await _notificationsPlugin.cancelAll();

    final now = DateTime.now();
    final tzNow = tz.TZDateTime.now(tz.local);
    int idCounter = 10000; // Offset for scheduled IDs to avoid overlaps with immediate ones

    // Determine the optimal Android schedule mode based on granted permissions
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    bool isExactPermitted = true;
    try {
      isExactPermitted = (await androidImplementation?.canScheduleExactNotifications()) ?? true;
    } catch (e) {
      debugPrint('NotificationService: Error querying exact alarm permission: $e');
    }

    final AndroidScheduleMode scheduleMode = isExactPermitted 
        ? AndroidScheduleMode.exactAllowWhileIdle 
        : AndroidScheduleMode.inexactAllowWhileIdle;

    debugPrint('NotificationService: Scheduling prayer alarms (Mode: ${scheduleMode.name}) starting from today...');

    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      final dateStr = DateFormat('MM-dd').format(targetDate);

      // Find the prayer time for this date
      final PrayerTime? dayTimes = prayerTimes.cast<PrayerTime?>().firstWhere(
        (element) => element?.date == dateStr,
        orElse: () => null,
      );

      if (dayTimes == null) continue;

      final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

      for (var prayerName in prayers) {
        String timeStr = '';
        if (prayerName == 'Fajr') {
          timeStr = dayTimes.fajr;
        } else if (prayerName == 'Dhuhr') {
          timeStr = dayTimes.dhuhr;
        } else if (prayerName == 'Asr') {
          timeStr = dayTimes.asr;
        } else if (prayerName == 'Maghrib') {
          timeStr = dayTimes.maghrib;
        } else if (prayerName == 'Isha') {
          timeStr = dayTimes.isha;
        }

        if (timeStr.isEmpty) continue;

        try {
          final parts = timeStr.split(':');
          var hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);

          // Adjust for PM hours
          if (prayerName == 'Dhuhr') {
            if (hour < 11) hour += 12;
          } else if (prayerName != 'Fajr') {
            hour += 12;
          }

          // Build exact TZDateTime
          final prayerDateTime = tz.TZDateTime(
            tz.local,
            targetDate.year,
            targetDate.month,
            targetDate.day,
            hour,
            minute,
          );

          // ------------------ ADHAN ALARM SCHEDULING ------------------
          final adhanOffset = adhanOffsets[prayerName] ?? 0;
          final adhanSound = adhanSounds[prayerName] ?? 'Default Alert';
          final isMuted = temporarilyMutedAlerts.contains(prayerName);

          final adhanAlarmTime = prayerDateTime.subtract(Duration(minutes: adhanOffset));

          if (adhanAlarmTime.isAfter(tzNow)) {
            if (adhanSound != 'Silent' && !isMuted) {
              String channelId = 'adhan_default_channel';
              String soundResource = '';

              if (adhanSound == 'Full Adhan') {
                channelId = 'adhan_full_channel';
                soundResource = 'adhan';
              } else if (adhanSound == 'Default Alert' || adhanSound == 'Chime') {
                channelId = 'adhan_chime_channel';
                soundResource = 'chime';
              }

              final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
                channelId,
                'Active Prayer Alarms',
                channelDescription: 'Alarms sounding for active prayer times',
                importance: Importance.max,
                priority: Priority.high,
                sound: soundResource.isNotEmpty 
                    ? RawResourceAndroidNotificationSound(soundResource)
                    : null,
                playSound: true,
                ongoing: true,
                actions: const <AndroidNotificationAction>[
                  AndroidNotificationAction(
                    'stop_active',
                    'STOP ALARM 🔇',
                    showsUserInterface: true,
                    cancelNotification: true,
                  ),
                ],
              );

              await _notificationsPlugin.zonedSchedule(
                id: idCounter++,
                title: '$prayerName Alarm Active! 🕌',
                body: 'Tap below to silence the alert sound instantly.',
                scheduledDate: adhanAlarmTime,
                notificationDetails: NotificationDetails(android: androidDetails),
                androidScheduleMode: scheduleMode,
                payload: prayerName,
              );
            }
          }

          // ------------------ UPCOMING ALERT SCHEDULING ------------------
          final upcomingTriggerTime = adhanAlarmTime.subtract(const Duration(minutes: 10));

          if (upcomingTriggerTime.isAfter(tzNow) && adhanSound != 'Silent' && !isMuted) {
            const AndroidNotificationDetails silentDetails = AndroidNotificationDetails(
              'silent_upcoming_channel',
              'Silent Upcoming Reminders',
              channelDescription: 'Silent reminders shown 10 minutes before prayer alerts',
              importance: Importance.low,
              priority: Priority.low,
              playSound: false,
              silent: true,
              actions: <AndroidNotificationAction>[
                AndroidNotificationAction(
                  'mute_upcoming',
                  'Mute Upcoming Sound 🔇',
                  showsUserInterface: true,
                  cancelNotification: false,
                ),
              ],
            );

            await _notificationsPlugin.zonedSchedule(
              id: idCounter++,
              title: 'Upcoming $prayerName Alert',
              body: 'Triggers in 10 minutes ($adhanSound)',
              scheduledDate: upcomingTriggerTime,
              notificationDetails: const NotificationDetails(android: silentDetails),
              androidScheduleMode: scheduleMode,
              payload: prayerName,
            );
          }

          // ------------------ IQAMAH ALARM SCHEDULING ------------------
          final iqamahOffset = iqamahOffsets[prayerName] ?? 20;
          final iqamahNotificationOffset = iqamahNotificationOffsets[prayerName] ?? 3;
          final iqamahSound = iqamahSounds[prayerName] ?? 'Chime';

          final iqamahTime = prayerDateTime.add(Duration(minutes: iqamahOffset));
          final iqamahAlarmTime = iqamahTime.subtract(Duration(minutes: iqamahNotificationOffset));

          if (iqamahAlarmTime.isAfter(tzNow) && iqamahSound != 'Silent') {
            String channelId = 'adhan_default_channel';
            String soundResource = '';

            if (iqamahSound == 'Default Alert' || iqamahSound == 'Chime') {
              channelId = 'adhan_chime_channel';
              soundResource = 'chime';
            }

            final AndroidNotificationDetails iqamahDetails = AndroidNotificationDetails(
              channelId,
              'Iqamah Alarms',
              channelDescription: 'Alarms sounding for Iqamah times',
              importance: Importance.max,
              priority: Priority.high,
              sound: soundResource.isNotEmpty 
                  ? RawResourceAndroidNotificationSound(soundResource)
                  : null,
              playSound: true,
            );

            await _notificationsPlugin.zonedSchedule(
              id: idCounter++,
              title: iqamahNotificationOffset > 0 
                  ? '$prayerName Iqamah in $iqamahNotificationOffset mins! 🕌' 
                  : '$prayerName Iqamah Active! 🕌',
              body: iqamahNotificationOffset > 0 
                  ? 'Iqamah congregation will start in $iqamahNotificationOffset minutes.'
                  : 'It is time for $prayerName Iqamah congregation.',
              scheduledDate: iqamahAlarmTime,
              notificationDetails: NotificationDetails(android: iqamahDetails),
              androidScheduleMode: scheduleMode,
              payload: prayerName,
            );
          }
        } catch (e) {
          debugPrint('Error scheduling alarms for $prayerName on $dateStr: $e');
        }
      }
    }
    debugPrint('NotificationService: Alarms scheduled successfully!');
  }

  static Future<void> showUpcomingNotification({
    required String prayerName,
    required int minutesRemaining,
    required String soundType,
    required bool isMuted,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'upcoming_prayer_channel',
      'Upcoming Prayer Alerts',
      channelDescription: 'Silent reminders shown 10 minutes before prayer alerts',
      importance: Importance.max,
      priority: Priority.high,
      silent: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'mute_upcoming',
          isMuted ? 'Unmute Upcoming Sound 🔊' : 'Mute Upcoming Sound 🔇',
          showsUserInterface: true,
          cancelNotification: false,
        ),
      ],
    );

    final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      id: 1001,
      title: 'Upcoming $prayerName Alert',
      body: isMuted 
          ? 'Alert is currently muted for this prayer call'
          : 'Triggers in $minutesRemaining minutes ($soundType)',
      notificationDetails: platformDetails,
      payload: prayerName,
    );
  }

  static Future<void> showActiveNotification(String prayerName) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'active_prayer_channel',
      'Active Prayer Alarms',
      channelDescription: 'Alarms sounding for active prayer times',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'stop_active',
          'STOP ALARM 🔇',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      id: 1002,
      title: '$prayerName Alarm Active! 🕌',
      body: 'Tap below to silence the alert sound instantly.',
      notificationDetails: platformDetails,
      payload: prayerName,
    );
  }

  static Future<void> showQuranPlaybackNotification({
    required String surahName,
    required int verseNum,
    required bool isPlaying,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'quran_playback_channel',
      'Quran Playback Control',
      channelDescription: 'Media playback notifications for the Holy Quran',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: isPlaying,
      showWhen: false,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          isPlaying ? 'pause_quran' : 'play_quran',
          isPlaying ? 'Pause ⏸' : 'Play ▶',
          showsUserInterface: true,
          cancelNotification: false,
        ),
        const AndroidNotificationAction(
          'stop_quran',
          'Stop ⏹',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      id: 2001,
      title: 'Reciting Surah $surahName',
      body: 'Verse $verseNum',
      notificationDetails: platformDetails,
      payload: surahName,
    );
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancel(id: 1001);
    await _notificationsPlugin.cancel(id: 1002);
  }

  static Future<void> cancelUpcoming() async {
    await _notificationsPlugin.cancel(id: 1001);
  }

  static Future<void> cancelActive() async {
    await _notificationsPlugin.cancel(id: 1002);
  }

  static Future<void> cancelQuranNotification() async {
    await _notificationsPlugin.cancel(id: 2001);
  }
}
