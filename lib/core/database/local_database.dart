abstract interface class LocalDatabase {
  Future<void> init();

  /// Inserts or replaces a record identified by [id] within [collection].
  Future<void> put(String collection, String id, Map<String, dynamic> value);

  /// Reads a single record, or `null` when absent.
  Future<Map<String, dynamic>?> get(String collection, String id);

  /// Reads every record in [collection].
  Future<List<Map<String, dynamic>>> getAll(String collection);

  /// Removes a single record.
  Future<void> delete(String collection, String id);

  /// Removes every record in [collection].
  Future<void> clear(String collection);

  /// Streams the full contents of [collection] on every change.
  Stream<List<Map<String, dynamic>>> watch(String collection);
}

/// Stable collection (table) names used across features.
abstract final class LocalCollections {
  static const String userSession = 'user_session';
  static const String pendingSync = 'pending_sync';
  static const String controlUnits = 'control_units';
  static const String ballotUnits = 'ballot_units';
  static const String auditLogs = 'audit_logs';
  static const String notifications = 'notifications';

  /// Angular → Flutter bridge submissions (survey, registration, …).
  static const String webSubmissions = 'web_submissions';

  /// Presiding officer election-day milestones and turnout records.
  static const String presidingConcern = 'presiding_concern';

  /// In-progress online nomination form draft.
  static const String nominationDrafts = 'nomination_drafts';
}
