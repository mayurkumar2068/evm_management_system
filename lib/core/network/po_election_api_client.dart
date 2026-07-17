import 'package:dio/dio.dart';
import 'package:evm_management_system/config/environment_config.dart';
import 'package:evm_management_system/core/network/dio_factory.dart';
import 'package:evm_management_system/core/network/interceptors/bearer_auth_interceptor.dart';
import 'package:evm_management_system/core/network/po_election_auth.dart';

/// Shared authenticated Dio client for all PO Election API traffic.
abstract final class PoElectionApiClient {
  static Dio? _dio;

  static Dio instance(EnvironmentConfig config) {
    return _dio ??= DioFactory.create(
      config: config,
      baseUrl: config.poElectionApiBaseUrl,
      interceptors: <Interceptor>[
        BearerAuthInterceptor(getAccessToken: PoElectionAuth.accessToken),
      ],
    );
  }

  static void reset() => _dio = null;
}
