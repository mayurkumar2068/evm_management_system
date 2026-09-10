import 'package:evm_management_system/config/app_config.dart';
import 'package:evm_management_system/config/environment_config.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:get/get.dart';

abstract final class AppBuildInfo {
  static const String versionName = '1.0.0';
  static const String buildNumber = '2';

  static String get versionWithBuild => '$versionName ($buildNumber)';

  static String get flavorLabel {
    if (Get.isRegistered<EnvironmentConfig>()) {
      return AppServices.config.flavor.label;
    }
    return AppConfig.environment.label;
  }
}
