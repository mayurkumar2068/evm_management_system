import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/location/location_service.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:evm_management_system/core/network/connectivity_service.dart';
import 'package:evm_management_system/features/presiding_concern/data/models/po_election_action_result.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_action_outcome.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/presiding_concern_local_datasource.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/presiding_concern_remote_datasource.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/presiding_election_context_store.dart';
import 'package:evm_management_system/features/presiding_concern/data/constants/po_election_api_fields.dart';
import 'package:evm_management_system/features/presiding_concern/data/models/po_election_api_mapper.dart';
import 'package:evm_management_system/features/presiding_concern/data/models/po_election_status_mapper.dart';
import 'package:evm_management_system/features/presiding_concern/data/models/presiding_session_mapper.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_election_context.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';
import 'package:evm_management_system/features/presiding_concern/domain/repository/presiding_concern_repository.dart';
import 'package:evm_management_system/features/service_auth/presentation/controllers/service_auth_controller.dart';
import 'package:get/get.dart';

/// Offline-first repository for presiding-officer election-day data with PO Election API sync.
final class PresidingConcernRepositoryImpl
    implements PresidingConcernRepository {
  PresidingConcernRepositoryImpl({
    required PresidingConcernLocalDatasource local,
    required PresidingElectionContextStore contextStore,
    required ConnectivityService connectivity,
    PresidingConcernRemoteDatasource? remote,
    LocationService? locationService,
  }) : _local = local,
       _contextStore = contextStore,
       _connectivity = connectivity,
       _remote = remote,
       _locationService = locationService ?? LocationService();

  final PresidingConcernLocalDatasource _local;
  final PresidingElectionContextStore _contextStore;
  final ConnectivityService _connectivity;
  final PresidingConcernRemoteDatasource? _remote;
  final LocationService _locationService;

  @override
  Future<PresidingSession> loadSession() async {
    final PresidingElectionContext? context = await _contextStore.read();
    final Map<String, dynamic>? raw = await _local.readSession();
    if (raw == null) {
      final PresidingSession seeded = _seedSession(context);
      await _persist(seeded);
      return seeded;
    }
    final PresidingSession parsed = PresidingSessionMapper.fromJson(raw);
    final PresidingSession session = _ensureMilestoneCatalog(
      _mergeContext(parsed, context),
    );
    if (context != null &&
        (session.electionId != parsed.electionId ||
            session.psId != parsed.psId ||
            session.areaType != parsed.areaType ||
            session.pollingStationCode != parsed.pollingStationCode)) {
      await _persist(session);
    }
    return session;
  }

  @override
  Future<PresidingActionOutcome> completeMilestone(String milestoneId) async {
    final PresidingSession session = await loadSession();
    final PresidingMilestone milestone = session.milestones.firstWhere(
      (PresidingMilestone m) => m.id == milestoneId,
    );
    if (milestone.isCompleted) {
      return PresidingActionOutcome(session: session);
    }

    final PoElectionActionResult apiResult = await _syncMilestone(
      session: session,
      milestoneId: milestoneId,
    );
    final DateTime completedAt = apiResult.actionDateTime ?? DateTime.now();
    final bool synced = apiResult.accepted;

    final List<PresidingMilestone> updated = session.milestones
        .map((PresidingMilestone item) {
          if (item.id != milestoneId) return item;
          return item.copyWith(
            state: PresidingMilestoneState.completed,
            completedAt: completedAt,
            pendingSync: !synced,
          );
        })
        .toList(growable: false);

    final PresidingSession next = session.copyWith(milestones: updated);
    await _persist(next);
    return PresidingActionOutcome(
      session: next,
      alreadyRegistered: apiResult.alreadyRegistered,
      message: apiResult.message,
    );
  }

  @override
  Future<PresidingSession> saveTurnout({
    required String slotId,
    int? male,
    int? female,
    int? thirdGender,
    int? queueCount,
  }) async {
    final PresidingSession session = await loadSession();
    final TurnoutRecord? existing = session.turnoutRecords[slotId];
    if (existing?.isReadOnly ?? false) {
      return session;
    }

    final TurnoutRecord record = TurnoutRecord(
      slotId: slotId,
      male: male ?? existing?.male,
      female: female ?? existing?.female,
      thirdGender: thirdGender ?? existing?.thirdGender,
      queueCount: queueCount ?? existing?.queueCount,
      savedAt: DateTime.now(),
      pendingSync: true,
    );

    final PoElectionActionResult apiResult = await _syncTurnout(
      session: session,
      record: record,
    );
    final DateTime savedAt = apiResult.actionDateTime ?? record.savedAt!;
    final TurnoutRecord persisted = record.copyWith(
      savedAt: savedAt,
      pendingSync: !apiResult.accepted,
      isLocked: true,
    );

    final Map<String, TurnoutRecord> turnout = Map<String, TurnoutRecord>.from(
      session.turnoutRecords,
    )..[slotId] = persisted;
    final PresidingSession next = session.copyWith(turnoutRecords: turnout);
    await _persist(next);
    return next;
  }

  @override
  Future<void> syncPending() async {
    if (await _activeRemote() == null) return;

    PresidingSession session = await loadSession();
    bool changed = false;

    for (final PresidingMilestone milestone in session.milestones) {
      if (!milestone.pendingSync || !milestone.isCompleted) continue;
      final PoElectionActionResult apiResult = await _syncMilestone(
        session: session,
        milestoneId: milestone.id,
      );
      if (!apiResult.accepted) continue;
      changed = true;
      session = session.copyWith(
        milestones: session.milestones
            .map((PresidingMilestone item) {
              if (item.id != milestone.id) return item;
              return item.copyWith(pendingSync: false);
            })
            .toList(growable: false),
      );
    }

    for (final MapEntry<String, TurnoutRecord> entry
        in session.turnoutRecords.entries) {
      final TurnoutRecord record = entry.value;
      if (!record.pendingSync || record.savedAt == null) continue;
      final PoElectionActionResult apiResult = await _syncTurnout(
        session: session,
        record: record,
      );
      if (!apiResult.accepted) continue;
      changed = true;
      final Map<String, TurnoutRecord> turnout =
          Map<String, TurnoutRecord>.from(session.turnoutRecords)
            ..[entry.key] = record.copyWith(
              pendingSync: false,
              isLocked: apiResult.alreadyRegistered || apiResult.success,
            );
      session = session.copyWith(turnoutRecords: turnout);
    }

    if (changed) {
      await _persist(session);
    }
  }

  @override
  Future<PresidingSession> refreshFromServer() async {
    final PresidingConcernRemoteDatasource? remote = await _activeRemote();
    if (remote == null) return loadSession();

    final PresidingSession session = await loadSession();
    final String? userId = await _resolveUserId(session);
    if (userId == null || userId.isEmpty) {
      return session;
    }

    try {
      final Map<String, dynamic>? statusData = await remote.fetchPoStatus(
        userId: userId,
      );
      if (statusData == null || statusData.isEmpty) return session;

      final Map<String, TurnoutRecord> fromServer =
          PoElectionStatusMapper.turnoutRecordsFromStatus(statusData);
      final Map<String, TurnoutRecord> merged = Map<String, TurnoutRecord>.from(
        session.turnoutRecords,
      );

      for (final MapEntry<String, TurnoutRecord> entry in fromServer.entries) {
        final TurnoutRecord? local = merged[entry.key];
        if (local?.pendingSync == true) continue;
        merged[entry.key] = entry.value;
      }

      final List<PresidingMilestone> milestones =
          PoElectionStatusMapper.milestonesFromStatus(
            current: session.milestones,
            data: statusData,
          );

      final String? bodyType = statusData[PoElectionResponseFields.bodyType]
          ?.toString();
      final PresidingSession next = session.copyWith(
        areaType: bodyType?.isNotEmpty ?? false
            ? PresidingElectionContext.normalizeAreaType(bodyType)
            : session.areaType,
        turnoutRecords: merged,
        milestones: milestones,
      );
      await _persist(next);
      AppLogger.i(
        'PO status synced from server (${merged.length} turnout slots)',
      );
      return next;
    } catch (e, s) {
      AppLogger.w('PO status refresh failed', error: e, stackTrace: s);
      return loadSession();
    }
  }

  @override
  Future<void> applyElectionContext(PresidingElectionContext context) async {
    await _contextStore.save(context);
    final PresidingSession current = await loadSession();
    final PresidingSession next = current.copyWith(
      electionId: context.electionId,
      psId: context.psId,
      areaType: context.areaType,
      pollingStationCode:
          context.pollingStationCode ?? current.pollingStationCode,
      pollingStationName: context.pollingStationName?.isNotEmpty ?? false
          ? context.pollingStationName!
          : current.pollingStationName,
    );
    await _persist(next);
  }

  @override
  Stream<PresidingSession> watchSession() async* {
    yield await loadSession();
    await for (final List<Map<String, dynamic>> _ in _local.watchAll()) {
      yield await loadSession();
    }
  }

  PresidingSession _seedSession(PresidingElectionContext? context) {
    return PresidingSession(
      electionId: context?.electionId,
      psId: context?.psId,
      areaType: context?.areaType,
      pollingStationCode: context?.pollingStationCode ?? '',
      pollingStationName: context?.pollingStationName?.isNotEmpty ?? false
          ? context!.pollingStationName!
          : PresidingDefaults.stationNameKey,
      milestones: PresidingSessionMapper.defaultMilestones(),
      turnoutRecords: <String, TurnoutRecord>{},
    );
  }

  PresidingSession _mergeContext(
    PresidingSession session,
    PresidingElectionContext? context,
  ) {
    if (context == null) return session;
    return session.copyWith(
      electionId: session.electionId ?? context.electionId,
      psId: session.psId ?? context.psId,
      areaType: session.areaType ?? context.areaType,
      pollingStationCode: session.pollingStationCode.isNotEmpty
          ? session.pollingStationCode
          : (context.pollingStationCode ?? ''),
      pollingStationName:
          session.pollingStationName.isNotEmpty &&
              !session.pollingStationName.startsWith('presiding.')
          ? session.pollingStationName
          : (context.pollingStationName ?? session.pollingStationName),
    );
  }

  Future<PoElectionActionResult> _syncMilestone({
    required PresidingSession session,
    required String milestoneId,
  }) async {
    final PresidingConcernRemoteDatasource? remote = await _activeRemote();
    if (remote == null) {
      AppLogger.i(
        'PO Election milestone skipped ($milestoneId): '
        '${await _remoteSkipReason()}',
      );
      return const PoElectionActionResult(success: false);
    }

    final PresidingElectionContext? context = await _resolveContext(session);
    if (context == null) {
      AppLogger.w(
        'PO Election milestone skipped ($milestoneId): '
        'election context missing (need electionId + psId + areaType from login)',
      );
      return const PoElectionActionResult(success: false);
    }

    final String? endpoint = PoElectionApiMapper.milestoneEndpoint(milestoneId);
    final GeoCoordinates? coords = await _locationService
        .getCurrentCoordinates();
    final Map<String, dynamic>? body = PoElectionApiMapper.milestoneBody(
      context: context,
      milestoneId: milestoneId,
      lat: coords?.latitude,
      long: coords?.longitude,
    );
    if (endpoint == null || body == null) {
      AppLogger.d(
        'PO Election milestone local-only ($milestoneId): no API mapping',
      );
      return const PoElectionActionResult(success: true);
    }

    try {
      return await remote.postAction(endpoint: endpoint, body: body);
    } catch (e, s) {
      AppLogger.w(
        'Milestone sync failed ($milestoneId)',
        error: e,
        stackTrace: s,
      );
      return const PoElectionActionResult(success: false);
    }
  }

  Future<PoElectionActionResult> _syncTurnout({
    required PresidingSession session,
    required TurnoutRecord record,
  }) async {
    final PresidingConcernRemoteDatasource? remote = await _activeRemote();
    if (remote == null) {
      AppLogger.i(
        'PO Election turnout skipped (${record.slotId}): '
        '${await _remoteSkipReason()}',
      );
      return const PoElectionActionResult(success: false);
    }

    final PresidingElectionContext? context = await _resolveContext(session);
    if (context == null) {
      AppLogger.w(
        'PO Election turnout skipped (${record.slotId}): '
        'election context missing (need electionId + psId + areaType from login)',
      );
      return const PoElectionActionResult(success: false);
    }

    final GeoCoordinates? coords = await _locationService
        .getCurrentCoordinates();
    final String endpoint = PoElectionApiMapper.turnoutEndpoint(record.slotId);
    final Map<String, dynamic>? body = PoElectionApiMapper.turnoutBody(
      context: context,
      record: record,
      lat: coords?.latitude,
      long: coords?.longitude,
    );
    if (body == null) {
      return const PoElectionActionResult(success: true);
    }

    try {
      return await remote.postAction(endpoint: endpoint, body: body);
    } catch (e, s) {
      AppLogger.w(
        'Turnout sync failed (${record.slotId})',
        error: e,
        stackTrace: s,
      );
      return const PoElectionActionResult(success: false);
    }
  }

  Future<PresidingElectionContext?> _resolveContext(
    PresidingSession session,
  ) async {
    if (session.hasElectionContext) {
      return PresidingElectionContext(
        electionId: session.electionId!,
        psId: session.psId!,
        areaType: session.areaType!,
        pollingStationCode: session.pollingStationCode,
        pollingStationName: session.pollingStationName,
      );
    }
    return _contextStore.read();
  }

  Future<String?> _resolveUserId(PresidingSession session) async {
    final PresidingElectionContext? context = await _contextStore.read();
    final String? fromContext = context?.userId?.trim();
    if (fromContext != null && fromContext.isNotEmpty) return fromContext;

    if (Get.isRegistered<ServiceAuthController>()) {
      final String? sessionUserId =
          AppServices.serviceAuth.session.value?.userId;
      if (sessionUserId != null && sessionUserId.trim().isNotEmpty) {
        return sessionUserId.trim();
      }
    }
    return null;
  }

  PresidingSession _ensureMilestoneCatalog(PresidingSession session) {
    final bool hasMaterialReceived = session.milestones.any(
      (PresidingMilestone m) => m.id == PresidingMilestoneIds.materialReceived,
    );
    if (hasMaterialReceived) return session;

    final List<PresidingMilestone> updated = <PresidingMilestone>[];
    for (final PresidingMilestone milestone in session.milestones) {
      updated.add(milestone);
      if (milestone.id == PresidingMilestoneIds.reachedPollingStation) {
        updated.add(
          const PresidingMilestone(
            id: PresidingMilestoneIds.materialReceived,
            sectionId: PresidingSectionIds.prePoll,
            labelKey: PresidingMilestoneLabelKeys.materialReceived,
            state: PresidingMilestoneState.pending,
          ),
        );
      }
    }
    return updated.length == session.milestones.length
        ? session
        : session.copyWith(milestones: updated);
  }

  Future<PresidingConcernRemoteDatasource?> _activeRemote() async {
    if (_remote == null) return null;
    if (!await _connectivity.isOnline) return null;
    return _remote;
  }

  Future<String> _remoteSkipReason() async {
    if (_remote == null) return 'remote datasource not configured';
    if (!await _connectivity.isOnline) return 'device offline';
    return 'unknown';
  }

  Future<void> _persist(PresidingSession session) {
    return _local.writeSession(PresidingSessionMapper.toJson(session));
  }
}
