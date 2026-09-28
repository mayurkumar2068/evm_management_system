import 'package:dio/dio.dart';
import 'package:evm_management_system/core/app_build_info.dart';
import 'package:evm_management_system/core/network/curl_formatter.dart';

final class ClientMetadataInterceptor extends Interceptor {
  const ClientMetadataInterceptor({
    this.clientVersion = AppBuildInfo.versionName,
    this.deviceType,
  });

  final String clientVersion;
  final String? deviceType;

  static const String clientVersionHeader = 'Client-Version';
  static const String deviceTypeHeader = 'DeviceType';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.putIfAbsent(clientVersionHeader, () => clientVersion);
    options.headers.putIfAbsent(
      deviceTypeHeader,
      () => deviceType ?? CurlFormatter.currentDeviceType,
    );
    handler.next(options);
  }
}
