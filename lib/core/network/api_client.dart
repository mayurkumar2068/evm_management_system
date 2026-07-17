import 'package:dio/dio.dart';
import 'package:evm_management_system/config/environment_config.dart';

/// Thin, typed wrapper over a fully-configured [Dio] instance.
///
/// UI and repositories use this client; they never instantiate Dio directly.
/// Interceptors (auth, retry, logging, connectivity, pinning) are attached by
/// the composition root before the client is exposed.
class ApiClient {
  ApiClient({required this.dio, required EnvironmentConfig config}) {
    dio.options
      ..baseUrl = config.apiBaseUrl
      ..connectTimeout = config.connectTimeout
      ..receiveTimeout = config.receiveTimeout
      ..sendTimeout = config.sendTimeout
      ..responseType = ResponseType.json;
  }

  final Dio dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => dio.get<T>(
    path,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
  );

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => dio.post<T>(
    path,
    data: data,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
  );

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => dio.put<T>(
    path,
    data: data,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
  );

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => dio.delete<T>(
    path,
    data: data,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
  );
}

/// Marks a request so the [AuthInterceptor] skips attaching a bearer token
/// (used by login / refresh calls).
Options get unauthenticatedOptions =>
    Options(extra: <String, dynamic>{'skipAuth': true});
