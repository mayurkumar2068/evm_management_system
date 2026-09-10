import 'package:evm_management_system/core/database/local_database.dart';

final class PresidingConcernLocalDatasource {
  const PresidingConcernLocalDatasource(this._db);

  static const String sessionDocId = 'active_session';

  final LocalDatabase _db;

  Future<Map<String, dynamic>?> readSession() {
    return _db.get(LocalCollections.presidingConcern, sessionDocId);
  }

  Future<void> writeSession(Map<String, dynamic> json) {
    return _db.put(LocalCollections.presidingConcern, sessionDocId, json);
  }

  Future<void> clearSession() {
    return _db.delete(LocalCollections.presidingConcern, sessionDocId);
  }

  Stream<List<Map<String, dynamic>>> watchAll() {
    return _db.watch(LocalCollections.presidingConcern);
  }
}
