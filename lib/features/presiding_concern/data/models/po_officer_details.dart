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
      id: _str(json['Id'] ?? json['id']),
      poUserId: _str(json['POUserId'] ?? json['poUserId']),
      poName: _str(json['POName'] ?? json['PoName'] ?? json['poName']),
      poMobileNo: _str(
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

  static String _str(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;
    final String s = value.toString().trim();
    return s.isEmpty ? fallback : s;
  }
}
