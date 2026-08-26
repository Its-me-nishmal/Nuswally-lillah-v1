import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/prayer_time_model.dart';
import 'app_update_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Function(String? actionId, String payload)? onActionClicked;

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    
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

    try {
      await _notificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload ?? '';
          final actionId = response.actionId;
          
          debugPrint('Notification Action Triggered: $actionId for payload: $payload');
          onActionClicked?.call(actionId, payload);
        },
      );
    } catch (e) {
      debugPrint('NotificationService: Plugin initialize error: $e');
    }

    // Create notification channels for custom Azan sounds
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      try {
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
      } catch (e) {
        debugPrint('NotificationService: Failed to create adhan_full_channel: $e');
      }

      try {
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
      } catch (e) {
        debugPrint('NotificationService: Failed to create adhan_chime_channel: $e');
      }

      try {
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
      } catch (e) {
        debugPrint('NotificationService: Failed to create silent_upcoming_channel: $e');
      }

      try {
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
      } catch (e) {
        debugPrint('NotificationService: Failed to create adhan_default_channel: $e');
      }

      try {
        // Create channel for app updates
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'app_update_channel',
            'App Updates',
            description: 'Notifications for new app updates and releases',
            importance: Importance.high,
            playSound: true,
          ),
        );
      } catch (e) {
        debugPrint('NotificationService: Failed to create app_update_channel: $e');
      }
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
    bool enabled = true,
    int preAzanReminderMinutes = 0,
    // Optional legacy fallback parameters
    Map<String, String>? adhanSounds,
    Map<String, int>? adhanOffsets,
    Map<String, String>? iqamahSounds,
    Map<String, int>? iqamahOffsets,
    Map<String, int>? iqamahNotificationOffsets,
    Set<String>? temporarilyMutedAlerts,
  }) async {
    // Cancel all previously scheduled alarms to avoid overlapping schedules
    await _notificationsPlugin.cancelAll();

    if (!enabled) {
      debugPrint('NotificationService: Azan notifications are disabled.');
      return;
    }

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

    debugPrint('NotificationService: Scheduling Azan alarms (Pre-Azan delay: $preAzanReminderMinutes min, Mode: ${scheduleMode.name})...');

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

          // Apply pre-azan delay offset if configured (e.g. 0, 3, 10, 30, 60 min)
          final triggerTime = preAzanReminderMinutes > 0
              ? prayerDateTime.subtract(Duration(minutes: preAzanReminderMinutes))
              : prayerDateTime;

          if (triggerTime.isAfter(tzNow)) {
            final title = preAzanReminderMinutes == 0
                ? 'Time for $prayerName Prayer 🕌'
                : '$prayerName Prayer in $preAzanReminderMinutes min 🕌';
            final body = preAzanReminderMinutes == 0
                ? "Hayya 'alas-Salah (Come to Prayer) • $timeStr"
                : "Azan will be called at $timeStr ($preAzanReminderMinutes minutes remaining)";

            const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
              'adhan_full_channel',
              'Adhan Alarms',
              channelDescription: 'Alarms sounding for daily Azan prayer times',
              importance: Importance.max,
              priority: Priority.high,
              sound: RawResourceAndroidNotificationSound('adhan'),
              playSound: true,
              ongoing: false,
            );

            await _notificationsPlugin.zonedSchedule(
              id: idCounter++,
              title: title,
              body: body,
              scheduledDate: triggerTime,
              notificationDetails: const NotificationDetails(android: androidDetails),
              androidScheduleMode: scheduleMode,
              payload: prayerName,
            );
          }
        } catch (e) {
          debugPrint('Error scheduling Azan alarm for $prayerName on $dateStr: $e');
        }
      }
    }
    debugPrint('NotificationService: Azan alarms scheduled successfully!');
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

  static Future<void> silenceAllAlarmsAndAzan() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('NotificationService: All notification alarms and Azan sound silenced.');
    } catch (e) {
      debugPrint('NotificationService: Error silencing alarms: $e');
    }
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

  /// Displays a heads-up notification when a new update is available
  static Future<void> showUpdateNotification(AppUpdateInfo info) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'app_update_channel',
      'App Updates',
      channelDescription: 'Notifications for new app updates and releases',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'open_update',
          'Update Now 🚀',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      id: 3001,
      title: '✨ Nuswally Lillah Update Available',
      body: 'New version v${info.versionName} is ready with fresh features and improvements. Tap to update!',
      notificationDetails: platformDetails,
      payload: 'app_update',
    );
  }

  /// Performs live check against remote API and triggers notification if update exists
  static Future<void> checkAndNotifyUpdates() async {
    try {
      debugPrint('NotificationService: Checking for daily app updates in background...');
      final updateInfo = await AppUpdateService.fetchUpdateInfo(forceRemote: true);
      if (updateInfo != null && AppUpdateService.isUpdateAvailable(updateInfo)) {
        debugPrint('NotificationService: Update found (v${updateInfo.versionName}). Triggering notification.');
        await showUpdateNotification(updateInfo);
      } else {
        debugPrint('NotificationService: App is on latest version.');
      }
    } catch (e) {
      debugPrint('NotificationService: Daily update check error: $e');
    }
  }

  /// Schedules daily 6:00 AM background update check & triggers if 24h passed
  static Future<void> scheduleDaily6AMUpdateCheck() async {
    try {
      final tzNow = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        tzNow.year,
        tzNow.month,
        tzNow.day,
        6, // 6:00 AM
        0,
      );

      if (scheduledDate.isBefore(tzNow)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Check if 24 hours have elapsed since last check to perform live check
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt('last_daily_update_check_timestamp') ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      if (nowMs - lastCheck > 24 * 60 * 60 * 1000) {
        await prefs.setInt('last_daily_update_check_timestamp', nowMs);
        checkAndNotifyUpdates();
      }
    } catch (e) {
      debugPrint('NotificationService: scheduleDaily6AMUpdateCheck error: $e');
    }
  }
}
