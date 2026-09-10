abstract interface class LocalDatabase {
  Future<void> init();

  Future<void> put(String collection, String id, Map<String, dynamic> value);

  Future<Map<String, dynamic>?> get(String collection, String id);

  Future<List<Map<String, dynamic>>> getAll(String collection);

  Future<void> delete(String collection, String id);

  Future<void> clear(String collection);

  Stream<List<Map<String, dynamic>>> watch(String collection);
}

abstract final class LocalCollections {
  static const String userSession = 'user_session';
  static const String pendingSync = 'pending_sync';
  static const String controlUnits = 'control_units';
  static const String ballotUnits = 'ballot_units';
  static const String auditLogs = 'audit_logs';
  static const String notifications = 'notifications';

  static const String webSubmissions = 'web_submissions';

  static const String presidingConcern = 'presiding_concern';

  static const String nominationDrafts = 'nomination_drafts';
}
