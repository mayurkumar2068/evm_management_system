import 'package:dio/dio.dart';
import 'package:evm_management_system/core/network/api_client.dart';
import 'package:evm_management_system/core/sync/sync_models.dart';

/// Outcome of pushing one [SyncTask] to the server.
sealed class SyncOutcome {
  const SyncOutcome();
}

/// Server accepted the change; [serverData] is the authoritative record.
class SyncSucceeded extends SyncOutcome {
  const SyncSucceeded(this.serverData);
  final Map<String, dynamic>? serverData;
}

/// Server rejected with a version conflict; [serverData] holds its version.
class SyncConflict extends SyncOutcome {
  const SyncConflict(this.serverData);
  final Map<String, dynamic> serverData;
}

/// Transient failure — the task should be retried later.
class SyncRetryable extends SyncOutcome {
  const SyncRetryable(this.reason);
  final String reason;
}

/// Permanent failure — retrying will not help (e.g. 4xx validation).
class SyncFatal extends SyncOutcome {
  const SyncFatal(this.reason);
  final String reason;
}

/// Pushes a single [SyncTask] to the backend and classifies the response.
///
/// Pure transport concern; orchestration/retry lives in the [SyncManager].
class SyncService {
  const SyncService(this._apiClient);

  final ApiClient _apiClient;

  Future<SyncOutcome> push(SyncTask task) async {
    try {
      final Response<dynamic> response = await _send(task);
      return SyncSucceeded(_asMap(response.data));
    } on DioException catch (e) {
      final int? code = e.response?.statusCode;
      if (code == 409) {
        return SyncConflict(_asMap(e.response?.data) ?? <String, dynamic>{});
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

  Map<String, dynamic>? _asMap(Object? data) =>
      data is Map<String, dynamic> ? data : null;
}
