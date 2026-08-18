import 'package:dio/dio.dart';
import 'package:evm_management_system/config/environment_config.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:evm_management_system/core/network/api_endpoints.dart';
import 'package:evm_management_system/core/network/po_election_api_client.dart';
import 'package:evm_management_system/core/network/po_election_auth.dart';
import 'package:evm_management_system/features/presiding_concern/data/models/po_officer_details.dart';

/// Remote calls for PO officer profile (name/mobile + OTP).
class PoOfficerDetailsDatasource {
  PoOfficerDetailsDatasource(this._config);

  final EnvironmentConfig _config;

  Dio get _dio => PoElectionApiClient.instance(_config);

  Future<Map<String, dynamic>> _authHeaders() async {
    final String token = (await PoElectionAuth.accessToken())?.trim() ?? '';
    if (token.isEmpty) {
      throw const PoOfficerDetailsException(
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

  /// Returns details when Status=true; `null` when not found / empty.
  Future<PoOfficerDetails?> fetchDetails(String poUserId) async {
    final String id = poUserId.trim();
    if (id.isEmpty) return null;

    try {
      final Map<String, dynamic> auth = await _authHeaders();
      final Response<dynamic> res = await _dio.post<dynamic>(
        PoElectionEndpoints.poDetails,
        data: <String, dynamic>{'poUserId': id},
        queryParameters: <String, dynamic>{'token': auth['token']},
        options: Options(
          contentType: Headers.jsonContentType,
          headers: auth['headers'] as Map<String, dynamic>,
        ),
      );

      _throwIfUnauthorized(res.statusCode);
      if (_isEmptyProfileStatus(res.statusCode)) return null;

      final Object? body = res.data;
      if (body is! Map) return null;
      final Map<String, dynamic> map = Map<String, dynamic>.from(body);
      final bool ok = map['Status'] == true || map['Success'] == true;
      if (!ok) return null;
      final Object? data = map['Data'] ?? map['data'];
      if (data is! Map) return null;
      final PoOfficerDetails details = PoOfficerDetails.fromJson(
        Map<String, dynamic>.from(data),
      );
      if (!details.hasProfile) return null;
      if (details.poUserId.isEmpty) {
        return details.copyWith(poUserId: id);
      }
      return details;
    } on PoOfficerDetailsException {
      rethrow;
    } on DioException catch (e) {
      final int? code = e.response?.statusCode;
      _throwIfUnauthorized(code);
      if (code == 400 || code == 404) {
        return null;
      }
      AppLogger.w('[PO Details] fetch failed: ${e.message}');
      throw PoOfficerDetailsException(
        _dioMessage(e, fallback: 'Could not load PO details'),
        statusCode: code,
      );
    }
  }

  Future<void> sendOtp(String mobileNo) async {
    final String mobile = mobileNo.trim();
    if (mobile.isEmpty) {
      throw const PoOfficerDetailsException('Mobile number is required');
    }
    try {
      final Map<String, dynamic> auth = await _authHeaders();
      final Response<dynamic> res = await _dio.post<dynamic>(
        PoElectionEndpoints.poSendOtp,
        data: <String, dynamic>{'mobileNo': mobile},
        queryParameters: <String, dynamic>{'token': auth['token']},
        options: Options(
          contentType: Headers.jsonContentType,
          headers: auth['headers'] as Map<String, dynamic>,
        ),
      );
      _throwIfUnauthorized(res.statusCode);
      final int? code = res.statusCode;
      if (code == null || code < 200 || code >= 300) {
        throw PoOfficerDetailsException(
          'OTP send failed',
          statusCode: code,
        );
      }
      final Object? body = res.data;
      if (body is! Map) {
        throw PoOfficerDetailsException(
          'OTP send failed',
          statusCode: code,
        );
      }
      final Map<String, dynamic> map = Map<String, dynamic>.from(body);
      final bool ok = map['Status'] == true || map['Success'] == true;
      if (!ok) {
        throw PoOfficerDetailsException(
          (map['Message'] ?? map['message'] ?? 'OTP send failed').toString(),
        );
      }
    } on PoOfficerDetailsException {
      rethrow;
    } on DioException catch (e) {
      _throwIfUnauthorized(e.response?.statusCode);
      throw PoOfficerDetailsException(
        _dioMessage(e, fallback: 'OTP send failed'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> saveWithOtp({
    required PoOfficerDetails details,
    required String otp,
  }) async {
    try {
      final Map<String, dynamic> auth = await _authHeaders();
      final Response<dynamic> res = await _dio.post<dynamic>(
        PoElectionEndpoints.poDetailSaveWithOtp,
        data: details.toSaveWithOtpJson(otp: otp),
        queryParameters: <String, dynamic>{'token': auth['token']},
        options: Options(
          contentType: Headers.jsonContentType,
          headers: auth['headers'] as Map<String, dynamic>,
        ),
      );
      _throwIfUnauthorized(res.statusCode);
      final int? code = res.statusCode;
      if (code == null || code < 200 || code >= 300) {
        throw PoOfficerDetailsException(
          'Save failed (HTTP $code)',
          statusCode: code,
        );
      }
      final Object? body = res.data;
      if (body is! Map) {
        throw PoOfficerDetailsException(
          'Save failed',
          statusCode: code,
        );
      }
      final Map<String, dynamic> map = Map<String, dynamic>.from(body);
      final bool ok = map['Status'] == true || map['Success'] == true;
      if (!ok) {
        throw PoOfficerDetailsException(
          (map['Message'] ?? map['message'] ?? 'Save failed').toString(),
        );
      }
    } on PoOfficerDetailsException {
      rethrow;
    } on DioException catch (e) {
      _throwIfUnauthorized(e.response?.statusCode);
      throw PoOfficerDetailsException(
        _dioMessage(e, fallback: 'Save failed'),
        statusCode: e.response?.statusCode,
      );
    }
  }
}

class PoOfficerDetailsException implements Exception {
  const PoOfficerDetailsException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}

String _dioMessage(DioException e, {required String fallback}) {
  final Object? body = e.response?.data;
  if (body is Map) {
    final Object? msg = body['Message'] ?? body['message'] ?? body['title'];
    if (msg != null && msg.toString().trim().isNotEmpty) {
      return msg.toString();
    }
  }
  return fallback;
}

void _throwIfUnauthorized(int? code) {
  if (code == 401 || code == 403) {
    throw PoOfficerDetailsException(
      'Session expired. Please login again.',
      statusCode: code,
    );
  }
}

bool _isEmptyProfileStatus(int? code) {
  return code == 400 || code == 404;
}
