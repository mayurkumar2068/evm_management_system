import 'package:evm_management_system/core/error/result.dart';
import 'package:evm_management_system/core/usecase/usecase.dart';
import 'package:evm_management_system/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:evm_management_system/features/dashboard/domain/repository/dashboard_repository.dart';

/// Parameters for [GetDashboardSummaryUseCase].
class DashboardSummaryParams {
  const DashboardSummaryParams({this.forceRefresh = false});
  final bool forceRefresh;
}

/// Loads the aggregated dashboard summary.
class GetDashboardSummaryUseCase
    implements UseCase<DashboardSummary, DashboardSummaryParams> {
  const GetDashboardSummaryUseCase(this._repository);

  final DashboardRepository _repository;

  @override
  Future<Result<DashboardSummary>> call(DashboardSummaryParams params) =>
      _repository.getSummary(forceRefresh: params.forceRefresh);
}
