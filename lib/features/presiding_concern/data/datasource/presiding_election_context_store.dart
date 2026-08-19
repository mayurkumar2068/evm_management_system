import 'dart:convert';

import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:evm_management_system/core/storage/secure_storage_service.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_election_context.dart';
import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';

/// Persists presiding-officer election context from login as a single source of truth.
final class PresidingElectionContextStore {
  const PresidingElectionContextStore(this._secureStorage);

  final SecureStorageService _secureStorage;

  /// In-memory copy so the PO header can render on Android without waiting
  /// on Keystore / EncryptedSharedPreferences (and without FutureBuilder reset).
  static PresidingElectionContext? memoryCache;

  /// Keeps elector counts from [fallback] when [primary] lacks them.
  static PresidingElectionContext mergePreservingElectors(
    PresidingElectionContext primary,
    PresidingElectionContext? fallback,
  ) {
    if (primary.hasElectorCounts || fallback == null || !fallback.hasElectorCounts) {
      return primary;
    }
    return primary.copyWith(
      maleElectors: fallback.maleElectors,
      femaleElectors: fallback.femaleElectors,
      otherElectors: fallback.otherElectors,
      totalElectors: fallback.totalElectors,
    );
  }

  /// Prefers whichever context carries elector counts (Release cold-start safe).
  static PresidingElectionContext? preferWithElectors(
    PresidingElectionContext? a,
    PresidingElectionContext? b,
  ) {
    if (a == null) return b;
    if (b == null) return a;
    if (a.hasElectorCounts) return a;
    if (b.hasElectorCounts) return mergePreservingElectors(a, b);
    return a.isComplete ? a : b;
  }

  /// Fills login identity / booth fields from [fallback] when [primary] lacks them.
  static PresidingElectionContext mergePreservingIdentity(
    PresidingElectionContext primary,
    PresidingElectionContext? fallback,
  ) {
    if (fallback == null) return primary;
    final String primaryArea = PresidingElectionContext.normalizeAreaType(
      primary.areaType,
    );
    final String fallbackArea = PresidingElectionContext.normalizeAreaType(
      fallback.areaType,
    );
    return primary.copyWith(
      userId: _nonEmpty(primary.userId) ?? fallback.userId,
      loginUserName: _nonEmpty(primary.loginUserName) ?? fallback.loginUserName,
      electionId: primary.electionId > 0 ? primary.electionId : fallback.electionId,
      psId: _nonEmpty(primary.psId) ?? fallback.psId,
      areaType: primaryArea.isNotEmpty ? primaryArea : fallbackArea,
      pollingStationCode:
          _nonEmpty(primary.pollingStationCode) ?? fallback.pollingStationCode,
      pollingStationName:
          _nonEmpty(primary.pollingStationName) ?? fallback.pollingStationName,
      boothLat: primary.boothLat ?? fallback.boothLat,
      boothLong: primary.boothLong ?? fallback.boothLong,
    );
  }

  /// Android fallback: PO service session also stores login elector totals.
  static void warmFromServiceSession(ServiceSession session) {
    if (session.kind != ServiceLoginKind.presiding || !session.hasElectorCounts) {
      return;
    }
    final PresidingElectionContext fromSession = PresidingElectionContext(
      electionId: 0,
      psId: '',
      areaType: PresidingElectionContext.normalizeAreaType(session.section),
      userId: session.userId,
      loginUserName: session.name,
      maleElectors: session.maleElectors,
      femaleElectors: session.femaleElectors,
      otherElectors: session.otherElectors,
      totalElectors: session.totalElectors,
    );
    final PresidingElectionContext merged = mergePreservingIdentity(
      preferWithElectors(memoryCache, fromSession) ?? fromSession,
      memoryCache,
    );
    memoryCache = merged;
  }

  /// Saves [context] to secure storage.
  Future<void> save(PresidingElectionContext context) async {
    PresidingElectionContext toSave = mergePreservingElectors(
      context,
      memoryCache,
    );
    if (!toSave.hasElectorCounts) {
      toSave = mergePreservingElectors(toSave, await _readFromDisk());
    }
    memoryCache = toSave;
    await _secureStorage.write(
      SecureStorageKeys.presidingElectionContext,
      jsonEncode(_toJson(toSave)),
    );
    AppLogger.d(
      'Presiding election context saved '
      '(electionId=${toSave.electionId}, psId=${_mask(toSave.psId)}, '
      'areaType=${toSave.areaType}, electors=${toSave.hasElectorCounts})',
    );
  }

  /// Reads the stored context, or `null` when absent or invalid.
  Future<PresidingElectionContext?> read() async {
    PresidingElectionContext? fromDisk;
    try {
      fromDisk = await _readFromDisk();
    } catch (e, s) {
      AppLogger.w(
        'Failed to parse presiding election context',
        error: e,
        stackTrace: s,
      );
    }

    if (memoryCache != null) {
      final PresidingElectionContext merged = mergePreservingIdentity(
        mergePreservingElectors(memoryCache!, fromDisk),
        fromDisk,
      );
      memoryCache = merged;
      return merged;
    }
    if (fromDisk != null) {
      memoryCache = fromDisk;
    }
    return fromDisk;
  }

  Future<PresidingElectionContext?> _readFromDisk() async {
    final String? raw = await _secureStorage.read(
      SecureStorageKeys.presidingElectionContext,
    );
    if (raw == null || raw.isEmpty) return null;
    return _fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Clears stored presiding election context (e.g. on logout).
  Future<void> clear() {
    memoryCache = null;
    return _secureStorage.delete(SecureStorageKeys.presidingElectionContext);
  }

  static Map<String, dynamic> _toJson(PresidingElectionContext context) {
    return <String, dynamic>{
      'election_id': context.electionId,
      'ps_id': context.psId,
      'area_type': context.areaType,
      if (context.userId != null && context.userId!.isNotEmpty)
        'user_id': context.userId,
      if (context.loginUserName != null && context.loginUserName!.isNotEmpty)
        'login_user_name': context.loginUserName,
      if (context.pollingStationCode != null)
        'polling_station_code': context.pollingStationCode,
      if (context.pollingStationName != null)
        'polling_station_name': context.pollingStationName,
      if (context.boothLat != null) 'booth_lat': context.boothLat,
      if (context.boothLong != null) 'booth_long': context.boothLong,
      if (context.maleElectors != null) 'male_electors': context.maleElectors,
      if (context.femaleElectors != null)
        'female_electors': context.femaleElectors,
      if (context.otherElectors != null)
        'other_electors': context.otherElectors,
      if (context.totalElectors != null)
        'total_electors': context.totalElectors,
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
      loginUserName:
          (json['login_user_name'] ?? json['loginUserName'])?.toString(),
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
      boothLat: _parseCoord(json['booth_lat'] ?? json['boothLat']),
      boothLong: _parseCoord(json['booth_long'] ?? json['boothLong']),
      maleElectors: _parseElectors(
        _electorField(json, const <String>[
          'male_electors',
          'maleElectors',
          'MaleElectors',
        ]),
      ),
      femaleElectors: _parseElectors(
        _electorField(json, const <String>[
          'female_electors',
          'femaleElectors',
          'FemaleElectors',
        ]),
      ),
      otherElectors: _parseElectors(
        _electorField(json, const <String>[
          'other_electors',
          'otherElectors',
          'OtherElectors',
        ]),
      ),
      totalElectors: _parseElectors(
        _electorField(json, const <String>[
          'total_electors',
          'totalElectors',
          'TotalElectors',
        ]),
      ),
    );
  }

  static double? _parseCoord(Object? raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString().trim());
  }

  static Object? _electorField(Map<String, dynamic> json, List<String> keys) {
    for (final String key in keys) {
      if (json.containsKey(key) && json[key] != null) return json[key];
    }
    for (final MapEntry<String, dynamic> entry in json.entries) {
      final String lower = entry.key.toLowerCase();
      for (final String key in keys) {
        if (lower == key.toLowerCase() && entry.value != null) {
          return entry.value;
        }
      }
    }
    return null;
  }

  static int? _parseElectors(Object? raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString().trim());
  }

  static int _parseElectionId(Object? raw) {
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static String _mask(String psId) {
    if (psId.length <= 8) return '***';
    return '${psId.substring(0, 4)}…${psId.substring(psId.length - 4)}';
  }

  static String? _nonEmpty(String? value) {
    final String trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
