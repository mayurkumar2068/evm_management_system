import 'dart:io';

import 'package:evm_management_system/core/time/app_time_zone.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

enum PollingAreaType { urban, rural }

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

  static Future<void> scheduleTestInMinutes({int minutes = 10}) async {
    await LocalNotificationService.instance.scheduleInMinutes(
      id: 998,
      minutes: minutes,
      title: 'परीक्षण सूचना',
      body:
          'सूचना परीक्षण सफल। यह $minutes मिनट बाद आने के लिए शेड्यूल की गई थी।',
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

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'voter_turnout_reporting';
  static const String _channelName = 'मतदान अपडेट रिमाइंडर';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    await AppTimeZone.ensureInitialized();

    const DarwinInitializationSettings darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
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
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        AppLogger.d('Notification tapped: ${response.payload}');
      },
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: '2-2 घंटे की मतदान जानकारी अपडेट रिमाइंडर',
        importance: Importance.max,
      ),
    );

    _initialized = true;
  }

  Future<void> _ensureRuntimePermissions() async {
    await initialize();
    if (kIsWeb) return;

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
      return;
    }

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleInMinutes({
    required int id,
    required int minutes,
    required String title,
    required String body,
  }) async {
    await initialize();
    await _ensureRuntimePermissions();

    final tz.TZDateTime when = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(minutes: minutes));

    await _plugin.cancel(id: id);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    AppLogger.d(
      '[Notification] one-shot id=$id scheduled at $when '
      '(in ${minutes}m, tz=${tz.local.name})',
    );

    final List<PendingNotificationRequest> pending = await _plugin
        .pendingNotificationRequests();
    AppLogger.d('[Notification] pending count=${pending.length}');
    for (final PendingNotificationRequest item in pending) {
      AppLogger.d('[Notification] pending ID:${item.id} Title:${item.title}');
    }
  }

  static const List<int> _urbanHours = [9, 11, 13, 15, 17];
  static const List<int> _ruralHours = [9, 11, 13, 15];

  Future<void> scheduleDailyReminders({
    required PollingAreaType areaType,
  }) async {
    await initialize();
    await _ensureRuntimePermissions();

    await _cancelReminderNotifications();

    final List<int> hours = areaType == PollingAreaType.urban
        ? _urbanHours
        : _ruralHours;

    for (int i = 0; i < hours.length; i++) {
      await _scheduleReminder(
        id: 100 + i,
        areaType: areaType,
        hour: hours[i],
        minute: 0,
      );
    }

    final pending = await _plugin.pendingNotificationRequests();

    AppLogger.d('Scheduled ${hours.length} ${areaType.name} reminders');

    for (final item in pending) {
      AppLogger.d('ID:${item.id}  Title:${item.title}');
    }
  }

  Future<void> _scheduleReminder({
    required int id,
    required PollingAreaType areaType,
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
      title: _reminderTitle(areaType: areaType, hour: hour),
      body: _reminderBody(areaType: areaType, hour: hour, minute: minute),
      scheduledDate: scheduled,
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  String _reminderTitle({
    required PollingAreaType areaType,
    required int hour,
  }) {
    if (areaType == PollingAreaType.urban && hour == 17) {
      return 'मतदान अपडेट (5 बजे) आवश्यक';
    }
    return 'मतदान अपडेट आवश्यक';
  }

  String _reminderBody({
    required PollingAreaType areaType,
    required int hour,
    required int minute,
  }) {
    final String slot = _formatTime(hour, minute);
    final bool isUrbanFinalSlot =
        areaType == PollingAreaType.urban && hour == 17;
    if (isUrbanFinalSlot) {
      return 'कृपया $slot तक का मतदान प्रतिशत अभी दर्ज करें। यह नगरीय क्षेत्र की अंतिम 2-2 घंटे की प्रविष्टि है।';
    }
    return 'कृपया $slot तक की 2-2 घंटे की मतदान जानकारी अभी भरें। यह रीयल-टाइम मॉनिटरिंग के लिए आवश्यक है।';
  }

  Future<void> _cancelReminderNotifications() async {
    for (int id = 100; id <= 104; id++) {
      await _plugin.cancel(id: id);
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  String _formatTime(int hour, int minute) {
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
    await _ensureRuntimePermissions();

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
        channelDescription: '2-2 घंटे की मतदान जानकारी अपडेट रिमाइंडर',
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
