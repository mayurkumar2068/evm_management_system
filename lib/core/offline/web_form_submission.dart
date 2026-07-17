/// A durable web-form payload queued for upload by [OfflineSyncService].
///
/// Angular never persists this — Flutter is the single source of truth for
/// offline storage. [clientId] prevents duplicate enqueue/sync.
class WebFormSubmission {
  const WebFormSubmission({
    required this.clientId,
    required this.formType,
    required this.endpoint,
    required this.payload,
    required this.authToken,
    required this.createdAt,
    this.status = WebSubmissionStatus.pending,
    this.attempts = 0,
    this.lastError,
    this.referenceId,
    this.syncedAt,
  });

  factory WebFormSubmission.fromJson(Map<String, dynamic> json) =>
      WebFormSubmission(
        clientId: json['clientId'] as String,
        formType: json['formType'] as String,
        endpoint: json['endpoint'] as String,
        payload:
            (json['payload'] as Map<String, dynamic>?) ?? <String, dynamic>{},
        authToken: json['authToken'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        status: WebSubmissionStatus.values.byName(
          json['status'] as String? ?? WebSubmissionStatus.pending.name,
        ),
        attempts: json['attempts'] as int? ?? 0,
        lastError: json['lastError'] as String?,
        referenceId: json['referenceId'] as String?,
        syncedAt: json['syncedAt'] != null
            ? DateTime.tryParse(json['syncedAt'] as String)
            : null,
      );

  final String clientId;
  final String formType;
  final String endpoint;
  final Map<String, dynamic> payload;
  final String authToken;
  final DateTime createdAt;
  final WebSubmissionStatus status;
  final int attempts;
  final String? lastError;
  final String? referenceId;
  final DateTime? syncedAt;

  WebFormSubmission copyWith({
    WebSubmissionStatus? status,
    int? attempts,
    String? lastError,
    String? referenceId,
    DateTime? syncedAt,
  }) => WebFormSubmission(
    clientId: clientId,
    formType: formType,
    endpoint: endpoint,
    payload: payload,
    authToken: authToken,
    createdAt: createdAt,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    lastError: lastError ?? this.lastError,
    referenceId: referenceId ?? this.referenceId,
    syncedAt: syncedAt ?? this.syncedAt,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'clientId': clientId,
    'formType': formType,
    'endpoint': endpoint,
    'payload': payload,
    'authToken': authToken,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'attempts': attempts,
    'lastError': lastError,
    'referenceId': referenceId,
    'syncedAt': syncedAt?.toIso8601String(),
  };
}

/// Lifecycle of a locally stored web submission.
enum WebSubmissionStatus { pending, syncing, synced, failed }

/// Response returned to Angular after every bridge submit.
class WebFormSubmitResult {
  const WebFormSubmitResult({
    required this.success,
    required this.mode,
    this.clientId,
    this.referenceId,
    this.message,
    this.error,
  });

  final bool success;
  final String mode;
  final String? clientId;
  final String? referenceId;
  final String? message;
  final String? error;

  Map<String, dynamic> toBridgeMap() => <String, dynamic>{
    'ok': success,
    'success': success,
    'mode': mode,
    if (clientId != null) 'clientId': clientId,
    if (referenceId != null) 'referenceId': referenceId,
    if (message != null) 'message': message,
    if (error != null) 'error': error,
  };
}
