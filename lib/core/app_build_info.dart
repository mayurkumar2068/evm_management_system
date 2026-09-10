import 'package:evm_management_system/config/app_config.dart';
import 'package:evm_management_system/config/environment_config.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:get/get.dart';

/// Marketing version and build number shown in Profile / About.
///
/// Keep in sync with `pubspec.yaml` `version:` (`name+build`). Flutter copies
/// these into the native binary (`versionName` / `CFBundleShortVersionString`
/// and `versionCode` / `CFBundleVersion`).
abstract final class AppBuildInfo {
  static const String versionName = '1.0.0';
  static const String buildNumber = '2';

  /// e.g. `1.0.0 (2)` — the store-style version line.
  static String get versionWithBuild => '$versionName ($buildNumber)';

  /// DEV / UAT / PROD from the active flavor.
  static String get flavorLabel {
    if (Get.isRegistered<EnvironmentConfig>()) {
      return AppServices.config.flavor.label;
    }
    return AppConfig.environment.label;
  }
}
