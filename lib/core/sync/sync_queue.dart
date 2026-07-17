import 'package:evm_management_system/core/database/local_database.dart';
import 'package:evm_management_system/core/sync/sync_models.dart';

/// Durable FIFO queue of [SyncTask]s persisted in the local database.
///
/// Survives app restarts so no offline mutation is ever lost. The queue is the
/// single source of truth for "what still needs to reach the server".
class SyncQueue {
  SyncQueue(this._db);

  final LocalDatabase _db;

  Future<void> enqueue(SyncTask task) =>
      _db.put(LocalCollections.pendingSync, task.id, task.toJson());

  Future<void> update(SyncTask task) => enqueue(task);

  Future<void> remove(String taskId) =>
      _db.delete(LocalCollections.pendingSync, taskId);

  Future<List<SyncTask>> pending() async {
    final List<Map<String, dynamic>> rows = await _db.getAll(
      LocalCollections.pendingSync,
    );
    final List<SyncTask> tasks =
        rows.map(SyncTask.fromJson).toList(growable: false)..sort(
          (SyncTask a, SyncTask b) => a.createdAt.compareTo(b.createdAt),
        );
    return tasks
        .where((SyncTask t) => t.status != SyncStatus.synced)
        .toList(growable: false);
  }

  Stream<List<SyncTask>> watchPendingTasks() => _db
      .watch(LocalCollections.pendingSync)
      .map((List<Map<String, dynamic>> rows) {
        final List<SyncTask> tasks =
            rows
                .map(SyncTask.fromJson)
                .where((SyncTask t) => t.status != SyncStatus.synced)
                .toList(growable: false)
              ..sort(
                (SyncTask a, SyncTask b) => a.createdAt.compareTo(b.createdAt),
              );
        return tasks;
      });

  Future<int> pendingCount() async => (await pending()).length;

  Stream<int> watchPendingCount() => _db
      .watch(LocalCollections.pendingSync)
      .map(
        (List<Map<String, dynamic>> rows) => rows
            .map(SyncTask.fromJson)
            .where((SyncTask t) => t.status != SyncStatus.synced)
            .length,
      );
}
