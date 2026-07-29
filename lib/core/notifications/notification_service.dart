import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum PollingAreaType {
  urban,
  rural,
}

class NotificationUtils {
  NotificationUtils._();

  static Future<void> initialize() async {
    await LocalNotificationService.instance.initialize();
  }

  static Future<void> showTestNotification() async {
    await LocalNotificationService.instance.showNotification(
      id: 999,
      title: 'Test Notification',
      body: 'Local notification is working successfully.',
    );
  }

  static Future<void> scheduleDailyReminders({
    required PollingAreaType areaType,
  }) async {
    await LocalNotificationService.instance.scheduleDailyReminders(
      areaType: areaType,
    );
  }
}

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance =
  LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const String _channelId = 'voter_turnout_reporting';
  static const String _channelName = 'Voter Turnout Reporting';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (_) {}

    const DarwinInitializationSettings darwin =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: darwin,
      macOS: darwin,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse:
          (NotificationResponse response) {
        debugPrint(
          'Notification tapped: ${response.payload}',
        );
      },
    );

    final android =
    _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Voter Turnout Reminder',
        importance: Importance.max,
      ),
    );

    if (!kIsWeb && Platform.isAndroid) {
      await android?.requestExactAlarmsPermission();
    }

    final granted = await _plugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint("iOS Permission : $granted");

    _initialized = true;
  }

  // ============================
  // Daily Reminder Scheduling
  // ============================

  static const List<int> _urbanHours = [9, 11, 13, 15, 17];
  static const List<int> _ruralHours = [9, 11, 13, 15];

  Future<void> scheduleDailyReminders({
    required PollingAreaType areaType,
  }) async {
    await initialize();

    // Remove previously scheduled reminder notifications only
    await _cancelReminderNotifications();

    final List<int> hours = areaType == PollingAreaType.urban
        ? _urbanHours
        : _ruralHours;

    for (int i = 0; i < hours.length; i++) {
      await _scheduleReminder(
        id: 100 + i,
        hour: hours[i],
        minute: 0,
      );
    }

    final pending = await _plugin.pendingNotificationRequests();

    debugPrint(
      'Scheduled ${hours.length} ${areaType.name} reminders',
    );

    for (final item in pending) {
      debugPrint(
        'ID:${item.id}  Title:${item.title}',
      );
    }
  }

  Future<void> _scheduleReminder({
    required int id,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      title: 'Voter Turnout Update',
      body:
      'Please submit voter turnout percentage recorded up to ${_formatTime(
          hour, minute)}.',
      scheduledDate: scheduled,
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ============================
  // Cancel only reminder IDs
  // ============================

  Future<void> _cancelReminderNotifications() async {
    for (int id = 100; id <= 104; id++) {
      await _plugin.cancel(id: id);
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ============================
  // Helper
  // ============================

  String _formatTime(int hour,
      int minute,) {
    final period = hour >= 12 ? 'PM' : 'AM';

    final displayHour = switch (hour) {
      0 => 12,
      > 12 => hour - 12,
      _ => hour,
    };

    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }


  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await initialize();

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _notificationDetails(),
    );
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Voter Turnout Reminder',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableLights: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
      ),
    );
  }
}