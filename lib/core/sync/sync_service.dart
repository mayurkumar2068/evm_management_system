import 'package:dio/dio.dart';
import 'package:evm_management_system/core/network/api_client.dart';
import 'package:evm_management_system/core/sync/sync_models.dart';
import 'package:evm_management_system/core/utils/json_map.dart';

sealed class SyncOutcome {
  const SyncOutcome();
}

class SyncSucceeded extends SyncOutcome {
  const SyncSucceeded(this.serverData);
  final Map<String, dynamic>? serverData;
}

class SyncConflict extends SyncOutcome {
  const SyncConflict(this.serverData);
  final Map<String, dynamic> serverData;
}

class SyncRetryable extends SyncOutcome {
  const SyncRetryable(this.reason);
  final String reason;
}

class SyncFatal extends SyncOutcome {
  const SyncFatal(this.reason);
  final String reason;
}

class SyncService {
  const SyncService(this._apiClient);

  final ApiClient _apiClient;

  Future<SyncOutcome> push(SyncTask task) async {
    try {
      final Response<dynamic> response = await _send(task);
      return SyncSucceeded(asStringKeyedMap(response.data));
    } on DioException catch (e) {
      final int? code = e.response?.statusCode;
      if (code == 409) {
        return SyncConflict(
          asStringKeyedMap(e.response?.data) ?? <String, dynamic>{},
        );
      }
      if (code != null && code >= 400 && code < 500 && code != 408) {
        return SyncFatal('HTTP $code: ${e.message}');
      }
      return SyncRetryable(e.message ?? 'transient error');
    }
  }

  Future<Response<dynamic>> _send(SyncTask task) {
    final Map<String, dynamic> body = <String, dynamic>{
      ...task.payload,
      'clientVersion': task.version,
    };
    return switch (task.operation) {
      SyncOperation.create => _apiClient.post<dynamic>(
        task.endpoint,
        data: body,
      ),
      SyncOperation.update => _apiClient.put<dynamic>(
        '${task.endpoint}/${task.entityId}',
        data: body,
      ),
      SyncOperation.delete => _apiClient.delete<dynamic>(
        '${task.endpoint}/${task.entityId}',
      ),
    };
  }
}
