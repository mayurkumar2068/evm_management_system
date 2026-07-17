/// A single recent action shown in the dashboard activity feed.
class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.title,
    required this.timestamp,
    this.subtitle,
  });

  final String id;
  final String title;
  final String? subtitle;
  final DateTime timestamp;
}

/// Aggregated, read-only snapshot powering the dashboard.
class DashboardSummary {
  const DashboardSummary({
    required this.totalControlUnits,
    required this.totalBallotUnits,
    required this.pendingSync,
    required this.scannedToday,
    required this.controlUnitsByStatus,
    required this.recentActivity,
  });

  const DashboardSummary.empty()
    : totalControlUnits = 0,
      totalBallotUnits = 0,
      pendingSync = 0,
      scannedToday = 0,
      controlUnitsByStatus = const <String, int>{},
      recentActivity = const <ActivityItem>[];

  final int totalControlUnits;
  final int totalBallotUnits;
  final int pendingSync;
  final int scannedToday;

  /// Distribution used by the inventory chart, keyed by status label.
  final Map<String, int> controlUnitsByStatus;
  final List<ActivityItem> recentActivity;
}
