import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Forces India Standard Time for the whole app (notifications, scheduling, API).
///
/// Device OS timezone cannot be changed; this sets the app's logical clock to
/// [Asia/Kolkata] (IST, UTC+05:30) on every cold start.
abstract final class AppTimeZone {
  static const String ianaId = 'Asia/Kolkata';
  static const String displayName = 'India Standard Time (IST)';

  static bool _ready = false;

  /// Call once at bootstrap — before notifications or any scheduled work.
  static Future<void> ensureInitialized() async {
    if (_ready) return;

    tzdata.initializeTimeZones();
    final tz.Location india = tz.getLocation(ianaId);
    tz.setLocalLocation(india);

    // DateFormat / intl default — India locale for calendar formatting.
    Intl.defaultLocale = 'en_IN';

    _ready = true;

    final tz.TZDateTime now = tz.TZDateTime.now(india);
    debugPrint(
      '[AppTimeZone] $ianaId | now=$now | offset=${now.timeZoneOffset}',
    );
  }

  static tz.Location get location {
    if (!_ready) {
      // Safe fallback if called before bootstrap (should not happen).
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(ianaId));
      _ready = true;
    }
    return tz.getLocation(ianaId);
  }

  /// Current instant in India Standard Time.
  static tz.TZDateTime now() => tz.TZDateTime.now(location);

  /// IANA id for API headers / WebView context.
  static String get headerValue => ianaId;
}
