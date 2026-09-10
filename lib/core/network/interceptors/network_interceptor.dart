import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

class NetworkInterceptor extends Interceptor {
  NetworkInterceptor({required this.localeCode, Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

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
