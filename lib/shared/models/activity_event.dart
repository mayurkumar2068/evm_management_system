enum ActivityType {
  registered,
  scanned,
  updated,
  login,
  sync,
  exported;

  static ActivityType fromName(String name) => ActivityType.values.firstWhere(
    (ActivityType t) => t.name == name,
    orElse: () => ActivityType.updated,
  );
}

class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.deviceId,
    required this.officer,
    required this.timestamp,
  });

  factory ActivityEvent.fromJson(Map<String, dynamic> json) => ActivityEvent(
    id: json['id'] as String,
    type: ActivityType.fromName(json['type'] as String? ?? 'updated'),
    title: json['title'] as String? ?? '',
    deviceId: json['deviceId'] as String? ?? '',
    officer: json['officer'] as String? ?? '',
    timestamp:
        DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
  );

  final String id;
  final ActivityType type;
  final String title;
  final String deviceId;
  final String officer;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'type': type.name,
    'title': title,
    'deviceId': deviceId,
    'officer': officer,
    'timestamp': timestamp.toIso8601String(),
  };
}
