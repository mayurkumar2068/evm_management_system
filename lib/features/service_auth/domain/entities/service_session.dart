import 'package:evm_management_system/core/utils/json_map.dart';

enum ServiceLoginKind { survey, presiding }

class ServiceSession {
  const ServiceSession({
    required this.token,
    required this.userId,
    required this.name,
    this.kind = ServiceLoginKind.survey,
    this.section,
    this.ttlHours,
    this.districtId,
    this.districtName,
    this.bodyId,
    this.bodyName,
    this.lat,
    this.long,
    this.createdAt,
    this.maleElectors,
    this.femaleElectors,
    this.otherElectors,
    this.totalElectors,
  });

  factory ServiceSession.fromJson(Map<String, dynamic> json) => ServiceSession(
    token: json['token'] as String,
    userId: json['userId'] as String,
    name: json['name'] as String,
    kind: _kindFromJson(json['kind']),
    section: json['section'] as String?,
    ttlHours: json['ttlHours'] as int?,
    districtId: json['districtId'] as String?,
    districtName: json['districtName'] as String?,
    bodyId: json['bodyId'] as String?,
    bodyName: json['bodyName'] as String?,
    lat: (json['lat'] as num?)?.toDouble(),
    long: (json['long'] as num?)?.toDouble(),
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null,
    maleElectors: parseOptionalInt(json['maleElectors']),
    femaleElectors: parseOptionalInt(json['femaleElectors']),
    otherElectors: parseOptionalInt(json['otherElectors']),
    totalElectors: parseOptionalInt(json['totalElectors']),
  );

  final String token;
  final String userId;
  final String name;
  final ServiceLoginKind kind;
  final String? section;
  final int? ttlHours;

  final String? districtId;
  final String? districtName;
  final String? bodyId;
  final String? bodyName;

  final double? lat;
  final double? long;

  final int? maleElectors;
  final int? femaleElectors;
  final int? otherElectors;
  final int? totalElectors;

  final DateTime? createdAt;

  bool get hasElectorCounts =>
      (maleElectors ?? 0) > 0 ||
      (femaleElectors ?? 0) > 0 ||
      (otherElectors ?? 0) > 0 ||
      (totalElectors ?? 0) > 0;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'token': token,
    'userId': userId,
    'name': name,
    'kind': kind.name,
    'section': section,
    'ttlHours': ttlHours,
    'districtId': districtId,
    'districtName': districtName,
    'bodyId': bodyId,
    'bodyName': bodyName,
    'lat': lat,
    'long': long,
    'createdAt': createdAt?.toIso8601String(),
    if (maleElectors != null) 'maleElectors': maleElectors,
    if (femaleElectors != null) 'femaleElectors': femaleElectors,
    if (otherElectors != null) 'otherElectors': otherElectors,
    if (totalElectors != null) 'totalElectors': totalElectors,
  };

  bool get isExpired {
    if (createdAt == null || ttlHours == null) return false;
    return DateTime.now().isAfter(createdAt!.add(Duration(hours: ttlHours!)));
  }

  static ServiceLoginKind _kindFromJson(Object? raw) {
    if (raw == ServiceLoginKind.presiding.name || raw == 'presiding') {
      return ServiceLoginKind.presiding;
    }
    return ServiceLoginKind.survey;
  }
}
