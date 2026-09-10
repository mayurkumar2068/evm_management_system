import 'dart:async';

import 'package:dio/dio.dart';
import 'package:evm_management_system/config/environment_config.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:evm_management_system/core/utils/json_map.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;

class AppFeatureFlagsController extends GetxController {
  AppFeatureFlagsController({
    required EnvironmentConfig config,
    required Dio dio,
  }) : _config = config,
       _dio = dio,
       showRegistration = config.showRegistrationDefault.obs;

  final EnvironmentConfig _config;
  final Dio _dio;

  final RxBool showRegistration;
  final Rxn<DateTime> lastFetchedAt = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    unawaited(refreshFromApi());
  }

  Future<void> refreshFromApi() async {
    final String path = _config.featureFlagsPath.trim();
    if (path.isEmpty) return;

    try {
      final String base = _config.poElectionApiBaseUrl.replaceAll(
        RegExp(r'/$'),
        '',
      );
      final String url = path.startsWith('http')
          ? path
          : '$base${path.startsWith('/') ? path : '/$path'}';

      final Response<dynamic> response = await _dio.get<dynamic>(
        url,
        options: Options(
          extra: <String, Object?>{'skipAuth': true},
          receiveTimeout: _config.receiveTimeout,
          sendTimeout: _config.sendTimeout,
          validateStatus: (int? status) =>
              status != null && (status < 300 || status == 404 || status == 501),
        ),
      );

      final int? code = response.statusCode;
      if (code == 404 || code == 501) {
        AppLogger.d(
          'App feature flags endpoint not available ($code); '
          'keeping showRegistration=${showRegistration.value}',
        );
        return;
      }

      final Map<String, dynamic>? map = asStringKeyedMap(response.data);
      if (map == null) return;

      final Object? nested = map['Data'] ?? map['data'] ?? map['Result'];
      final Map<String, dynamic> flags = asStringKeyedMap(nested) ?? map;

      final bool? remote = _parseBool(
        flags['showRegistration'] ??
            flags['ShowRegistration'] ??
            flags['SHOW_REGISTRATION'],
      );
      if (remote != null) {
        showRegistration.value = remote;
      }
      lastFetchedAt.value = DateTime.now();
    } on DioException catch (e) {
      AppLogger.d(
        'App feature flags refresh skipped (${e.response?.statusCode ?? e.type}); '
        'keeping showRegistration=${showRegistration.value}',
      );
    } catch (e, s) {
      AppLogger.w(
        'App feature flags refresh failed; keeping showRegistration='
        '${showRegistration.value}',
        error: e,
        stackTrace: s,
      );
    }
  }

  static bool? _parseBool(Object? raw) {
    if (raw == null) return null;
    if (raw is bool) return raw;
    final String s = raw.toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return null;
  }
}
