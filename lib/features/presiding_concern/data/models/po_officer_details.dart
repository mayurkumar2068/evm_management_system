import 'package:evm_management_system/core/utils/json_map.dart';

/// Presiding officer profile details from `po-details` / save-with-otp APIs.
class PoOfficerDetails {
  const PoOfficerDetails({
    this.id,
    required this.poUserId,
    this.poName = '',
    this.poMobileNo = '',
  });

  factory PoOfficerDetails.fromJson(Map<String, dynamic> json) {
    return PoOfficerDetails(
      id: coercedString(json['Id'] ?? json['id']),
      poUserId: coercedString(json['POUserId'] ?? json['poUserId']),
      poName: coercedString(json['POName'] ?? json['PoName'] ?? json['poName']),
      poMobileNo: coercedString(
        json['POMobileNo'] ?? json['PoMobileNo'] ?? json['poMobileNo'],
      ),
    );
  }

  final String? id;
  final String poUserId;
  final String poName;
  final String poMobileNo;

  static PoOfficerDetails? tryParse(
    Map<String, dynamic> json, {
    String? fallbackUserId,
  }) {
    final details = PoOfficerDetails.fromJson(json);
    if (details.poName.trim().isEmpty && details.poMobileNo.trim().isEmpty) {
      return null;
    }
    if (details.poUserId.isEmpty && fallbackUserId != null) {
      return details.copyWith(poUserId: fallbackUserId);
    }
    return details;
  }

  bool get hasProfile =>
      poName.trim().isNotEmpty && poMobileNo.trim().length == 10;

  bool get hasServerId {
    final String? value = id?.trim();
    if (value == null || value.isEmpty) return false;
    return _guidPattern.hasMatch(value);
  }

  Map<String, dynamic> toSaveWithOtpJson({required String otp}) =>
      <String, dynamic>{
        // Create → null; update (mobile change) → existing Guid from po-details.
        'id': hasServerId ? id!.trim() : null,
        'poUserId': poUserId,
        'poName': poName.trim(),
        'poMobileNo': poMobileNo.trim(),
        'otp': otp.trim(),
      };

  static final RegExp _guidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  PoOfficerDetails copyWith({
    String? id,
    String? poUserId,
    String? poName,
    String? poMobileNo,
  }) {
    return PoOfficerDetails(
      id: id ?? this.id,
      poUserId: poUserId ?? this.poUserId,
      poName: poName ?? this.poName,
      poMobileNo: poMobileNo ?? this.poMobileNo,
    );
  }

}
