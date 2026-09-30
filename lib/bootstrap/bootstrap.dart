import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:MPSECNET/config/environment_config.dart';
import 'package:MPSECNET/config/flavor.dart';
import 'package:MPSECNET/core/cache/app_startup_cache.dart';
import 'package:MPSECNET/core/database/json_local_database.dart';
import 'package:MPSECNET/core/database/local_database.dart';
import 'package:MPSECNET/core/di/app_services.dart';
import 'package:MPSECNET/app/app.dart';
import 'package:MPSECNET/core/logging/app_logger.dart';
import 'package:MPSECNET/core/media/configure_app_image_picker.dart';
import 'package:MPSECNET/core/settings/settings_service.dart';
import 'package:MPSECNET/core/storage/secure_storage_service.dart';
import 'package:MPSECNET/core/time/app_time_zone.dart';
import 'package:MPSECNET/core/utils/app_locale_holder.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/notifications/notification_service.dart';

/// [env] must be the constant map for [flavor] — see
/// [EnvironmentConfig.load] for why callers pass it in rather than resolving
/// it here.
Future<void> bootstrap(Flavor flavor, Map<String, String> env) async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      configureAppImagePicker();
      await AppTimeZone.ensureInitialized();
      await EasyLocalization.ensureInitialized();
      WidgetsFlutterBinding.ensureInitialized();

      await LocalNotificationService.instance.initialize();
      final EnvironmentConfig config = EnvironmentConfig.load(flavor, env);

      GoogleFonts.config.allowRuntimeFetching = false;

      AppLogger.configure(
        enabled: config.enableLogging,
        verbose: !config.isProduction,
      );

      await AppStartupCache.clearOnLaunch();
      if (!config.isProduction) {
        // ignore: avoid_print
        print(
          '[ENV] ${flavor.label} | '
          'po=${config.poElectionApiBaseUrl} | '
          'surveyApi=${config.surveyApiBaseUrl} | '
          'surveyWeb=${config.surveyWebBaseUrl}',
        );
      }
      AppLogger.i(
        'Bootstrapping ${flavor.label} '
        'api=${config.apiBaseUrl} '
        'po=${config.poElectionApiBaseUrl} '
        'surveyApi=${config.surveyApiBaseUrl} '
        'surveyWeb=${config.surveyWebBaseUrl}',
      );

      final LocalDatabase database = JsonLocalDatabase();
      await database.init();

      final SecureStorageService secureStorage = SecureStorageService();
      const bool onboardingSeen = true;
      try {
        await secureStorage.write(SecureStorageKeys.onboardingSeen, 'true');
      } catch (_) {}

      FlutterError.onError = (FlutterErrorDetails details) {
        AppLogger.e(
          'FlutterError',
          error: details.exception,
          stackTrace: details.stack,
        );
      };

      final AppSettingsService settingsService = AppSettingsService(
        secureStorage,
      );
      final Locale appLocale = _resolveStartupLocale(
        await settingsService.loadLocale(),
      );
      AppLocaleHolder.code = appLocale.languageCode;
      final ThemeMode savedTheme = await settingsService.loadThemeMode();

      await AppServices.register(
        config: config,
        database: database,
        secureStorage: secureStorage,
        onboardingSeen: onboardingSeen,
        settingsService: settingsService,
        initialLocale: appLocale,
        initialThemeMode: savedTheme,
      );

      runApp(
        EasyLocalization(
          supportedLocales: const <Locale>[Locale('hi'), Locale('en')],
          path: 'assets/translations',
          fallbackLocale: const Locale('hi'),
          startLocale: appLocale,
          saveLocale: false,
          child: const EvmApp(),
        ),
      );
    },
    (Object error, StackTrace stack) {
      AppLogger.e('Uncaught zone error', error: error, stackTrace: stack);
    },
  );
}

Locale _resolveStartupLocale(Locale? saved) {
  final String code = saved?.languageCode ?? 'hi';
  if (code == 'en' || code == 'hi') return Locale(code);
  return const Locale('hi');
}
