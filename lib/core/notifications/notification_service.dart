import 'package:evm_management_system/core/logging/app_logger.dart';

/// A normalized push/local notification message.
class AppNotificationMessage {
  const AppNotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    this.deepLink,
    this.data = const <String, dynamic>{},
  });

  final String id;
  final String title;
  final String body;

  /// Optional route to navigate to when the notification is tapped.
  final String? deepLink;
  final Map<String, dynamic> data;
}

/// Push-notification contract covering foreground, background and terminated
/// delivery plus tap-driven navigation.
///
/// Abstracted so the FCM implementation can be added (with
/// `firebase_messaging` + native setup) without changing callers.
abstract interface class NotificationService {
  /// Requests permission and registers the device token.
  Future<void> initialize();

  /// Stream of messages received while the app is in the foreground.
  Stream<AppNotificationMessage> get onForegroundMessage;

  /// Stream of deep links produced when a notification is tapped (from
  /// background or terminated state).
  Stream<String> get onNotificationTap;

  /// The current device push token, used to register with the backend.
  Future<String?> deviceToken();
}

/// Inert default used until FCM is configured for the build.
class NoopNotificationService implements NotificationService {
  NoopNotificationService();

  final Stream<AppNotificationMessage> _foreground =
      const Stream<AppNotificationMessage>.empty();
  final Stream<String> _taps = const Stream<String>.empty();

  @override
  Future<void> initialize() async {
    AppLogger.i('NotificationService: initialize (noop)');
  }

  @override
  Stream<AppNotificationMessage> get onForegroundMessage => _foreground;

  @override
  Stream<String> get onNotificationTap => _taps;

  @override
  Future<String?> deviceToken() async => null;
}
