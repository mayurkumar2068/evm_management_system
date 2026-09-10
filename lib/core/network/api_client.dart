import 'package:dio/dio.dart';
import 'package:evm_management_system/config/environment_config.dart';

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

Options get unauthenticatedOptions =>
    Options(extra: <String, dynamic>{'skipAuth': true});
