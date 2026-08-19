import 'package:dio/dio.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:evm_management_system/core/network/api_endpoints.dart';
import 'package:evm_management_system/core/network/api_envelope.dart';
import 'package:evm_management_system/core/network/po_election_auth.dart';
import 'package:evm_management_system/core/security/jwt_utils.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/po_api_exception.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/po_election_base_datasource.dart';
import 'package:evm_management_system/features/presiding_concern/data/models/po_party_details.dart';

/// Remote calls for PO party details, and PO/PS Survey logout.
class PoPartyRemoteDatasource extends PoElectionBaseDatasource {
  PoPartyRemoteDatasource(super.config);

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
      final Response<dynamic> res = await dio.post<dynamic>(
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
      if (code == 400) {
        final String msg =
            (ApiEnvelope.message(res.data) ?? '').toLowerCase();
        if (msg.contains('not found')) return null;
        return null;
      }
      if (code == null || code < 200 || code >= 300) {
        AppLogger.w('[PO Party] fetch non-2xx http=$code');
        return null;
      }

      final Map<String, dynamic>? data = ApiEnvelope.unwrap(res.data);
      if (data == null) return null;
      final PoPartyDetails details = PoPartyDetails.fromJson(data);
      if (!details.existsOnServer &&
          details.p1Name.isEmpty &&
          details.p1MobileNo.isEmpty) {
        return null;
      }
      return details;
    } on DioException catch (e) {
      final int? code = e.response?.statusCode;
      if (code == 400 || code == 404 || code == 401 || code == 403) {
        return null;
      }
      if (isTransientDio(e)) return null;
      AppLogger.w('[PO Party] fetch failed: ${e.message}');
      return null;
    }
  }

  /// Sends SMS OTP to [mobileNo] via `po-send-otp` (same store as PO details).
  Future<void> sendOtp(String mobileNo) async {
    final String mobile = mobileNo.trim();
    if (mobile.isEmpty) {
      throw const PoApiException('Mobile number is required');
    }
    try {
      final Response<dynamic> res = await authedPost(
        PoElectionEndpoints.poSendOtp,
        <String, dynamic>{'mobileNo': mobile},
      );
      final int? code = res.statusCode;
      if (code == 401 || code == 403) {
        throw const PoApiException(
          'Unauthorized. Please login again.',
          statusCode: 401,
        );
      }
      if (code == null || code < 200 || code >= 300) {
        throw PoApiException('OTP send failed', statusCode: code);
      }
      if (!ApiEnvelope.isSuccess(res.data)) {
        throw PoApiException(
          ApiEnvelope.message(res.data) ?? 'OTP send failed',
        );
      }
    } on PoApiException {
      rethrow;
    } on DioException catch (e) {
      throw PoApiException(
        dioMessage(e, fallback: 'OTP send failed'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Saves or updates party details via `save-po-party` (no OTP).
  /// Returns server id when available.
  Future<String?> savePartyDetails(PoPartyDetails details) async {
    try {
      final Response<dynamic> res = await authedPost(
        PoElectionEndpoints.savePoParty,
        details.toSaveJson(),
      );

      final int? code = res.statusCode;
      if (code == 401 || code == 403) {
        throw const PoApiException(
          'Unauthorized. Please login again.',
          statusCode: 401,
        );
      }
      if (code == 404) {
        throw const PoApiException(
          'Save endpoint not found',
          statusCode: 404,
        );
      }
      if (code == null || code < 200 || code >= 300) {
        throw PoApiException('Save failed (HTTP $code)', statusCode: code);
      }

      final Object? body = res.data;
      if (body is! Map) {
        throw const PoApiException('Invalid save response');
      }
      final Map<String, dynamic> map = Map<String, dynamic>.from(body);
      final bool ok = map['Success'] == true || map['Status'] == true;
      if (!ok) {
        final String msg =
            (map['Message'] ?? map['message'] ?? 'Save failed').toString();
        throw PoApiException(msg);
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
    } on PoApiException {
      rethrow;
    } on DioException catch (e) {
      throw PoApiException(
        dioMessage(e, fallback: 'Save failed'),
        statusCode: e.response?.statusCode,
        offline: isTransientDio(e),
      );
    }
  }

  /// Best-effort remote logout. Returns `true` when server confirms success.
  ///
  /// The API's "already logged in from another device" guard on
  /// `login-po-pass` / `login-survey-pass` is keyed by the `SessionId` claim
  /// embedded in the access token (not just the user id) — so logout must
  /// echo that same `sessionId` back for the server to release the correct
  /// lock. Without it, `po-logout`/`ps-logout` still reports `Status: true`
  /// but the concurrent-session lock stays held, and the very next login
  /// 400s. Pass [sessionId] explicitly only to override; otherwise it's read
  /// from the current access token's claims.
  ///
  /// [isSurveyUser] selects the endpoint: `ps-logout` for Booth/PS Survey
  /// sessions (`ServiceLoginKind.survey`), `po-logout` for Presiding Officer
  /// sessions (`ServiceLoginKind.presiding`, the default).
  Future<bool> logout({
    required String poUserId,
    String? sessionId,
    bool isSurveyUser = false,
  }) async {
    final String id = poUserId.trim();
    if (id.isEmpty) return false;
    final String token = (await PoElectionAuth.accessToken())?.trim() ?? '';
    final String? resolvedSessionId =
        sessionId ?? (token.isEmpty ? null : JwtUtils.sessionId(token));
    final String endpoint = isSurveyUser
        ? PoElectionEndpoints.psLogout
        : PoElectionEndpoints.poLogout;
    try {
      final Response<dynamic> res = await dio.post<dynamic>(
        endpoint,
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
      return ApiEnvelope.isSuccess(res.data) ||
          (res.statusCode != null &&
              res.statusCode! >= 200 &&
              res.statusCode! < 300);
    } catch (e) {
      AppLogger.w('[PO Party] $endpoint failed (local clear continues): $e');
      return false;
    }
  }
}
