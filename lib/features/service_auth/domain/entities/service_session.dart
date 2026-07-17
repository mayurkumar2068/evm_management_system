/// Session granted by the survey API (`/api/Account/login-survey-pass`) when an officer logs in
/// to open a government web service. The [token] is forwarded to the WebView as
/// `?token=` and attached to every Angular API call.
class ServiceSession {
  const ServiceSession({
    required this.token,
    required this.userId,
    required this.name,
    this.section,
    this.ttlHours,
    this.districtId,
    this.districtName,
    this.bodyId,
    this.bodyName,
    this.lat,
    this.long,
    this.createdAt,
  });

  factory ServiceSession.fromJson(Map<String, dynamic> json) => ServiceSession(
    token: json['token'] as String,
    userId: json['userId'] as String,
    name: json['name'] as String,
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
  );

  final String token;
  final String userId;
  final String name;
  final String? section;
  final int? ttlHours;

  /// District context returned by the survey login response. Forwarded to
  /// the WebView session context as `X-District-Id`.
  final String? districtId;
  final String? districtName;
  final String? bodyId;
  final String? bodyName;

  /// Coordinates from login-survey-pass response (`Lat` / `Long`).
  final double? lat;
  final double? long;

  /// When the session was created. Used to check expiry locally.
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'token': token,
    'userId': userId,
    'name': name,
    'section': section,
    'ttlHours': ttlHours,
    'districtId': districtId,
    'districtName': districtName,
    'bodyId': bodyId,
    'bodyName': bodyName,
    'lat': lat,
    'long': long,
    'createdAt': createdAt?.toIso8601String(),
  };

  bool get isExpired {
    if (createdAt == null || ttlHours == null) return false;
    return DateTime.now().isAfter(createdAt!.add(Duration(hours: ttlHours!)));
  }
}
