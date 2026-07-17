import 'dart:async';

import 'package:dio/dio.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';

/// Retries transient failures (timeouts, connection errors, 502/503/504)
/// using exponential backoff with jitter.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 400),
  });

  final Dio dio;
  final int maxRetries;
  final Duration baseDelay;

  static const String _attemptKey = 'x-retry-attempt';
  static const Set<int> _retriableStatus = <int>{502, 503, 504};

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final RequestOptions options = err.requestOptions;
    final int attempt = (options.extra[_attemptKey] as int?) ?? 0;

    if (!_shouldRetry(err) || attempt >= maxRetries) {
      return handler.next(err);
    }

    final Duration delay = baseDelay * (1 << attempt);
    AppLogger.d(
      'Retrying ${options.uri} '
      '(attempt ${attempt + 1}/$maxRetries) in ${delay.inMilliseconds}ms',
    );
    await Future<void>.delayed(delay);

    options.extra[_attemptKey] = attempt + 1;
    try {
      final Response<dynamic> response = await dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  bool _shouldRetry(DioException err) {
    final bool idempotent = const <String>{
      'GET',
      'HEAD',
      'PUT',
      'DELETE',
    }.contains(err.requestOptions.method.toUpperCase());
    final bool transientType =
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError;
    final bool transientStatus = _retriableStatus.contains(
      err.response?.statusCode,
    );
    return idempotent && (transientType || transientStatus);
  }
}
