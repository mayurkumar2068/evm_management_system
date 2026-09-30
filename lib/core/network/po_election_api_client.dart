import 'package:dio/dio.dart';
import 'package:MPSECNET/config/environment_config.dart';
import 'package:MPSECNET/core/network/dio_factory.dart';
import 'package:MPSECNET/core/network/interceptors/bearer_auth_interceptor.dart';
import 'package:MPSECNET/core/network/interceptors/po_api_logging_interceptor.dart';
import 'package:MPSECNET/core/network/po_election_auth.dart';

abstract final class PoElectionApiClient {
  static Dio? _dio;

  static Dio instance(EnvironmentConfig config) {
    return _dio ??= DioFactory.create(
      config: config,
      baseUrl: config.poElectionApiBaseUrl,
      interceptors: <Interceptor>[
        BearerAuthInterceptor(getAccessToken: PoElectionAuth.accessToken),

        PoApiLoggingInterceptor(),
      ],
    );
  }

  static void reset() => _dio = null;
}
