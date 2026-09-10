import 'package:dio/dio.dart';
import 'package:evm_management_system/config/environment_config.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:evm_management_system/core/network/api_endpoints.dart';
import 'package:evm_management_system/core/network/po_election_api_client.dart';
import 'package:evm_management_system/features/presiding_concern/data/constants/po_election_api_fields.dart';
import 'package:evm_management_system/features/presiding_concern/data/models/po_election_action_result.dart';

abstract interface class PresidingConcernRemoteDatasource {
  Future<PoElectionActionResult> postAction({
    required String endpoint,
    required Map<String, dynamic> body,
  });

  Future<Map<String, dynamic>?> fetchPoStatus({
    required int electionId,
    required String psId,
  });
}

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
  Future<Map<String, dynamic>?> fetchPoStatus({
    required int electionId,
    required String psId,
  }) async {
    final String token = (await _getAccessToken())?.trim() ?? '';
    final String resolvedPsId = psId.trim();
    if (token.isEmpty || electionId <= 0 || resolvedPsId.isEmpty) {
      AppLogger.w(
        '[PO API] po-status skipped — '
        'token=${token.isEmpty ? "MISSING" : "ok"} '
        'electionId=$electionId '
        'psId=${resolvedPsId.isEmpty ? "MISSING" : resolvedPsId}',
      );
      return null;
    }

    final Response<dynamic> response = await _dio.post<dynamic>(
      PoElectionEndpoints.poStatus,
      data: <String, dynamic>{
        PoElectionRequestFields.electionId: electionId,
        PoElectionRequestFields.psId: resolvedPsId,
      },
      options: Options(
        contentType: Headers.jsonContentType,
        headers: <String, dynamic>{
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
    final int? status = response.statusCode;
    if (status == null || status < 200 || status >= 300) {
      AppLogger.w(
        '[PO API] po-status non-2xx http=$status '
        '(endpoint may be missing on this host) body=${response.data}',
      );
      return null;
    }

    final dynamic data = response.data;
    if (data is Map) {
      final Map<String, dynamic> body = data.cast<String, dynamic>();
      final Object? statusFlag =
          body[PoElectionResponseFields.status] ?? body['status'];
      if (statusFlag == true) {
        final Object? payload =
            body[PoElectionResponseFields.data] ?? body['data'];
        if (payload is Map) return payload.cast<String, dynamic>();
        AppLogger.w(
          '[PO API] po-status Status=true but Data is not a Map '
          '(type=${payload.runtimeType})',
        );
      } else {
        AppLogger.w(
          '[PO API] po-status Status=$statusFlag '
          'Message=${body['Message']}',
        );
      }
      return body;
    }
    AppLogger.w('[PO API] po-status unexpected body type=${data.runtimeType}');
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
