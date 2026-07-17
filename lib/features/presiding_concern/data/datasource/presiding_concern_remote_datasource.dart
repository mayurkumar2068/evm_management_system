import 'package:dio/dio.dart';
import 'package:evm_management_system/config/environment_config.dart';
import 'package:evm_management_system/core/network/api_endpoints.dart';
import 'package:evm_management_system/core/network/po_election_api_client.dart';
import 'package:evm_management_system/features/presiding_concern/data/constants/po_election_api_fields.dart';
import 'package:evm_management_system/features/presiding_concern/data/models/po_election_action_result.dart';

/// Network calls for PO Election APIs (`POElectionAPI v1` OpenAPI).
abstract interface class PresidingConcernRemoteDatasource {
  /// POSTs [body] to [endpoint] and returns the parsed server outcome.
  Future<PoElectionActionResult> postAction({
    required String endpoint,
    required Map<String, dynamic> body,
  });

  /// GET `/api/POElection/get-po-status?id={userId}`
  Future<Map<String, dynamic>?> fetchPoStatus({required String userId});
}

/// Dio-backed PO Election API client using the PO login access token.
final class PresidingConcernRemoteDatasourceImpl
    implements PresidingConcernRemoteDatasource {
  PresidingConcernRemoteDatasourceImpl({
    required EnvironmentConfig config,
    required Future<String?> Function() getAccessToken,
    Dio? dio,
  }) : _dio = dio ?? PoElectionApiClient.instance(config),
       _getAccessToken = getAccessToken;

  final Dio _dio;
  final Future<String?> Function() _getAccessToken;

  @override
  Future<PoElectionActionResult> postAction({
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      endpoint,
      data: body,
      options: Options(contentType: Headers.jsonContentType),
    );
    return _parseResponse(response);
  }

  @override
  Future<Map<String, dynamic>?> fetchPoStatus({required String userId}) async {
    final String token = (await _getAccessToken())?.trim() ?? '';
    if (token.isEmpty || userId.trim().isEmpty) return null;

    final Response<dynamic> response = await _dio.get<dynamic>(
      PoElectionEndpoints.getPoStatus(userId.trim()),
      options: Options(
        headers: <String, dynamic>{'Authorization': 'Bearer $token'},
      ),
    );
    final int? status = response.statusCode;
    if (status == null || status < 200 || status >= 300) return null;

    final dynamic data = response.data;
    if (data is Map) {
      final Map<String, dynamic> body = data.cast<String, dynamic>();
      final Object? statusFlag =
          body[PoElectionResponseFields.status] ?? body['status'];
      if (statusFlag == true) {
        final Object? payload =
            body[PoElectionResponseFields.data] ?? body['data'];
        if (payload is Map) return payload.cast<String, dynamic>();
      }
      return body;
    }
    return null;
  }

  static PoElectionActionResult _parseResponse(Response<dynamic> response) {
    final int? status = response.statusCode;
    if (status == null || status < 200 || status >= 300) {
      return const PoElectionActionResult(success: false);
    }

    final dynamic data = response.data;
    if (data is num) {
      return const PoElectionActionResult(success: true);
    }
    if (data is! Map) {
      return const PoElectionActionResult(success: true);
    }

    final Map<String, dynamic> body = data.cast<String, dynamic>();
    final int? code = _readInt(body['Code'] ?? body['code']);
    final String? message = (body['Message'] ?? body['message'])?.toString();
    final DateTime? actionDateTime = _parseDateTime(
      body['ActionDateTime'] ?? body['actionDateTime'],
    );

    if (code == -1) {
      return PoElectionActionResult(
        success: false,
        alreadyRegistered: true,
        actionDateTime: actionDateTime,
        message: message,
      );
    }

    final int? id = _readInt(body['Id'] ?? body['id']);
    if (id != null || actionDateTime != null) {
      return PoElectionActionResult(
        success: true,
        actionDateTime: actionDateTime,
        message: message,
      );
    }

    return const PoElectionActionResult(success: true);
  }

  static int? _readInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
