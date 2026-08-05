import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/config/environment_config.dart';
import 'package:evm_management_system/config/flavor.dart';
import 'package:evm_management_system/core/constants/feature_flags.dart';
import 'package:evm_management_system/core/database/json_local_database.dart';
import 'package:evm_management_system/core/database/local_database.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/app/app.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:evm_management_system/core/settings/settings_service.dart';
import 'package:evm_management_system/core/storage/secure_storage_service.dart';
import 'package:evm_management_system/core/time/app_time_zone.dart';
import 'package:evm_management_system/core/utils/app_locale_holder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/notifications/notification_service.dart';

/// Single composition root. Loads the flavor `.env`, initializes cross-cutting
/// services, wires GetX dependencies and starts the app inside a guarded zone.
Future<void> bootstrap(Flavor flavor) async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await AppTimeZone.ensureInitialized();
      await EasyLocalization.ensureInitialized();
      await GoogleFonts.pendingFonts(<TextStyle>[
        GoogleFonts.poppins(),
        GoogleFonts.notoSansDevanagari(),
      ]);
      WidgetsFlutterBinding.ensureInitialized();

      await LocalNotificationService.instance.initialize();
      await dotenv.load(fileName: flavor.envFile);
      final EnvironmentConfig config = EnvironmentConfig.load(flavor);

      AppLogger.configure(
        enabled: config.enableLogging,
        verbose: !config.isProduction,
      );
      // Always print endpoints so flavor/URL mixups are visible in debug consoles.
      // ignore: avoid_print
      print(
        '[ENV] ${flavor.label} | '
        'po=${config.poElectionApiBaseUrl} | '
        'surveyApi=${config.surveyApiBaseUrl} | '
        'surveyWeb=${config.surveyWebBaseUrl}',
      );
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
      bool onboardingSeen = kSkipOnboarding;
      if (!onboardingSeen) {
        try {
          onboardingSeen =
              (await secureStorage.read(SecureStorageKeys.onboardingSeen)) ==
              'true';
        } catch (_) {
          onboardingSeen = false;
        }
      } else {
        try {
          await secureStorage.write(SecureStorageKeys.onboardingSeen, 'true');
        } catch (_) {}
      }

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
