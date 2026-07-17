import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/app.dart';
import 'package:evm_management_system/config/environment_config.dart';
import 'package:evm_management_system/config/flavor.dart';
import 'package:evm_management_system/core/database/json_local_database.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/settings/settings_service.dart';
import 'package:evm_management_system/core/storage/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

/// Boots [EvmApp] with GetX services registered for integration tests.
Future<void> pumpEvmAppForTest({required bool onboardingSeen}) async {
  await EasyLocalization.ensureInitialized();
  await dotenv.load(fileName: Flavor.dev.envFile);
  final EnvironmentConfig config = EnvironmentConfig.load(Flavor.dev);
  final JsonLocalDatabase db = JsonLocalDatabase();
  await db.init();
  final SecureStorageService secureStorage = SecureStorageService();
  final AppSettingsService settingsService = AppSettingsService(secureStorage);

  // Get.reset() is synchronous; awaiting it triggers a linter error.
  Get.reset();

  await AppServices.register(
    config: config,
    database: db,
    secureStorage: secureStorage,
    onboardingSeen: onboardingSeen,
    settingsService: settingsService,
    initialLocale: const Locale('en'),
    initialThemeMode: ThemeMode.light,
  );
}
