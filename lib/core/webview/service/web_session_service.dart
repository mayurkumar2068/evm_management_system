import 'dart:io' show Platform;

import 'package:evm_management_system/config/app_config.dart';
import 'package:evm_management_system/core/app_build_info.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/storage/secure_storage_service.dart';
import 'package:evm_management_system/core/time/app_time_zone.dart';
import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:uuid/uuid.dart';

import '../models/web_session_context.dart';
import 'device_id_service.dart';

class WebSessionService {
  WebSessionService({DeviceIdService? deviceId})
    : _deviceId = deviceId ?? DeviceIdService(SecureStorageService());

  final DeviceIdService _deviceId;

  Future<WebSessionContext> build({
    WebThemeMode theme = WebThemeMode.system,
  }) async {
    final ServiceSession? session = AppServices.serviceAuth.session.value;
    final String deviceId = await _deviceId.getOrCreate();

    return WebSessionContext(
      accessToken: session?.token,
      language: 'hi',
      theme: theme,
      deviceId: deviceId,
      officerId: session?.userId,
      districtId: session?.districtId,
      distName: session?.districtName,
      bodyId: session?.bodyId,
      bodyName: session?.bodyName,
      urbanRural: session?.section,
      boothLat: session?.lat,
      boothLong: session?.long,
      apiBaseUrl: AppServices.config.poElectionApiBaseUrl,
      appVersion: AppBuildInfo.versionName,
      buildNumber: AppBuildInfo.buildNumber,
      platform: Platform.isIOS ? 'ios' : 'android',
      environment: AppConfig.environment.name,
      timezone: AppTimeZone.headerValue,
      correlationId: const Uuid().v4(),
    );
  }
}
