import 'dart:async';

import 'package:dio/dio.dart';

/// Injects the bearer token and transparently refreshes it on 401.
///
/// Decoupled from the Auth feature via callbacks supplied at the composition
/// root, so `core` never depends on a feature module.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.getAccessToken,
    required this.refreshToken,
    required this.onAuthFailure,
    required this.retry,
  });

  /// Returns the current access token, or `null` if unauthenticated.
  final Future<String?> Function() getAccessToken;

  /// Attempts a token refresh; returns `true` on success.
  final Future<bool> Function() refreshToken;

  /// Invoked when authentication cannot be recovered (force logout).
  final void Function() onAuthFailure;

  /// Replays the original request after a successful refresh.
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
