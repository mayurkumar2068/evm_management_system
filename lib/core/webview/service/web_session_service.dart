import 'dart:io' show Platform;

import 'package:evm_management_system/config/app_config.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/storage/secure_storage_service.dart';
import 'package:evm_management_system/core/utils/app_locale_holder.dart';
import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:uuid/uuid.dart';

import '../models/web_session_context.dart';
import 'device_id_service.dart';

/// App version/build mirrored from pubspec (`1.0.0+1`). Kept as constants to
/// avoid an extra `package_info_plus` dependency.
const String kWebAppVersion = '1.0.0';
const String kWebBuildNumber = '1';

/// Builds the [WebSessionContext] that pre-authenticates every WebView.
class WebSessionService {
  WebSessionService({DeviceIdService? deviceId})
    : _deviceId = deviceId ?? DeviceIdService(SecureStorageService());

  final DeviceIdService _deviceId;

  Future<WebSessionContext> build({
    WebThemeMode theme = WebThemeMode.system,
  }) async {
    final ServiceSession? session = AppServices.serviceAuth.session.value;
    final String deviceId = await _deviceId.getOrCreate();
    final DateTime now = DateTime.now();

    return WebSessionContext(
      accessToken: session?.token,
      language: _normalizeLang(AppLocaleHolder.code),
      theme: theme,
      deviceId: deviceId,
      officerId: session?.userId,
      districtId: session?.districtId,
      appVersion: kWebAppVersion,
      buildNumber: kWebBuildNumber,
      platform: Platform.isIOS ? 'ios' : 'android',
      environment: AppConfig.environment.name,
      timezone: now.timeZoneName,
      correlationId: const Uuid().v4(),
    );
  }

  static String _normalizeLang(String code) =>
      code.toLowerCase().startsWith('en') ? 'en' : 'hi';
}
