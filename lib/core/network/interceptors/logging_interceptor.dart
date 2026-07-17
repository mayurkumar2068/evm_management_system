import 'package:dio/dio.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:evm_management_system/core/network/api_log_formatter.dart';

/// Logs the full HTTP lifecycle: request → status code → response body.
///
/// Each call is tagged with a short [logId] so request/response pairs are easy
/// to match in the console. Sensitive headers and body fields are redacted.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({required this.enabled});

  final bool enabled;
  int _sequence = 0;

  static const String _logIdKey = 'apiLogId';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enabled) {
      final int logId = ++_sequence;
      options.extra[_logIdKey] = logId;
      AppLogger.i(
        '[$logId] ── REQUEST ──\n${ApiLogFormatter.formatRequest(options)}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (enabled) {
      final Object? logId = response.requestOptions.extra[_logIdKey];
      AppLogger.i(
        '[$logId] ── RESPONSE ${response.statusCode} ──\n'
        '${ApiLogFormatter.formatResponse(response)}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enabled) {
      final Object? logId = err.requestOptions.extra[_logIdKey];
      AppLogger.w(
        '[$logId] ── ERROR ${err.response?.statusCode ?? '—'} ──\n'
        '${ApiLogFormatter.formatError(err)}',
      );
    }
    handler.next(err);
  }
}
