import 'package:evm_management_system/core/database/local_database.dart';
import 'package:evm_management_system/features/dashboard/data/models/dashboard_summary_model.dart';

/// Local cache for the dashboard summary, enabling offline-first reads.
abstract interface class DashboardLocalDataSource {
  Future<void> cache(DashboardSummaryModel model);
  Future<DashboardSummaryModel?> read();
}

class DashboardLocalDataSourceImpl implements DashboardLocalDataSource {
  const DashboardLocalDataSourceImpl(this._db);

  final LocalDatabase _db;

  static const String _collection = 'dashboard';
  static const String _key = 'summary';

  @override
  Future<void> cache(DashboardSummaryModel model) =>
      _db.put(_collection, _key, model.toJson());

  @override
  Future<DashboardSummaryModel?> read() async {
    final Map<String, dynamic>? json = await _db.get(_collection, _key);
    if (json == null) return null;
    return DashboardSummaryModel.fromJson(json);
  }
}
