import 'package:dio/dio.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:evm_management_system/core/network/api_envelope.dart';
import 'package:evm_management_system/core/utils/json_map.dart';
import 'package:evm_management_system/features/grievance/data/grievance_endpoints.dart';
import 'package:evm_management_system/features/grievance/data/models/grievance_models.dart';

class GrievanceApiException implements Exception {
  const GrievanceApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GrievanceRemoteDatasource {
  GrievanceRemoteDatasource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<String> sendOtp({required String mobileNo}) async {
    final Response<dynamic> res;
    try {
      res = await _dio.post<dynamic>(
        GrievanceEndpoints.sendOtp,
        data: <String, dynamic>{'mobileNo': mobileNo},
        options: Options(
          contentType: Headers.jsonContentType,
          extra: <String, dynamic>{'skipAuth': true},
        ),
      );
    } on DioException catch (e) {
      AppLogger.w(
        '[GrievanceAPI] send-otp DioException http=${e.response?.statusCode} '
        'err=${e.message}',
      );
      throw GrievanceApiException(_networkOrServerMessage(e));
    }

    final Map<String, dynamic> envelope =
        asStringKeyedMap(res.data) ?? <String, dynamic>{};
    final bool ok = ApiEnvelope.isSuccess(envelope);
    final String message = ApiEnvelope.message(envelope) ?? '';

    if (res.statusCode != 200 || !ok) {
      throw GrievanceApiException(
        message.isNotEmpty ? message : 'Failed to send OTP',
      );
    }
    return message;
  }

  Future<void> verifyOtp({
    required String mobileNo,
    required String otp,
  }) async {
    final Response<dynamic> res;
    try {
      res = await _dio.post<dynamic>(
        GrievanceEndpoints.verifyOtp,
        data: <String, dynamic>{'mobileNo': mobileNo, 'otp': otp},
        options: Options(
          contentType: Headers.jsonContentType,
          extra: <String, dynamic>{'skipAuth': true},
        ),
      );
    } on DioException catch (e) {
      AppLogger.w(
        '[GrievanceAPI] verify-otp DioException http=${e.response?.statusCode} '
        'err=${e.message}',
      );
      throw GrievanceApiException(_networkOrServerMessage(e));
    }

    final Map<String, dynamic> envelope =
        asStringKeyedMap(res.data) ?? <String, dynamic>{};
    final bool ok = ApiEnvelope.isSuccess(envelope);
    if (res.statusCode != 200 || !ok) {
      final String message = ApiEnvelope.message(envelope) ?? '';
      throw GrievanceApiException(
        message.isNotEmpty ? message : 'Invalid or expired OTP',
      );
    }
  }

  Future<GrievanceSubmissionResult> register(
    GrievanceSubmission submission,
  ) async {
    final Response<dynamic> res;
    try {
      res = await _dio.post<dynamic>(
        GrievanceEndpoints.register,
        data: submission.toJson(),
        options: Options(
          contentType: Headers.jsonContentType,
          extra: <String, dynamic>{'skipAuth': true},
        ),
      );
    } on DioException catch (e) {
      AppLogger.w(
        '[GrievanceAPI] register DioException http=${e.response?.statusCode} '
        'err=${e.message}',
      );
      throw GrievanceApiException(_networkOrServerMessage(e));
    }

    final Map<String, dynamic> envelope =
        asStringKeyedMap(res.data) ?? <String, dynamic>{};
    final bool ok = ApiEnvelope.isSuccess(envelope);
    final String message = ApiEnvelope.message(envelope) ?? '';
    if (res.statusCode != 200 || !ok) {
      throw GrievanceApiException(
        message.isNotEmpty ? message : 'Failed to submit grievance',
      );
    }

    final Map<String, dynamic> data = ApiEnvelope.unwrap(envelope) ?? {};
    final String referenceNo =
        (data['referenceNo'] ?? data['ReferenceNo'] ?? '').toString();
    return GrievanceSubmissionResult(
      referenceNo: referenceNo,
      message: message,
    );
  }

  String _networkOrServerMessage(DioException e) {
    final dynamic data = e.response?.data;
    if (data is Map) {
      final Object? message = data['Message'] ?? data['message'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }
    final int? code = e.response?.statusCode;
    if (code != null && code >= 500) {
      return 'Server error. Please try again later.';
    }
    return 'Network error. Please try again.';
  }
}
