import 'package:dio/dio.dart';
import 'package:evm_management_system/core/network/connectivity_service.dart';

class ConnectivityInterceptor extends Interceptor {
  ConnectivityInterceptor(this._connectivity);

  final ConnectivityService _connectivity;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final bool online = await _connectivity.isOnline;
    if (!online) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'offline',
          message: 'No internet connection',
        ),
      );
    }
    handler.next(options);
  }
}
