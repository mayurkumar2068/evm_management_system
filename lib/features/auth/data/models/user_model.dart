/// Data-transfer object for the user as returned by the API / stored locally.
///
/// Kept separate from the [AuthUser] domain entity; conversion happens in
/// `UserMapper` so transport concerns never leak into the domain.
class UserModel {
  const UserModel({
    required this.id,
    required this.officerId,
    required this.fullName,
    required this.role,
    this.email,
    this.designation,
    this.stateCode,
    this.districtCode,
    this.electionId,
    this.psId,
    this.areaType,
    this.pollingStationCode,
    this.pollingStationName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'].toString(),
    officerId:
        json['officerId'] as String? ?? json['officer_id'] as String? ?? '',
    fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? '',
    role: json['role'] as String? ?? 'unknown',
    email: json['email'] as String?,
    designation: json['designation'] as String?,
    stateCode: json['stateCode'] as String? ?? json['state_code'] as String?,
    districtCode:
        json['districtCode'] as String? ?? json['district_code'] as String?,
    electionId: _parseOptionalInt(json['electionId'] ?? json['election_id']),
    psId:
        json['psId'] as String? ??
        json['ps_id'] as String? ??
        json['PSID'] as String?,
    areaType: json['areaType'] as String? ?? json['area_type'] as String?,
    pollingStationCode:
        json['pollingStationCode'] as String? ??
        json['polling_station_code'] as String? ??
        json['boothId'] as String?,
    pollingStationName:
        json['pollingStationName'] as String? ??
        json['polling_station_name'] as String? ??
        json['boothName'] as String?,
  );

  static int? _parseOptionalInt(Object? raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }

  final String id;
  final String officerId;
  final String fullName;
  final String role;
  final String? email;
  final String? designation;
  final String? stateCode;
  final String? districtCode;
  final int? electionId;
  final String? psId;
  final String? areaType;
  final String? pollingStationCode;
  final String? pollingStationName;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'officerId': officerId,
    'fullName': fullName,
    'role': role,
    'email': email,
    'designation': designation,
    'stateCode': stateCode,
    'districtCode': districtCode,
    'electionId': electionId,
    'psId': psId,
    'areaType': areaType,
    'pollingStationCode': pollingStationCode,
    'pollingStationName': pollingStationName,
  };
}
