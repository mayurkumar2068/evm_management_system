import 'package:evm_management_system/core/sync/sync_models.dart';

/// Reconciles a local [SyncTask] payload with the server's version.
///
/// Strategy is configurable per task type. `lastWriteWins` compares the
/// `updatedAt` timestamps; `manual` surfaces the conflict to an operator.
class ConflictResolver {
  const ConflictResolver({this.strategy = ConflictStrategy.lastWriteWins});

  final ConflictStrategy strategy;

  /// Returns the winning record, or `null` when manual resolution is required.
  Map<String, dynamic>? resolve({
    required Map<String, dynamic> local,
    required Map<String, dynamic> server,
  }) {
    switch (strategy) {
      case ConflictStrategy.serverWins:
        return server;
      case ConflictStrategy.clientWins:
        return local;
      case ConflictStrategy.manual:
        return null;
      case ConflictStrategy.lastWriteWins:
        final DateTime? localTs = _timestamp(local);
        final DateTime? serverTs = _timestamp(server);
        if (localTs == null) return server;
        if (serverTs == null) return local;
        return localTs.isAfter(serverTs) ? local : server;
    }
  }

  DateTime? _timestamp(Map<String, dynamic> record) {
    final Object? raw = record['updatedAt'] ?? record['modifiedAt'];
    return raw is String ? DateTime.tryParse(raw) : null;
  }
}
