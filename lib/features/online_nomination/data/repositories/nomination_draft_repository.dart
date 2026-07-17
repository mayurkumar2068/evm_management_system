import 'package:evm_management_system/core/database/local_database.dart';
import 'package:evm_management_system/features/online_nomination/data/models/nomination_draft.dart';

/// Persists a single in-progress nomination draft on device.
final class NominationDraftRepository {
  NominationDraftRepository(this._database);

  final LocalDatabase _database;

  static const String _collection = LocalCollections.nominationDrafts;
  static const String _activeId = 'active';

  Future<NominationDraft?> loadActive() async {
    final Map<String, dynamic>? raw = await _database.get(
      _collection,
      _activeId,
    );
    return NominationDraft.fromJson(raw);
  }

  Future<void> save(NominationDraft draft) async {
    if (!draft.hasProgress) {
      await clear();
      return;
    }
    await _database.put(_collection, _activeId, draft.toJson());
  }

  Future<void> clear() async {
    await _database.delete(_collection, _activeId);
  }

  Future<bool> hasResumableDraft() async {
    final NominationDraft? draft = await loadActive();
    return draft != null && draft.hasProgress;
  }
}
