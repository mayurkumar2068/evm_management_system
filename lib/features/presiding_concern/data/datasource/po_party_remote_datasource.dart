import 'package:dio/dio.dart';
import 'package:evm_management_system/config/environment_config.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:evm_management_system/core/network/api_endpoints.dart';
import 'package:evm_management_system/core/network/po_election_api_client.dart';
import 'package:evm_management_system/core/network/po_election_auth.dart';
import 'package:evm_management_system/core/security/jwt_utils.dart';
import 'package:evm_management_system/features/presiding_concern/data/models/po_party_details.dart';

/// Remote calls for PO party details and PO logout.
class PoPartyRemoteDatasource {
  PoPartyRemoteDatasource(this._config);

  final EnvironmentConfig _config;

  Dio get _dio => PoElectionApiClient.instance(_config);

  /// Fetches existing party details. Returns `null` when not filled yet.
  Future<PoPartyDetails?> fetchPartyDetails(String poUserId) async {
    final String id = poUserId.trim();
    if (id.isEmpty) return null;

    final String token = (await PoElectionAuth.accessToken())?.trim() ?? '';
    if (token.isEmpty) {
      AppLogger.w('[PO Party] fetch skipped — token MISSING');
      return null;
    }

    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        PoElectionEndpoints.poPartyDetails,
        data: <String, dynamic>{'poUserId': id},
        queryParameters: <String, dynamic>{'token': token},
        options: Options(
          contentType: Headers.jsonContentType,
          headers: <String, dynamic>{
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final int? code = res.statusCode;
      if (code == 401 || code == 403) {
        AppLogger.w('[PO Party] fetch unauthorized http=$code');
        return null;
      }
      if (code == 404) return null;
      // API returns 400 + "Details not found" when party is not filled yet.
      if (code == 400) {
        final Object? body = res.data;
        if (body is Map) {
          final String msg =
              (body['Message'] ?? body['message'] ?? '').toString().toLowerCase();
          if (msg.contains('not found')) return null;
        }
        return null;
      }
      if (code == null || code < 200 || code >= 300) {
        AppLogger.w('[PO Party] fetch non-2xx http=$code');
        return null;
      }

      final Object? body = res.data;
      if (body is! Map) return null;
      final Map<String, dynamic> map = Map<String, dynamic>.from(body);
      final bool ok = map['Status'] == true || map['Success'] == true;
      if (!ok) return null;
      final Object? data = map['Data'] ?? map['data'];
      if (data is! Map) return null;
      final PoPartyDetails details = PoPartyDetails.fromJson(
        Map<String, dynamic>.from(data),
      );
      if (!details.existsOnServer &&
          details.p1Name.isEmpty &&
          details.p1MobileNo.isEmpty) {
        return null;
      }
      return details;
    } on DioException catch (e) {
      final int? code = e.response?.statusCode;
      if (code == 404 || code == 401 || code == 403) return null;
      AppLogger.w('[PO Party] fetch failed: ${e.message}');
      rethrow;
    }
  }

  /// Saves or updates party details. Returns server id when available.
  Future<String?> savePartyDetails(PoPartyDetails details) async {
    final String token = (await PoElectionAuth.accessToken())?.trim() ?? '';
    if (token.isEmpty) {
      throw const PoPartyApiException(
        'PO session token missing. Please login again.',
        statusCode: 401,
      );
    }

    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        PoElectionEndpoints.savePoParty,
        data: details.toSaveJson(),
        queryParameters: <String, dynamic>{'token': token},
        options: Options(
          contentType: Headers.jsonContentType,
          headers: <String, dynamic>{
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final int? code = res.statusCode;
      if (code == 401 || code == 403) {
        throw const PoPartyApiException(
          'Unauthorized. Please login again.',
          statusCode: 401,
        );
      }
      if (code == 404) {
        throw const PoPartyApiException(
          'Save endpoint not found',
          statusCode: 404,
        );
      }
      if (code == null || code < 200 || code >= 300) {
        throw PoPartyApiException(
          'Save failed (HTTP $code)',
          statusCode: code,
        );
      }

      final Object? body = res.data;
      if (body is! Map) {
        throw const PoPartyApiException('Invalid save response');
      }
      final Map<String, dynamic> map = Map<String, dynamic>.from(body);
      final bool ok = map['Success'] == true || map['Status'] == true;
      if (!ok) {
        final String msg = (map['Message'] ?? map['message'] ?? 'Save failed')
            .toString();
        throw PoPartyApiException(msg);
      }

      // `Status.Id` from save is an action status int (e.g. 1), NOT the party Guid.
      // Prefer Guid from Data, else re-fetch by poUserId.
      final Object? data = map['Data'] ?? map['data'];
      if (data is Map) {
        final Object? id = data['Id'] ?? data['id'];
        if (PoPartyDetails.isPartyGuid(id?.toString())) {
          return id.toString();
        }
      }
      if (PoPartyDetails.isPartyGuid(details.id)) {
        return details.id;
      }
      final PoPartyDetails? refreshed =
          await fetchPartyDetails(details.poUserId);
      if (refreshed != null && refreshed.existsOnServer) {
        return refreshed.id;
      }
      return null;
    } on PoPartyApiException {
      rethrow;
    } on DioException catch (e) {
      throw PoPartyApiException(
        _dioMessage(e, fallback: 'Save failed'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Best-effort remote logout. Returns `true` when server confirms success.
  ///
  /// The API's "already logged in from another device" guard on
  /// `login-po-pass` / `login-survey-pass` is keyed by the `SessionId` claim
  /// embedded in the access token (not just the user id) — so logout must
  /// echo that same `sessionId` back for the server to release the correct
  /// lock. Without it, `po-logout` still reports `Status: true` but the
  /// concurrent-session lock stays held, and the very next login 400s.
  /// Pass [sessionId] explicitly only to override; otherwise it's read from
  /// the current access token's claims.
  Future<bool> logout({
    required String poUserId,
    String? sessionId,
  }) async {
    final String id = poUserId.trim();
    if (id.isEmpty) return false;
    final String token = (await PoElectionAuth.accessToken())?.trim() ?? '';
    final String? resolvedSessionId =
        sessionId ?? (token.isEmpty ? null : JwtUtils.sessionId(token));
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        PoElectionEndpoints.poLogout,
        data: <String, dynamic>{
          'id': id,
          'sessionId': resolvedSessionId,
        },
        queryParameters: token.isEmpty
            ? null
            : <String, dynamic>{'token': token},
        options: Options(
          contentType: Headers.jsonContentType,
          headers: <String, dynamic>{
            'Accept': 'application/json',
            if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
        ),
      );
      final Object? body = res.data;
      if (body is Map) {
        return body['Status'] == true || body['Success'] == true;
      }
      final int? code = res.statusCode;
      return code != null && code >= 200 && code < 300;
    } catch (e) {
      AppLogger.w('[PO Party] logout failed (local clear continues): $e');
      return false;
    }
  }
}

String _dioMessage(DioException e, {required String fallback}) {
  final Object? body = e.response?.data;
  if (body is Map) {
    final Object? msg = body['Message'] ?? body['message'] ?? body['title'];
    if (msg != null && msg.toString().trim().isNotEmpty) {
      return msg.toString();
    }
    final Object? errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final Object? first = errors.values.first;
      if (first is List && first.isNotEmpty) {
        return first.first.toString();
      }
      return first.toString();
    }
  }
  return fallback;
}

class PoPartyApiException implements Exception {
  const PoPartyApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isNotFound => statusCode == 404;
  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}
