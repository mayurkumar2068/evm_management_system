import 'package:evm_management_system/core/database/local_database.dart';
import 'package:evm_management_system/core/offline/web_form_submission.dart';

/// Persists [WebFormSubmission] records and enforces client-side de-duplication.
class WebSubmissionRepository {
  WebSubmissionRepository(this._db);

  final LocalDatabase _db;

  /// Returns `true` when [clientId] is already pending or synced locally.
  Future<bool> isDuplicate(String clientId) async {
    final Map<String, dynamic>? existing = await _db.get(
      LocalCollections.webSubmissions,
      clientId,
    );
    if (existing == null) {
      return false;
    }
    final WebFormSubmission submission = WebFormSubmission.fromJson(existing);
    return submission.status == WebSubmissionStatus.pending ||
        submission.status == WebSubmissionStatus.syncing ||
        submission.status == WebSubmissionStatus.synced;
  }

  /// Inserts or replaces a submission record.
  Future<void> save(WebFormSubmission submission) => _db.put(
    LocalCollections.webSubmissions,
    submission.clientId,
    submission.toJson(),
  );

  /// Reads every locally stored submission.
  Future<List<WebFormSubmission>> all() async {
    final List<Map<String, dynamic>> rows = await _db.getAll(
      LocalCollections.webSubmissions,
    );
    return rows.map(WebFormSubmission.fromJson).toList(growable: false);
  }

  /// Pending submissions ordered oldest-first for FIFO sync.
  Future<List<WebFormSubmission>> pending() async {
    final List<WebFormSubmission> rows = await all();
    return rows
        .where(
          (WebFormSubmission s) =>
              s.status == WebSubmissionStatus.pending ||
              s.status == WebSubmissionStatus.syncing,
        )
        .toList(growable: false)
      ..sort(
        (WebFormSubmission a, WebFormSubmission b) =>
            a.createdAt.compareTo(b.createdAt),
      );
  }

  /// Streams the count of unsynced submissions for badges.
  Stream<int> watchPendingCount() => _db
      .watch(LocalCollections.webSubmissions)
      .map(
        (List<Map<String, dynamic>> rows) => rows
            .map(WebFormSubmission.fromJson)
            .where(
              (WebFormSubmission s) =>
                  s.status == WebSubmissionStatus.pending ||
                  s.status == WebSubmissionStatus.syncing,
            )
            .length,
      );
}
