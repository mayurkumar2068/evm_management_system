import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/localization/locale_keys.dart';

extension DateTimeExtensions on DateTime {
  /// Returns a localized relative time string (e.g., "Just Now", "2 minutes ago").
  String get relativeTime {
    final Duration d = DateTime.now().difference(this);
    if (d.inMinutes < 1) return LocaleKeys.timeJustNow.tr();
    if (d.inMinutes < 60) {
      return LocaleKeys.timeMinutes.tr(args: <String>['${d.inMinutes}']);
    }
    if (d.inHours < 24) {
      return LocaleKeys.timeHours.tr(args: <String>['${d.inHours}']);
    }
    return LocaleKeys.timeDays.tr(args: <String>['${d.inDays}']);
  }
}
