import 'package:dio/dio.dart';
import 'package:evm_management_system/config/environment_config.dart';
import 'package:evm_management_system/core/network/po_election_api_client.dart';
import 'package:evm_management_system/core/network/po_election_auth.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/po_api_exception.dart';

abstract class PoElectionBaseDatasource {
  PoElectionBaseDatasource(this.config);
  final EnvironmentConfig config;

  Dio get dio => PoElectionApiClient.instance(config);

  Future<Map<String, dynamic>> authHeaders() async {
    final String token = (await PoElectionAuth.accessToken())?.trim() ?? '';
    if (token.isEmpty) {
      throw const PoApiException(
        'PO session token missing. Please login again.',
        statusCode: 401,
      );
    }
    return <String, dynamic>{
      'token': token,
      'headers': <String, dynamic>{
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    };
  }

  Future<Response<dynamic>> authedPost(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final auth = await authHeaders();
    return dio.post<dynamic>(
      endpoint,
      data: body,
      queryParameters: <String, dynamic>{'token': auth['token']},
      options: Options(
        contentType: Headers.jsonContentType,
        headers: auth['headers'] as Map<String, dynamic>,
      ),
    );
  }

  void throwIfUnauthorized(int? code) {
    if (code == 401 || code == 403) {
      throw PoApiException(
        'Session expired. Please login again.',
        statusCode: code,
      );
    }
  }

  String dioMessage(DioException e, {required String fallback}) {
    final Object? body = e.response?.data;
    if (body is Map) {
      final Object? msg = body['Message'] ?? body['message'] ?? body['title'];
      if (msg != null && msg.toString().trim().isNotEmpty) {
        return msg.toString();
      }
      final Object? errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final Object? first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        return first.toString();
      }
    }
    return fallback;
  }

  bool isTransientDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      default:
        break;
    }
    final int? code = e.response?.statusCode;
    if (code == 408 || code == 429 || (code != null && code >= 500))
      return true;
    final String msg = (e.message ?? '').toLowerCase();
    return msg.contains('offline') ||
        msg.contains('socket') ||
        msg.contains('network');
  }
}
