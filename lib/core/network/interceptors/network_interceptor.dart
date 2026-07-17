import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// Attaches standard headers (content negotiation, correlation id, locale)
/// to every outgoing request for consistent server-side tracing.
class NetworkInterceptor extends Interceptor {
  NetworkInterceptor({required this.localeCode, Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  /// Active locale code (e.g. `en`, `hi`) sent as `Accept-Language`.
  final String Function() localeCode;
  final Uuid _uuid;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.putIfAbsent('Accept', () => 'application/json');
    options.headers.putIfAbsent('Content-Type', () => 'application/json');
    options.headers['Accept-Language'] = localeCode();
    options.headers['X-Request-Id'] = _uuid.v4();
    handler.next(options);
  }
}
