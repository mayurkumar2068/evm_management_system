import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/routes/app_pages.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/providers/session_event_bus.dart';
import 'package:evm_management_system/core/security/screen_security_service.dart';
import 'package:evm_management_system/core/webview/service/webview_warmer.dart';
import 'package:evm_management_system/core/security/session_timeout_manager.dart';
import 'package:evm_management_system/core/utils/app_locale_holder.dart';
import 'package:evm_management_system/features/auth/presentation/states/auth_state.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:permission_handler/permission_handler.dart';

/// Root application widget. Wires GetX navigation, theme and localization,
/// restores the session on first build, and reacts to session-expiry events.
class EvmApp extends StatefulWidget {
  const EvmApp({super.key});

  @override
  State<EvmApp> createState() => _EvmAppState();
}

class _EvmAppState extends State<EvmApp> {
  SessionTimeoutManager? _idleTimeout;
  Worker? _authWorker;
  Worker? _localeWorker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final config = AppServices.config;
      _idleTimeout = SessionTimeoutManager(timeout: config.sessionTimeout);

      Get.find<ScreenSecurityService>().enableSecureMode();
      unawaited(_requestRuntimePermissions());
      unawaited(Get.find<WebViewWarmer>().warm());

      Future<void>.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        AppServices.auth.restoreSession();
      });
      AppServices.syncManager.start();
      AppServices.offlineSync.start();
      AppServices.sessionBus.events.listen((SessionEvent event) {
        AppServices.auth.onSessionExpired();
      });

      _authWorker = ever<AuthState>(
        AppServices.auth.authState,
        (AuthState next) => _syncIdleTimeout(next),
      );
      _localeWorker = ever<Locale>(AppServices.settings.locale, (Locale next) {
        if (!mounted) return;
        if (context.locale != next) {
          context.setLocale(next);
        }
      });
    });
  }

  Future<void> _requestRuntimePermissions() async {
    try {
      await <Permission>[
        Permission.locationWhenInUse,
        Permission.camera,
      ].request();
    } on Exception catch (e) {
      debugPrint('Runtime permission request failed: $e');
    }
  }

  @override
  void dispose() {
    _authWorker?.dispose();
    _localeWorker?.dispose();
    _idleTimeout?.dispose();
    super.dispose();
  }

  void _syncIdleTimeout(AuthState next) {
    final SessionTimeoutManager? timeout = _idleTimeout;
    if (timeout == null) return;
    if (next.isAuthenticated) {
      timeout.start(() => AppServices.sessionBus.emit(SessionEvent.expired));
    } else {
      timeout.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLocaleHolder.code = context.locale.languageCode;

    return Obx(() {
      final ThemeMode themeMode = AppServices.settings.themeMode.value;
      AppServices.settings.locale.value;

      return GetMaterialApp(
        title: LocaleKeys.appName.tr(),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        getPages: AppPages.routes,
        initialRoute: AppPages.initial,
        routingCallback: (_) {},
        builder: (BuildContext context, Widget? child) {
          final MediaQueryData mq = MediaQuery.of(context);
          AppResponsive.update(mq);
          return Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _idleTimeout?.heartbeat(),
            child: MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(AppResponsive.fontScale),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
      );
    });
  }
}
