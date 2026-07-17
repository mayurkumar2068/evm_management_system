import 'package:evm_management_system/core/database/local_database.dart';

/// Local persistence for presiding-officer session data.
final class PresidingConcernLocalDatasource {
  const PresidingConcernLocalDatasource(this._db);

  static const String sessionDocId = 'active_session';

  final LocalDatabase _db;

  /// Reads the stored session document.
  Future<Map<String, dynamic>?> readSession() {
    return _db.get(LocalCollections.presidingConcern, sessionDocId);
  }

  /// Writes the session document.
  Future<void> writeSession(Map<String, dynamic> json) {
    return _db.put(LocalCollections.presidingConcern, sessionDocId, json);
  }

  /// Emits session changes.
  Stream<List<Map<String, dynamic>>> watchAll() {
    return _db.watch(LocalCollections.presidingConcern);
  }
}
