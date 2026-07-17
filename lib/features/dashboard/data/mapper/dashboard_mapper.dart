import 'package:evm_management_system/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:evm_management_system/features/dashboard/domain/entities/dashboard_summary.dart';

/// Maps dashboard DTOs to domain entities.
abstract final class DashboardMapper {
  static DashboardSummary toEntity(DashboardSummaryModel model) =>
      DashboardSummary(
        totalControlUnits: model.totalControlUnits,
        totalBallotUnits: model.totalBallotUnits,
        pendingSync: model.pendingSync,
        scannedToday: model.scannedToday,
        controlUnitsByStatus: model.controlUnitsByStatus,
        recentActivity: model.recentActivity
            .map(
              (ActivityItemModel a) => ActivityItem(
                id: a.id,
                title: a.title,
                subtitle: a.subtitle,
                timestamp: a.timestamp,
              ),
            )
            .toList(growable: false),
      );
}
