import 'package:dio/dio.dart';

/// Attaches `Authorization: Bearer <token>` when a token is available.
class BearerAuthInterceptor extends Interceptor {
  BearerAuthInterceptor({required Future<String?> Function() getAccessToken})
    : _getAccessToken = getAccessToken;

  final Future<String?> Function() _getAccessToken;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] == true) {
      return handler.next(options);
    }

    final String? token = await _getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
