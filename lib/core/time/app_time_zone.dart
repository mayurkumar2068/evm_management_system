import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

abstract final class AppTimeZone {
  static const String ianaId = 'Asia/Kolkata';
  static const String displayName = 'India Standard Time (IST)';

  static bool _ready = false;

  static Future<void> ensureInitialized() async {
    if (_ready) return;

    tzdata.initializeTimeZones();
    final tz.Location india = tz.getLocation(ianaId);
    tz.setLocalLocation(india);

    Intl.defaultLocale = 'en_IN';

    _ready = true;

    final tz.TZDateTime now = tz.TZDateTime.now(india);
    AppLogger.d(
      '[AppTimeZone] $ianaId | now=$now | offset=${now.timeZoneOffset}',
    );
  }

  static tz.Location get location {
    if (!_ready) {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(ianaId));
      _ready = true;
    }
    return tz.getLocation(ianaId);
  }

  static tz.TZDateTime now() => tz.TZDateTime.now(location);

  static tz.TZDateTime fromDateTime(DateTime dateTime) =>
      tz.TZDateTime.from(dateTime, location);

  static DateTime calendarDate([DateTime? dateTime]) {
    final tz.TZDateTime ist = dateTime == null ? now() : fromDateTime(dateTime);
    return DateTime(ist.year, ist.month, ist.day);
  }

  static String get headerValue => ianaId;
}
