import 'package:dio/dio.dart';
import 'package:evm_management_system/config/environment_config.dart';
import 'package:evm_management_system/core/network/dio_factory.dart';

/// Unauthenticated Dio client for OLINAPI (Online Nomination masters).
abstract final class OlinApiClient {
  static Dio? _dio;

  static Dio instance(EnvironmentConfig config) {
    return _dio ??= DioFactory.create(
      config: config,
      baseUrl: config.olinApiBaseUrl,
    );
  }

  static void reset() => _dio = null;
}
