import 'dart:convert';

import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:evm_management_system/core/storage/secure_storage_service.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_election_context.dart';

/// Persists presiding-officer election context from login as a single source of truth.
final class PresidingElectionContextStore {
  const PresidingElectionContextStore(this._secureStorage);

  final SecureStorageService _secureStorage;

  /// Saves [context] to secure storage.
  Future<void> save(PresidingElectionContext context) async {
    await _secureStorage.write(
      SecureStorageKeys.presidingElectionContext,
      jsonEncode(_toJson(context)),
    );
    AppLogger.d(
      'Presiding election context saved '
      '(electionId=${context.electionId}, psId=${_mask(context.psId)}, '
      'areaType=${context.areaType})',
    );
  }

  /// Reads the stored context, or `null` when absent or invalid.
  Future<PresidingElectionContext?> read() async {
    final String? raw = await _secureStorage.read(
      SecureStorageKeys.presidingElectionContext,
    );
    if (raw == null || raw.isEmpty) return null;
    try {
      final PresidingElectionContext context = _fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      return context.isComplete ? context : null;
    } catch (e, s) {
      AppLogger.w(
        'Failed to parse presiding election context',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  /// Clears stored presiding election context (e.g. on logout).
  Future<void> clear() =>
      _secureStorage.delete(SecureStorageKeys.presidingElectionContext);

  static Map<String, dynamic> _toJson(PresidingElectionContext context) {
    return <String, dynamic>{
      'election_id': context.electionId,
      'ps_id': context.psId,
      'area_type': context.areaType,
      if (context.userId != null && context.userId!.isNotEmpty)
        'user_id': context.userId,
      if (context.pollingStationCode != null)
        'polling_station_code': context.pollingStationCode,
      if (context.pollingStationName != null)
        'polling_station_name': context.pollingStationName,
    };
  }

  static PresidingElectionContext _fromJson(Map<String, dynamic> json) {
    return PresidingElectionContext(
      electionId: _parseElectionId(json['election_id'] ?? json['electionId']),
      psId: (json['ps_id'] ?? json['psId'] ?? '').toString(),
      areaType: PresidingElectionContext.normalizeAreaType(
        (json['area_type'] ?? json['areaType'])?.toString(),
      ),
      userId: (json['user_id'] ?? json['userId'])?.toString(),
      pollingStationCode:
          (json['polling_station_code'] ??
                  json['pollingStationCode'] ??
                  json['boothId'])
              ?.toString(),
      pollingStationName:
          (json['polling_station_name'] ??
                  json['pollingStationName'] ??
                  json['boothName'])
              ?.toString(),
    );
  }

  static int _parseElectionId(Object? raw) {
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static String _mask(String psId) {
    if (psId.length <= 8) return '***';
    return '${psId.substring(0, 4)}…${psId.substring(psId.length - 4)}';
  }
}
