import 'package:dio/dio.dart';
import 'package:evm_management_system/core/network/api_client.dart';
import 'package:evm_management_system/core/network/api_endpoints.dart';
import 'package:evm_management_system/features/dashboard/data/models/dashboard_summary_model.dart';

/// Network access for the dashboard summary.
abstract interface class DashboardRemoteDataSource {
  Future<DashboardSummaryModel> fetchSummary();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  const DashboardRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<DashboardSummaryModel> fetchSummary() async {
    final Response<Map<String, dynamic>> response = await _apiClient
        .get<Map<String, dynamic>>(ApiEndpoints.dashboardSummary);
    return DashboardSummaryModel.fromJson(response.data ?? <String, dynamic>{});
  }
}
