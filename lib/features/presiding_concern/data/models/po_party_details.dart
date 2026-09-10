import 'package:evm_management_system/core/utils/json_map.dart';

/// PO party / polling-party details from POElection API.
class PoPartyDetails {
  const PoPartyDetails({
    this.id,
    required this.poUserId,
    this.partyNo = '',
    this.p1Name = '',
    this.p1MobileNo = '',
    this.p2Name = '',
    this.p2MobileNo = '',
    this.p3Name = '',
    this.p3MobileNo = '',
    this.p4Name = '',
    this.p4MobileNo = '',
  });

  factory PoPartyDetails.fromJson(Map<String, dynamic> json) {
    final String rawId = coercedString(json['Id'] ?? json['id']);
    return PoPartyDetails(
      id: isPartyGuid(rawId) ? rawId : null,
      poUserId: coercedString(json['POUserId'] ?? json['poUserId']),
      partyNo: coercedString(json['PartyNo'] ?? json['partyNo']),
      p1Name: coercedString(json['P1Name'] ?? json['p1Name']),
      p1MobileNo: coercedString(json['P1MobileNo'] ?? json['p1MobileNo']),
      p2Name: coercedString(json['P2Name'] ?? json['p2Name']),
      p2MobileNo: coercedString(json['P2MobileNo'] ?? json['p2MobileNo']),
      p3Name: coercedString(json['P3Name'] ?? json['p3Name']),
      p3MobileNo: coercedString(json['P3MobileNo'] ?? json['p3MobileNo']),
      p4Name: coercedString(json['P4Name'] ?? json['p4Name']),
      p4MobileNo: coercedString(json['P4MobileNo'] ?? json['p4MobileNo']),
    );
  }

  final String? id;
  final String poUserId;
  final String partyNo;
  final String p1Name;
  final String p1MobileNo;
  final String p2Name;
  final String p2MobileNo;
  final String p3Name;
  final String p3MobileNo;
  final String p4Name;
  final String p4MobileNo;

  bool get existsOnServer => isPartyGuid(id);

  /// Local cache / pending-sync payload (no OTP — party save does not use it).
  Map<String, dynamic> toCacheJson() => <String, dynamic>{
    'id': id,
    'poUserId': poUserId,
    'partyNo': partyNo,
    'p1Name': p1Name,
    'p1MobileNo': p1MobileNo,
    'p2Name': p2Name,
    'p2MobileNo': p2MobileNo,
    'p3Name': p3Name,
    'p3MobileNo': p3MobileNo,
    'p4Name': p4Name,
    'p4MobileNo': p4MobileNo,
  };

  /// `save-po-party` body. OTP is not used for दल की जानकारी.
  Map<String, dynamic> toSaveJson() => <String, dynamic>{
    // Server expects Nullable<Guid>; never send action-status ints like "1".
    'id': existsOnServer ? id : null,
    'poUserId': poUserId,
    'partyNo': partyNo.trim(),
    'p1Name': _nullIfEmpty(p1Name),
    'p1MobileNo': _nullIfEmpty(p1MobileNo),
    'p2Name': _nullIfEmpty(p2Name),
    'p2MobileNo': _nullIfEmpty(p2MobileNo),
    'p3Name': _nullIfEmpty(p3Name),
    'p3MobileNo': _nullIfEmpty(p3MobileNo),
    'p4Name': _nullIfEmpty(p4Name),
    'p4MobileNo': _nullIfEmpty(p4MobileNo),
  };

  /// True when [value] is a Guid string (party record id), not an int status id.
  static bool isPartyGuid(String? value) {
    if (value == null) return false;
    final String t = value.trim();
    if (t.isEmpty) return false;
    return _guidPattern.hasMatch(t);
  }

  static final RegExp _guidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  PoPartyDetails copyWith({
    String? id,
    String? poUserId,
    String? partyNo,
    String? p1Name,
    String? p1MobileNo,
    String? p2Name,
    String? p2MobileNo,
    String? p3Name,
    String? p3MobileNo,
    String? p4Name,
    String? p4MobileNo,
  }) {
    return PoPartyDetails(
      id: id ?? this.id,
      poUserId: poUserId ?? this.poUserId,
      partyNo: partyNo ?? this.partyNo,
      p1Name: p1Name ?? this.p1Name,
      p1MobileNo: p1MobileNo ?? this.p1MobileNo,
      p2Name: p2Name ?? this.p2Name,
      p2MobileNo: p2MobileNo ?? this.p2MobileNo,
      p3Name: p3Name ?? this.p3Name,
      p3MobileNo: p3MobileNo ?? this.p3MobileNo,
      p4Name: p4Name ?? this.p4Name,
      p4MobileNo: p4MobileNo ?? this.p4MobileNo,
    );
  }


  static Object? _nullIfEmpty(String value) {
    final String t = value.trim();
    return t.isEmpty ? null : t;
  }
}
