import 'package:evm_management_system/core/error/result.dart';
import 'package:evm_management_system/features/dashboard/domain/entities/dashboard_summary.dart';

/// Domain contract for dashboard data (offline-first).
abstract interface class DashboardRepository {
  /// Returns the dashboard summary, preferring fresh server data and falling
  /// back to the local cache when offline.
  Future<Result<DashboardSummary>> getSummary({bool forceRefresh = false});
}
