/// DTO for the dashboard summary as returned by the API and cached locally.
class DashboardSummaryModel {
  const DashboardSummaryModel({
    required this.totalControlUnits,
    required this.totalBallotUnits,
    required this.pendingSync,
    required this.scannedToday,
    required this.controlUnitsByStatus,
    required this.recentActivity,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data =
        (json['data'] as Map<String, dynamic>?) ?? json;
    return DashboardSummaryModel(
      totalControlUnits: data['totalControlUnits'] as int? ?? 0,
      totalBallotUnits: data['totalBallotUnits'] as int? ?? 0,
      pendingSync: data['pendingSync'] as int? ?? 0,
      scannedToday: data['scannedToday'] as int? ?? 0,
      controlUnitsByStatus:
          (data['controlUnitsByStatus'] as Map<String, dynamic>?)?.map(
            (String k, Object? v) => MapEntry<String, int>(k, v as int? ?? 0),
          ) ??
          <String, int>{},
      recentActivity: (data['recentActivity'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ActivityItemModel.fromJson)
          .toList(growable: false),
    );
  }

  final int totalControlUnits;
  final int totalBallotUnits;
  final int pendingSync;
  final int scannedToday;
  final Map<String, int> controlUnitsByStatus;
  final List<ActivityItemModel> recentActivity;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'totalControlUnits': totalControlUnits,
    'totalBallotUnits': totalBallotUnits,
    'pendingSync': pendingSync,
    'scannedToday': scannedToday,
    'controlUnitsByStatus': controlUnitsByStatus,
    'recentActivity': recentActivity
        .map((ActivityItemModel a) => a.toJson())
        .toList(),
  };
}

/// DTO for a recent-activity row.
class ActivityItemModel {
  const ActivityItemModel({
    required this.id,
    required this.title,
    required this.timestamp,
    this.subtitle,
  });

  factory ActivityItemModel.fromJson(Map<String, dynamic> json) =>
      ActivityItemModel(
        id: json['id'].toString(),
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String?,
        timestamp:
            DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );

  final String id;
  final String title;
  final String? subtitle;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'timestamp': timestamp.toIso8601String(),
  };
}
