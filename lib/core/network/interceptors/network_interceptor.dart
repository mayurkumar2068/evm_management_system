import 'package:dio/dio.dart';
import 'package:MPSECNET/core/app_build_info.dart';
import 'package:MPSECNET/core/network/curl_formatter.dart';
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
    options.headers.putIfAbsent('Client-Version', () => AppBuildInfo.versionName);
    options.headers.putIfAbsent('DeviceType', () => CurlFormatter.currentDeviceType);
    handler.next(options);
  }
}
