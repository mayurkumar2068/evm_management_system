import 'dart:async';

import 'package:dio/dio.dart';

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.getAccessToken,
    required this.refreshToken,
    required this.onAuthFailure,
    required this.retry,
  });

  final Future<String?> Function() getAccessToken;

  final Future<bool> Function() refreshToken;

  final void Function() onAuthFailure;

  final Future<Response<dynamic>> Function(RequestOptions options) retry;

  static const String _retriedFlag = 'x-auth-retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] != true) {
      final String? token = await getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final RequestOptions request = err.requestOptions;
    final bool alreadyRetried = request.extra[_retriedFlag] == true;
    final bool isAuthCall = request.extra['skipAuth'] == true;

    if (err.response?.statusCode != 401 || alreadyRetried || isAuthCall) {
      return handler.next(err);
    }

    final bool refreshed = await refreshToken();
    if (!refreshed) {
      onAuthFailure();
      return handler.next(err);
    }

    try {
      request.extra[_retriedFlag] = true;
      final Response<dynamic> response = await retry(request);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }
}
