import 'dart:async';

import 'package:evm_management_system/core/database/local_database.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:evm_management_system/core/network/connectivity_service.dart';
import 'package:evm_management_system/core/sync/conflict_resolver.dart';
import 'package:evm_management_system/core/sync/retry_policy.dart';
import 'package:evm_management_system/core/sync/sync_models.dart';
import 'package:evm_management_system/core/sync/sync_queue.dart';
import 'package:evm_management_system/core/sync/sync_service.dart';

/// Orchestrates the offline-first sync lifecycle.
///
/// Flow per the architecture spec:
/// `save local -> mark pending -> background sync -> server success -> update local`.
/// Triggered by connectivity changes and a periodic interval; serializes work
/// so only one drain runs at a time. Conflicts are reconciled by
/// [ConflictResolver]; transient failures back off via [RetryPolicy].
class SyncManager {
  SyncManager({
    required SyncQueue queue,
    required SyncService service,
    required ConnectivityService connectivity,
    required LocalDatabase db,
    required RetryPolicy retryPolicy,
    required Duration interval,
    void Function(SyncTask task)? onTaskConfirmed,
    ConflictResolver conflictResolver = const ConflictResolver(),
  }) : _queue = queue,
       _service = service,
       _connectivity = connectivity,
       _db = db,
       _retryPolicy = retryPolicy,
       _interval = interval,
       _onTaskConfirmed = onTaskConfirmed,
       _conflictResolver = conflictResolver;

  final SyncQueue _queue;
  final SyncService _service;
  final ConnectivityService _connectivity;
  final LocalDatabase _db;
  final RetryPolicy _retryPolicy;
  final ConflictResolver _conflictResolver;
  final Duration _interval;
  final void Function(SyncTask task)? _onTaskConfirmed;

  StreamSubscription<bool>? _connectivitySub;
  Timer? _timer;
  bool _draining = false;

  /// Persists a mutation locally and queues it for background sync.
  ///
  /// The optimistic local write is keyed off [SyncTask.entityType] — the very
  /// same collection [_process] writes the server-confirmed record back to —
  /// so the pending and confirmed copies can never land in different
  /// collections.
  Future<void> submit(SyncTask task) async {
    await _db.put(task.entityType, task.entityId, task.payload);
    await _queue.enqueue(task);
    unawaited(sync());
  }

  /// Begins watching connectivity and scheduling periodic drains.
  void start() {
    _connectivitySub = _connectivity.onStatusChange.listen((bool online) {
      if (online) unawaited(sync());
    });
    _timer = Timer.periodic(_interval, (_) => unawaited(sync()));
  }

  /// Drains the queue once. Safe to call concurrently — extra calls no-op.
  Future<void> sync() async {
    if (_draining) return;
    if (!await _connectivity.isOnline) return;
    _draining = true;
    try {
      for (final SyncTask task in await _queue.pending()) {
        await _process(task);
      }
    } catch (e, s) {
      AppLogger.e('Sync drain failed', error: e, stackTrace: s);
    } finally {
      _draining = false;
    }
  }

  Future<void> _process(SyncTask task) async {
    final SyncTask inProgressTask = task.copyWith(
      status: SyncStatus.inProgress,
    );
    await _queue.update(inProgressTask);

    final SyncOutcome outcome = await _service.push(task);

    switch (outcome) {
      case SyncSucceeded(:final serverData):
        if (serverData != null) {
          await _db.put(task.entityType, task.entityId, serverData);
        }
        await _queue.remove(task.id);
        _onTaskConfirmed?.call(task);

      case SyncConflict(:final serverData):
        final Map<String, dynamic>? winner = _conflictResolver.resolve(
          local: task.payload,
          server: serverData,
        );
        if (winner == null) {
          await _queue.update(task.copyWith(status: SyncStatus.conflict));
        } else {
          await _db.put(task.entityType, task.entityId, winner);
          await _queue.remove(task.id);
          _onTaskConfirmed?.call(task);
        }

      case SyncRetryable(:final reason):
        final int attempts = task.attempts + 1;
        if (_retryPolicy.shouldRetry(attempts)) {
          await _queue.update(
            task.copyWith(
              status: SyncStatus.pending,
              attempts: attempts,
              lastError: reason,
            ),
          );
        } else {
          await _queue.update(
            task.copyWith(
              status: SyncStatus.failed,
              attempts: attempts,
              lastError: reason,
            ),
          );
        }

      case SyncFatal(:final reason):
        await _queue.update(
          task.copyWith(status: SyncStatus.failed, lastError: reason),
        );
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
    _timer?.cancel();
  }
}
