import 'package:evm_management_system/core/sync/sync_models.dart';

class ConflictResolver {
  const ConflictResolver({this.strategy = ConflictStrategy.lastWriteWins});

  final ConflictStrategy strategy;

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
