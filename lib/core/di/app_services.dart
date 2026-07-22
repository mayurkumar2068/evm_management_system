import 'package:dio/dio.dart';
import 'package:evm_management_system/config/environment_config.dart';
import 'package:evm_management_system/core/database/local_database.dart';
import 'package:evm_management_system/core/di/onboarding_store.dart';
import 'package:evm_management_system/core/network/api_client.dart';
import 'package:evm_management_system/core/network/connectivity_service.dart';
import 'package:evm_management_system/core/network/interceptors/auth_interceptor.dart';
import 'package:evm_management_system/core/network/po_election_auth.dart';
import 'package:evm_management_system/core/network/interceptors/connectivity_interceptor.dart';
import 'package:evm_management_system/core/network/interceptors/logging_interceptor.dart';
import 'package:evm_management_system/core/network/interceptors/network_interceptor.dart';
import 'package:evm_management_system/core/network/interceptors/retry_interceptor.dart';
import 'package:evm_management_system/core/network/token_refresher.dart';
import 'package:evm_management_system/core/notifications/notification_service.dart';
import 'package:evm_management_system/core/offline/offline_sync_service.dart';
import 'package:evm_management_system/core/offline/survey_api_upload_service.dart';
import 'package:evm_management_system/core/offline/web_submission_repository.dart';
import 'package:evm_management_system/core/providers/session_event_bus.dart';
import 'package:evm_management_system/core/security/biometric_authenticator.dart';
import 'package:evm_management_system/core/security/screen_security_service.dart';
import 'package:evm_management_system/core/security/ssl_pinning_service.dart';
import 'package:evm_management_system/core/security/token_vault.dart';
import 'package:evm_management_system/core/settings/settings_service.dart';
import 'package:evm_management_system/core/storage/secure_storage_service.dart';
import 'package:evm_management_system/core/sync/conflict_resolver.dart';
import 'package:evm_management_system/core/sync/retry_policy.dart';
import 'package:evm_management_system/core/sync/sync_manager.dart';
import 'package:evm_management_system/core/sync/sync_queue.dart';
import 'package:evm_management_system/core/sync/sync_service.dart';
import 'package:evm_management_system/core/utils/app_locale_holder.dart';
import 'package:evm_management_system/core/webview/service/device_id_service.dart';
import 'package:evm_management_system/core/webview/service/web_session_service.dart';
import 'package:evm_management_system/core/webview/service/webview_cookie_service.dart';
import 'package:evm_management_system/core/webview/service/webview_logger.dart';
import 'package:evm_management_system/core/webview/service/webview_warmer.dart';
import 'package:evm_management_system/features/online_nomination/data/repositories/nomination_draft_repository.dart';
import 'package:evm_management_system/features/online_nomination/data/repositories/urban_nomination_master_repository.dart';
import 'package:evm_management_system/features/online_nomination/data/datasources/urban_nomination_remote_datasource.dart';
import 'package:evm_management_system/core/network/olin_api_client.dart';
import 'package:evm_management_system/features/auth/presentation/controllers/auth_controller.dart';
import 'package:evm_management_system/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:evm_management_system/features/presiding_concern/di/presiding_concern_module.dart';
import 'package:evm_management_system/features/service_auth/presentation/controllers/service_auth_controller.dart';
import 'package:evm_management_system/shared/controllers/activity_log_controller.dart';
import 'package:evm_management_system/shared/controllers/device_records_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Composition root for application-lifetime dependencies (GetX only).
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

    Get.put<BiometricAuthenticator>(BiometricAuthenticator(), permanent: true);
    Get.put<ScreenSecurityService>(
      const DefaultScreenSecurityService(),
      permanent: true,
    );
    Get.put<NotificationService>(NoopNotificationService(), permanent: true);

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
    Get.put<WebViewLogger>(WebViewLogger(), permanent: true);
    Get.put<WebViewCookieService>(WebViewCookieService(), permanent: true);
    Get.put<DeviceIdService>(DeviceIdService(secureStorage), permanent: true);
    Get.put<WebSessionService>(WebSessionService(), permanent: true);

    Get.put<NominationDraftRepository>(
      NominationDraftRepository(database),
      permanent: true,
    );
    Get.put<UrbanNominationMasterRepository>(
      UrbanNominationMasterRepository(
        UrbanNominationRemoteDatasource(OlinApiClient.instance(config)),
      ),
      permanent: true,
    );

    Get.put<DeviceRecordsController>(
      DeviceRecordsController(database),
      permanent: true,
    );
    Get.put<ActivityLogController>(ActivityLogController(), permanent: true);
    Get.put<ServiceAuthController>(ServiceAuthController(), permanent: true);
    // Auth before dashboard — DashboardController.onInit listens to authState.
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<DashboardController>(DashboardController(), permanent: true);
    Get.put<PresidingDashboardController>(
      PresidingDashboardController(),
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
  static TokenVault get tokenVault => Get.find<TokenVault>();
  static ConnectivityService get connectivity =>
      Get.find<ConnectivityService>();
  static SyncManager get syncManager => Get.find<SyncManager>();
  static SyncQueue get syncQueue => Get.find<SyncQueue>();
  static SessionEventBus get sessionBus => Get.find<SessionEventBus>();
  static OfflineSyncService get offlineSync => Get.find<OfflineSyncService>();
  static WebSubmissionRepository get webSubmissionRepository =>
      Get.find<WebSubmissionRepository>();
  static AuthController get auth => Get.find<AuthController>();
  static SettingsController get settings => Get.find<SettingsController>();
  static DeviceRecordsController get deviceRecords =>
      Get.find<DeviceRecordsController>();
  static ActivityLogController get activityLog =>
      Get.find<ActivityLogController>();
  static NominationDraftRepository get nominationDrafts =>
      Get.find<NominationDraftRepository>();
  static UrbanNominationMasterRepository get urbanNominationMasters =>
      Get.find<UrbanNominationMasterRepository>();
}

/// Reactive locale and theme preferences.
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
