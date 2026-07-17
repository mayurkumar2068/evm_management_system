/// The mutation represented by a queued sync task.
enum SyncOperation { create, update, delete }

/// Lifecycle state of a queued task.
enum SyncStatus { pending, inProgress, failed, synced, conflict }

/// Strategy applied when local and server versions diverge.
enum ConflictStrategy { lastWriteWins, serverWins, clientWins, manual }

/// A single durable unit of work in the offline-first sync queue.
///
/// Persisted locally the moment a user mutates data; the [SyncManager] later
/// replays it against the server and reconciles the response.
class SyncTask {
  const SyncTask({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.endpoint,
    required this.createdAt,
    this.status = SyncStatus.pending,
    this.attempts = 0,
    this.version = 0,
    this.lastError,
  });

  factory SyncTask.fromJson(Map<String, dynamic> json) => SyncTask(
    id: json['id'] as String,
    entityType: json['entityType'] as String,
    entityId: json['entityId'] as String,
    operation: SyncOperation.values.byName(json['operation'] as String),
    payload: (json['payload'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    endpoint: json['endpoint'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    status: SyncStatus.values.byName(json['status'] as String),
    attempts: json['attempts'] as int? ?? 0,
    version: json['version'] as int? ?? 0,
    lastError: json['lastError'] as String?,
  );

  final String id;
  final String entityType;
  final String entityId;
  final SyncOperation operation;
  final Map<String, dynamic> payload;
  final String endpoint;
  final DateTime createdAt;
  final SyncStatus status;
  final int attempts;
  final int version;
  final String? lastError;

  SyncTask copyWith({
    SyncStatus? status,
    int? attempts,
    int? version,
    String? lastError,
  }) => SyncTask(
    id: id,
    entityType: entityType,
    entityId: entityId,
    operation: operation,
    payload: payload,
    endpoint: endpoint,
    createdAt: createdAt,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    version: version ?? this.version,
    lastError: lastError ?? this.lastError,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'entityType': entityType,
    'entityId': entityId,
    'operation': operation.name,
    'payload': payload,
    'endpoint': endpoint,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'attempts': attempts,
    'version': version,
    'lastError': lastError,
  };
}
