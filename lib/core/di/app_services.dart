import 'package:dio/dio.dart';
import 'package:MPSECNET/config/environment_config.dart';
import 'package:MPSECNET/core/feature_flags/app_feature_flags_controller.dart';
import 'package:MPSECNET/core/database/local_database.dart';
import 'package:MPSECNET/core/di/onboarding_store.dart';
import 'package:MPSECNET/core/network/api_client.dart';
import 'package:MPSECNET/core/network/connectivity_service.dart';
import 'package:MPSECNET/core/network/interceptors/auth_interceptor.dart';
import 'package:MPSECNET/core/network/po_election_auth.dart';
import 'package:MPSECNET/core/network/interceptors/connectivity_interceptor.dart';
import 'package:MPSECNET/core/network/interceptors/logging_interceptor.dart';
import 'package:MPSECNET/core/network/interceptors/network_interceptor.dart';
import 'package:MPSECNET/core/network/interceptors/retry_interceptor.dart';
import 'package:MPSECNET/core/network/network_quality_service.dart';
import 'package:MPSECNET/core/network/token_refresher.dart';
import 'package:MPSECNET/core/notifications/notification_service.dart';
import 'package:MPSECNET/core/offline/offline_sync_service.dart';
import 'package:MPSECNET/core/offline/survey_api_upload_service.dart';
import 'package:MPSECNET/core/offline/web_submission_repository.dart';
import 'package:MPSECNET/core/providers/session_event_bus.dart';
import 'package:MPSECNET/core/security/biometric_authenticator.dart';
import 'package:MPSECNET/core/security/screen_security_service.dart';
import 'package:MPSECNET/core/security/ssl_pinning_service.dart';
import 'package:MPSECNET/core/security/token_vault.dart';
import 'package:MPSECNET/core/settings/settings_service.dart';
import 'package:MPSECNET/core/storage/secure_storage_service.dart';
import 'package:MPSECNET/core/sync/conflict_resolver.dart';
import 'package:MPSECNET/core/sync/retry_policy.dart';
import 'package:MPSECNET/core/sync/sync_manager.dart';
import 'package:MPSECNET/core/sync/sync_queue.dart';
import 'package:MPSECNET/core/sync/sync_service.dart';
import 'package:MPSECNET/core/utils/app_locale_holder.dart';
import 'package:MPSECNET/core/webview/service/device_id_service.dart';
import 'package:MPSECNET/core/webview/service/web_session_service.dart';
import 'package:MPSECNET/core/webview/service/webview_cookie_service.dart';
import 'package:MPSECNET/core/webview/service/webview_logger.dart';
import 'package:MPSECNET/core/webview/service/webview_warmer.dart';
import 'package:MPSECNET/features/auth/presentation/controllers/auth_controller.dart';
import 'package:MPSECNET/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:MPSECNET/features/presiding_concern/di/presiding_concern_module.dart';
import 'package:MPSECNET/features/presiding_concern/presentation/controllers/presiding_party_controller.dart';
import 'package:MPSECNET/features/service_auth/presentation/controllers/service_auth_controller.dart';
import 'package:MPSECNET/shared/controllers/activity_log_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

abstract final class AppServices {
  static Future<void> register({
    required EnvironmentConfig config,
    required LocalDatabase database,
    required SecureStorageService secureStorage,
    required bool onboardingSeen,
    required AppSettingsService settingsService,
    required Locale initialLocale,
    required ThemeMode initialThemeMode,
  }) async {
    Get.put<EnvironmentConfig>(config, permanent: true);
    Get.put<LocalDatabase>(database, permanent: true);
    Get.put<SecureStorageService>(secureStorage, permanent: true);
    final OnboardingStore onboarding = OnboardingStore()..seen = onboardingSeen;
    Get.put<OnboardingStore>(onboarding, permanent: true);
    Get.put<AppSettingsService>(settingsService, permanent: true);
    Get.put<SettingsController>(
      SettingsController(settingsService, initialLocale, initialThemeMode),
      permanent: true,
    );

    final TokenVault tokenVault = TokenVault(secureStorage);
    Get.put<TokenVault>(tokenVault, permanent: true);

    final ConnectivityService connectivity = ConnectivityService();
    Get.put<ConnectivityService>(connectivity, permanent: true);

    Get.put<NetworkQualityService>(
      NetworkQualityService(connectivity),
      permanent: true,
    );

    Get.put<BiometricAuthenticator>(BiometricAuthenticator(), permanent: true);
    Get.put<ScreenSecurityService>(
      const DefaultScreenSecurityService(),
      permanent: true,
    );
    Get.put<LocalNotificationService>(
      LocalNotificationService.instance,
      permanent: true,
    );

    final SessionEventBus sessionBus = SessionEventBus();
    Get.put<SessionEventBus>(sessionBus, permanent: true);

    final TokenRefresher refresher = TokenRefresher(
      config: config,
      tokenVault: tokenVault,
    );
    Get.put<TokenRefresher>(refresher, permanent: true);

    final Dio dio = Dio();
    dio.httpClientAdapter = SslPinningService(config).buildAdapter();
    final ApiClient apiClient = ApiClient(dio: dio, config: config);
    dio.interceptors.addAll(<Interceptor>[
      ConnectivityInterceptor(connectivity),
      NetworkInterceptor(localeCode: () => AppLocaleHolder.code),
      AuthInterceptor(
        getAccessToken: PoElectionAuth.accessToken,
        refreshToken: refresher.refresh,
        onAuthFailure: () => sessionBus.emit(SessionEvent.expired),
        retry: (RequestOptions options) => dio.fetch<dynamic>(options),
      ),
      RetryInterceptor(dio: dio),
      LoggingInterceptor(enabled: config.enableLogging),
    ]);
    Get.put<ApiClient>(apiClient, permanent: true);

    Get.put<AppFeatureFlagsController>(
      AppFeatureFlagsController(config: config, dio: dio),
      permanent: true,
    );

    final SyncQueue syncQueue = SyncQueue(database);
    Get.put<SyncQueue>(syncQueue, permanent: true);
    Get.put<SyncService>(SyncService(apiClient), permanent: true);

    final SyncManager syncManager = SyncManager(
      queue: syncQueue,
      service: Get.find<SyncService>(),
      connectivity: connectivity,
      db: database,
      retryPolicy: RetryPolicy(maxAttempts: config.syncMaxRetry),
      interval: config.syncInterval,
      conflictResolver: const ConflictResolver(),
    );
    Get.put<SyncManager>(syncManager, permanent: true);

    final WebSubmissionRepository webSubmissionRepository =
        WebSubmissionRepository(database);
    Get.put<WebSubmissionRepository>(webSubmissionRepository, permanent: true);
    Get.put<SurveyApiUploadService>(
      SurveyApiUploadService(baseUrl: config.surveyApiBaseUrl),
      permanent: true,
    );
    final OfflineSyncService offlineSync = OfflineSyncService(
      repository: webSubmissionRepository,
      uploadService: Get.find<SurveyApiUploadService>(),
      connectivity: connectivity,
      retryPolicy: RetryPolicy(maxAttempts: config.syncMaxRetry),
      syncInterval: config.syncInterval,
    );
    Get.put<OfflineSyncService>(offlineSync, permanent: true);

    Get.put<WebViewWarmer>(WebViewWarmer(), permanent: true);
    Get.put<WebViewLogger>(const WebViewLogger(), permanent: true);
    Get.put<WebViewCookieService>(WebViewCookieService(), permanent: true);
    Get.put<DeviceIdService>(DeviceIdService(secureStorage), permanent: true);
    Get.put<WebSessionService>(WebSessionService(), permanent: true);

    Get.put<ActivityLogController>(ActivityLogController(), permanent: true);
    Get.put<ServiceAuthController>(ServiceAuthController(), permanent: true);

    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<DashboardController>(DashboardController(), permanent: true);
    Get.put<PresidingDashboardController>(
      PresidingDashboardController(),
      permanent: true,
    );
    Get.put<PresidingPartyController>(
      PresidingPartyController(),
      permanent: true,
    );
    Get.put<PresidingTurnoutController>(
      PresidingTurnoutController(),
      permanent: true,
    );
  }

  static ServiceAuthController get serviceAuth =>
      Get.find<ServiceAuthController>();

  static EnvironmentConfig get config => Get.find<EnvironmentConfig>();
  static LocalDatabase get database => Get.find<LocalDatabase>();
  static SecureStorageService get secureStorage =>
      Get.find<SecureStorageService>();
  static OnboardingStore get onboarding => Get.find<OnboardingStore>();
  static ApiClient get apiClient => Get.find<ApiClient>();
  static AppFeatureFlagsController get featureFlags =>
      Get.find<AppFeatureFlagsController>();
  static TokenVault get tokenVault => Get.find<TokenVault>();
  static ConnectivityService get connectivity =>
      Get.find<ConnectivityService>();
  static NetworkQualityService get networkQuality =>
      Get.find<NetworkQualityService>();
  static SyncManager get syncManager => Get.find<SyncManager>();
  static SyncQueue get syncQueue => Get.find<SyncQueue>();
  static SessionEventBus get sessionBus => Get.find<SessionEventBus>();
  static OfflineSyncService get offlineSync => Get.find<OfflineSyncService>();
  static WebSubmissionRepository get webSubmissionRepository =>
      Get.find<WebSubmissionRepository>();
  static AuthController get auth => Get.find<AuthController>();
  static DashboardController get dashboard => Get.find<DashboardController>();
  static SettingsController get settings => Get.find<SettingsController>();
  static ActivityLogController get activityLog =>
      Get.find<ActivityLogController>();
}

class SettingsController extends GetxController {
  SettingsController(
    this._settings,
    Locale initialLocale,
    ThemeMode initialTheme,
  ) : locale = initialLocale.obs,
      themeMode = initialTheme.obs;

  final AppSettingsService _settings;
  final Rx<Locale> locale;
  final Rx<ThemeMode> themeMode;
  Future<void> setLocale(Locale value) async {
    if (locale.value == value) return;
    locale.value = value;
    await _settings.saveLocale(value);
  }

  Future<void> setThemeMode(ThemeMode value) async {
    if (themeMode.value == value) return;
    themeMode.value = value;
    await _settings.saveThemeMode(value);
  }
}
