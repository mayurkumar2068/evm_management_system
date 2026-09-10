import 'package:dio/dio.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:evm_management_system/core/network/api_endpoints.dart';
import 'package:evm_management_system/core/network/api_envelope.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/po_api_exception.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/po_election_base_datasource.dart';
import 'package:evm_management_system/features/presiding_concern/data/models/po_officer_details.dart';

class PoOfficerDetailsDatasource extends PoElectionBaseDatasource {
  PoOfficerDetailsDatasource(super.config);

  Future<PoOfficerDetails?> fetchDetails(String poUserId) async {
    final String id = poUserId.trim();
    if (id.isEmpty) return null;

    try {
      final Response<dynamic> res = await authedPost(
        PoElectionEndpoints.poDetails,
        <String, dynamic>{'poUserId': id},
      );

      throwIfUnauthorized(res.statusCode);
      if (res.statusCode == 400 || res.statusCode == 404) return null;

      final Map<String, dynamic>? data = ApiEnvelope.unwrap(res.data);
      if (data == null) return null;
      return PoOfficerDetails.tryParse(data, fallbackUserId: id);
    } on PoApiException {
      rethrow;
    } on DioException catch (e) {
      final int? code = e.response?.statusCode;
      throwIfUnauthorized(code);
      if (code == 400 || code == 404) {
        return null;
      }
      AppLogger.w('[PO Details] fetch failed: ${e.message}');
      throw PoApiException(
        dioMessage(e, fallback: 'Could not load PO details'),
        statusCode: code,
      );
    }
  }

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
      throwIfUnauthorized(res.statusCode);
      final int? code = res.statusCode;
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
      throwIfUnauthorized(e.response?.statusCode);
      throw PoApiException(
        dioMessage(e, fallback: 'OTP send failed'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> saveWithOtp({
    required PoOfficerDetails details,
    required String otp,
  }) async {
    try {
      final Response<dynamic> res = await authedPost(
        PoElectionEndpoints.poDetailSaveWithOtp,
        details.toSaveWithOtpJson(otp: otp),
      );
      throwIfUnauthorized(res.statusCode);
      final int? code = res.statusCode;
      if (code == null || code < 200 || code >= 300) {
        throw PoApiException('Save failed (HTTP $code)', statusCode: code);
      }
      if (!ApiEnvelope.isSuccess(res.data)) {
        throw PoApiException(ApiEnvelope.message(res.data) ?? 'Save failed');
      }
    } on PoApiException {
      rethrow;
    } on DioException catch (e) {
      throwIfUnauthorized(e.response?.statusCode);
      throw PoApiException(
        dioMessage(e, fallback: 'Save failed'),
        statusCode: e.response?.statusCode,
      );
    }
  }
}
