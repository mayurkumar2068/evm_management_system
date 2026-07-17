import 'package:dio/dio.dart';
import 'package:evm_management_system/config/environment_config.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:evm_management_system/core/network/api_endpoints.dart';
import 'package:evm_management_system/core/security/token_vault.dart';

/// Refreshes the access token using a dedicated, interceptor-free [Dio] so the
/// refresh call can never recurse through the [AuthInterceptor].
///
/// Lives in `core` (not the auth feature) so the network layer stays
/// self-contained and feature-agnostic.
class TokenRefresher {
  TokenRefresher({
    required EnvironmentConfig config,
    required TokenVault tokenVault,
    Dio? dio,
  }) : _tokenVault = tokenVault,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: config.apiBaseUrl,
               connectTimeout: config.connectTimeout,
               receiveTimeout: config.receiveTimeout,
             ),
           );

  final TokenVault _tokenVault;
  final Dio _dio;

  Future<bool> refresh() async {
    try {
      final AuthTokens? current = await _tokenVault.read();
      if (current == null) return false;

      final Response<Map<String, dynamic>> response = await _dio
          .post<Map<String, dynamic>>(
            ApiEndpoints.refresh,
            data: <String, dynamic>{'refreshToken': current.refreshToken},
          );
      final Map<String, dynamic> body = response.data ?? <String, dynamic>{};
      final Map<String, dynamic> data =
          (body['data'] as Map<String, dynamic>?) ?? body;

      final String? access =
          data['accessToken'] as String? ?? data['access_token'] as String?;
      if (access == null) return false;

      await _tokenVault.save(
        AuthTokens(
          accessToken: access,
          refreshToken:
              data['refreshToken'] as String? ??
              data['refresh_token'] as String? ??
              current.refreshToken,
          expiresAt: DateTime.now().add(
            Duration(
              seconds:
                  data['expiresIn'] as int? ??
                  data['expires_in'] as int? ??
                  3600,
            ),
          ),
        ),
      );
      return true;
    } catch (e, s) {
      AppLogger.w('Token refresh failed', error: e, stackTrace: s);
      return false;
    }
  }
}
