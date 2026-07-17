import 'package:evm_management_system/core/database/local_database.dart';
import 'package:evm_management_system/core/sync/sync_models.dart';
import 'package:evm_management_system/core/sync/sync_queue.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [LocalDatabase] fake for fast, isolated tests.
class _InMemoryDb implements LocalDatabase {
  final Map<String, Map<String, Map<String, dynamic>>> _data =
      <String, Map<String, Map<String, dynamic>>>{};

  @override
  Future<void> init() async {}

  @override
  Future<void> put(String c, String id, Map<String, dynamic> v) async {
    _data.putIfAbsent(c, () => <String, Map<String, dynamic>>{})[id] = v;
  }

  @override
  Future<Map<String, dynamic>?> get(String c, String id) async => _data[c]?[id];

  @override
  Future<List<Map<String, dynamic>>> getAll(String c) async =>
      _data[c]?.values.toList() ?? <Map<String, dynamic>>[];

  @override
  Future<void> delete(String c, String id) async => _data[c]?.remove(id);

  @override
  Future<void> clear(String c) async => _data[c]?.clear();

  @override
  Stream<List<Map<String, dynamic>>> watch(String c) =>
      Stream<List<Map<String, dynamic>>>.value(
        _data[c]?.values.toList() ?? <Map<String, dynamic>>[],
      );
}

void main() {
  late SyncQueue queue;

  setUp(() => queue = SyncQueue(_InMemoryDb()));

  SyncTask task(String id) => SyncTask(
    id: id,
    entityType: LocalCollections.controlUnits,
    entityId: 'cu-$id',
    operation: SyncOperation.create,
    payload: const <String, dynamic>{'k': 'v'},
    endpoint: '/control-units',
    createdAt: DateTime.now(),
  );

  test('enqueue then pending returns the task', () async {
    await queue.enqueue(task('1'));
    expect(await queue.pendingCount(), 1);
  });

  test('remove drops the task from pending', () async {
    await queue.enqueue(task('1'));
    await queue.remove('1');
    expect(await queue.pendingCount(), 0);
  });

  test('synced tasks are excluded from pending', () async {
    await queue.enqueue(task('1'));
    await queue.update(task('1').copyWith(status: SyncStatus.synced));
    expect(await queue.pendingCount(), 0);
  });
}
