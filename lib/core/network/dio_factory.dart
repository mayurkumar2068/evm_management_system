import 'package:dio/dio.dart';
import 'package:evm_management_system/config/environment_config.dart';
import 'package:evm_management_system/core/network/interceptors/logging_interceptor.dart';

abstract final class DioFactory {
  static Dio create({
    required EnvironmentConfig config,
    required String baseUrl,
    List<Interceptor> interceptors = const <Interceptor>[],
    bool validateNon5xx = true,
  }) {
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        sendTimeout: config.sendTimeout,
        responseType: ResponseType.json,
        validateStatus: validateNon5xx
            ? (int? code) => code != null && code < 500
            : null,
      ),
    );

    dio.interceptors.addAll(interceptors);
    dio.interceptors.add(LoggingInterceptor(enabled: config.enableLogging));
    return dio;
  }
}
