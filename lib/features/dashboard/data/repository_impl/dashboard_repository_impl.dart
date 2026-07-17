import 'package:evm_management_system/core/error/error_mapper.dart';
import 'package:evm_management_system/core/error/failure.dart';
import 'package:evm_management_system/core/error/result.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:evm_management_system/features/dashboard/data/datasource/dashboard_local_datasource.dart';
import 'package:evm_management_system/features/dashboard/data/datasource/dashboard_remote_datasource.dart';
import 'package:evm_management_system/features/dashboard/data/mapper/dashboard_mapper.dart';
import 'package:evm_management_system/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:evm_management_system/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:evm_management_system/features/dashboard/domain/repository/dashboard_repository.dart';

/// Offline-first [DashboardRepository]: serve fresh server data when reachable,
/// cache it, and transparently fall back to the local cache when offline.
class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl({
    required DashboardRemoteDataSource remote,
    required DashboardLocalDataSource local,
  }) : _remote = remote,
       _local = local;

  final DashboardRemoteDataSource _remote;
  final DashboardLocalDataSource _local;

  @override
  Future<Result<DashboardSummary>> getSummary({
    bool forceRefresh = false,
  }) async {
    try {
      final DashboardSummaryModel remote = await _remote.fetchSummary();
      await _local.cache(remote);
      return Result<DashboardSummary>.success(DashboardMapper.toEntity(remote));
    } catch (e, s) {
      AppLogger.w(
        'Dashboard remote fetch failed; trying cache',
        error: e,
        stackTrace: s,
      );
      final DashboardSummaryModel? cached = await _local.read();
      if (cached != null) {
        return Result<DashboardSummary>.success(
          DashboardMapper.toEntity(cached),
        );
      }
      return Result<DashboardSummary>.failure(
        ErrorMapper.map(e, s) is NetworkFailure
            ? const NetworkFailure()
            : ErrorMapper.map(e, s),
      );
    }
  }
}
