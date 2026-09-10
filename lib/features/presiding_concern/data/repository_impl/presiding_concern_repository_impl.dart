import 'dart:convert';

import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/location/location_service.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:evm_management_system/core/network/api_endpoints.dart';
import 'package:evm_management_system/core/network/connectivity_service.dart';
import 'package:evm_management_system/core/storage/secure_storage_service.dart';
import 'package:evm_management_system/features/presiding_concern/data/models/po_election_action_result.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_action_outcome.dart';
import 'package:evm_management_system/features/presiding_concern/data/config/turnout_slot_registry.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/presiding_concern_local_datasource.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/presiding_concern_remote_datasource.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/presiding_election_context_store.dart';
import 'package:evm_management_system/features/presiding_concern/data/models/po_election_api_mapper.dart';
import 'package:evm_management_system/features/presiding_concern/data/models/po_election_status_mapper.dart';
import 'package:evm_management_system/features/presiding_concern/data/models/presiding_session_mapper.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_election_context.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';
import 'package:evm_management_system/features/presiding_concern/domain/repository/presiding_concern_repository.dart';
import 'package:evm_management_system/features/presiding_concern/domain/turnout_count_validator.dart';
import 'package:evm_management_system/features/presiding_concern/domain/turnout_live_sync.dart';

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
      PresidingSession seeded = _seedSession(context);
      final String? liveLoginName = await _liveLoginUserName();
      if ((seeded.loginUserName == null || seeded.loginUserName!.isEmpty) &&
          liveLoginName != null &&
          liveLoginName.isNotEmpty) {
        seeded = seeded.copyWith(loginUserName: liveLoginName);
      }

      if (context != null ||
          (liveLoginName != null && liveLoginName.isNotEmpty)) {
        await _persist(seeded);
      }
      return seeded;
    }
    final PresidingSession parsed = PresidingSessionMapper.fromJson(raw);
    PresidingSession session = _ensureMilestoneCatalog(
      _mergeContext(parsed, context),
    ).completeDuringPollIfPollEnded();
    final String? liveLoginName = await _liveLoginUserName();
    if ((session.loginUserName == null || session.loginUserName!.isEmpty) &&
        liveLoginName != null &&
        liveLoginName.isNotEmpty) {
      session = session.copyWith(loginUserName: liveLoginName);
    }
    if (session.electionId != parsed.electionId ||
        session.psId != parsed.psId ||
        session.areaType != parsed.areaType ||
        session.pollingStationCode != parsed.pollingStationCode ||
        session.loginUserName != parsed.loginUserName ||
        session.isLivePoll != parsed.isLivePoll ||
        session.isIpbms != parsed.isIpbms ||
        !_sameMilestoneCatalog(parsed.milestones, session.milestones) ||
        parsed.turnoutRecords[TurnoutSlotIds.livePollInfo]?.isLocked !=
            session.turnoutRecords[TurnoutSlotIds.livePollInfo]?.isLocked) {
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
    if (!session.isMilestoneActionEnabled(milestoneId)) {
      return PresidingActionOutcome(
        session: session,
        message: session.milestoneActionBlockKey(milestoneId),
      );
    }

    final PoElectionActionResult apiResult = await _syncMilestone(
      session: session,
      milestoneId: milestoneId,
    );
    final bool synced = apiResult.accepted;
    DateTime? completedAt =
        apiResult.actionDateTime ??
        (apiResult.alreadyRegistered
            ? null
            : (synced ? DateTime.now() : DateTime.now()));

    if (milestoneId == PresidingMilestoneIds.twoHourlyInfo) {
      completedAt = _latestLocalTurnoutTime(session) ?? completedAt;
    } else if (milestoneId == PresidingMilestoneIds.livePollInfo) {
      final TurnoutRecord? live =
          session.turnoutRecords[TurnoutSlotIds.livePollInfo];
      final bool hasLiveCounts =
          (live?.male ?? 0) > 0 ||
          (live?.female ?? 0) > 0 ||
          (live?.thirdGender ?? 0) > 0;
      completedAt = hasLiveCounts ? (live?.savedAt ?? completedAt) : null;
    }

    final List<PresidingMilestone> updated = session.milestones
        .map((PresidingMilestone item) {
          if (item.id != milestoneId) return item;
          if (completedAt == null &&
              (apiResult.alreadyRegistered ||
                  milestoneId == PresidingMilestoneIds.livePollInfo)) {
            return item.copyWith(
              state: PresidingMilestoneState.completed,
              clearCompletedAt: true,
              pendingSync: false,
            );
          }
          return item.copyWith(
            state: PresidingMilestoneState.completed,
            completedAt: completedAt ?? DateTime.now(),
            pendingSync: !synced,
          );
        })
        .toList(growable: false);

    Map<String, TurnoutRecord> turnout = session.turnoutRecords;
    if (milestoneId == PresidingMilestoneIds.twoHourlyInfo ||
        milestoneId == PresidingMilestoneIds.livePollInfo) {
      final TurnoutRecord? live = turnout[TurnoutSlotIds.livePollInfo];
      if (live != null && !live.isLocked) {
        turnout = Map<String, TurnoutRecord>.from(turnout)
          ..[TurnoutSlotIds.livePollInfo] = live.copyWith(isLocked: true);
      } else if (live == null) {
        turnout = Map<String, TurnoutRecord>.from(turnout)
          ..[TurnoutSlotIds.livePollInfo] = const TurnoutRecord(
            slotId: TurnoutSlotIds.livePollInfo,
            isLocked: true,
          );
      }
    }

    PresidingSession next = session.copyWith(
      milestones: updated,
      turnoutRecords: turnout,
    );
    if (milestoneId == PresidingMilestoneIds.pollEnd ||
        milestoneId == PresidingMilestoneIds.twoHourlyInfo ||
        milestoneId == PresidingMilestoneIds.livePollInfo) {
      next = next.completeDuringPollIfPollEnded();
    }
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

    final bool isQueueOnly = slotId == TurnoutSlotIds.queueCount;
    final PresidingElectionContext? electors = await _contextStore.read();
    final int resolvedMale = male ?? existing?.male ?? 0;
    final int resolvedFemale = female ?? existing?.female ?? 0;
    final int resolvedOther = thirdGender ?? existing?.thirdGender ?? 0;
    final int resolvedQueue = queueCount ?? existing?.queueCount ?? 0;

    final TurnoutCountValidationResult lastSlotGate =
        TurnoutCountValidator.validateLastSlotBeforeNextCards(
          session: session,
          slotId: slotId,
        );
    if (!lastSlotGate.isOk) {
      throw TurnoutCountValidationException(lastSlotGate);
    }

    final TurnoutCountValidationResult earlierClosed =
        TurnoutCountValidator.validateEarlierSlotNotClosed(
          session: session,
          slotId: slotId,
        );
    if (!earlierClosed.isOk) {
      throw TurnoutCountValidationException(earlierClosed);
    }

    if (isQueueOnly) {
      if (resolvedQueue < 0) {
        throw const TurnoutCountValidationException(
          TurnoutCountValidationResult.fail(
            'presiding.count_cannot_be_negative',
          ),
        );
      }
      if (resolvedQueue > TurnoutCountValidator.maxEnterableCount) {
        throw const TurnoutCountValidationException(
          TurnoutCountValidationResult.fail(
            'presiding.count_max_four_digits',
            limit: TurnoutCountValidator.maxEnterableCount,
          ),
        );
      }
    } else {
      final TurnoutCountValidationResult validation =
          TurnoutCountValidator.validate(
            male: resolvedMale,
            female: resolvedFemale,
            other: resolvedOther,
            bounds: TurnoutCountValidator.boundsFor(
              session: session,
              slotId: slotId,
              electors: electors,
            ),
          );
      if (!validation.isOk) {
        throw TurnoutCountValidationException(validation);
      }
    }

    final TurnoutCountValidationResult lastPlusQueue =
        TurnoutCountValidator.validateLastPlusQueueVsCompletion(
          session: session,
          slotId: slotId,
          male: resolvedMale,
          female: resolvedFemale,
          other: resolvedOther,
          queueCount: resolvedQueue,
        );
    if (!lastPlusQueue.isOk) {
      throw TurnoutCountValidationException(lastPlusQueue);
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
    final bool lockSlot = slotId != TurnoutSlotIds.livePollInfo;
    final TurnoutRecord persisted = record.copyWith(
      savedAt: savedAt,
      pendingSync: !apiResult.accepted,
      isLocked: lockSlot,
    );

    Map<String, TurnoutRecord> turnout = Map<String, TurnoutRecord>.from(
      session.turnoutRecords,
    )..[slotId] = persisted;
    PresidingSession next = session.copyWith(turnoutRecords: turnout);

    if (TurnoutLiveSync.mirrorsToLivePoll(slotId) && !isQueueOnly) {
      next = await _mirrorCountsToLivePoll(
        session: next,
        male: resolvedMale,
        female: resolvedFemale,
        other: resolvedOther,
        sourceSlotId: slotId,
      );
      turnout = Map<String, TurnoutRecord>.from(next.turnoutRecords);
    }

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
              isLocked: entry.key == TurnoutSlotIds.livePollInfo
                  ? record.isLocked
                  : (apiResult.alreadyRegistered || apiResult.success),
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
    final PresidingElectionContext? context = await _resolveContext(session);
    if (context == null) return session;

    try {
      final Map<String, dynamic>? status = await remote.fetchPoStatus(
        electionId: context.electionId,
        psId: context.psId,
      );
      if (status == null || status.isEmpty) return session;

      final Map<String, TurnoutRecord> serverTurnout =
          PoElectionStatusMapper.turnoutRecordsFromStatus(status);
      final Map<String, TurnoutRecord> mergedTurnout =
          Map<String, TurnoutRecord>.from(session.turnoutRecords);
      for (final TurnoutSlotConfig config
          in TurnoutSlotRegistry.genderStatusSlots()) {
        if (serverTurnout.containsKey(config.slotId)) {
          mergedTurnout[config.slotId] = serverTurnout[config.slotId]!;
        } else {
          mergedTurnout.remove(config.slotId);
        }
      }
      if (serverTurnout.containsKey(TurnoutSlotIds.queueCount)) {
        mergedTurnout[TurnoutSlotIds.queueCount] =
            serverTurnout[TurnoutSlotIds.queueCount]!;
      } else {
        mergedTurnout.remove(TurnoutSlotIds.queueCount);
      }
      final List<PresidingMilestone> mergedMilestones =
          PoElectionStatusMapper.milestonesFromStatus(
            current: session.milestones,
            data: status,
          );
      PresidingSession next = session
          .copyWith(milestones: mergedMilestones, turnoutRecords: mergedTurnout)
          .completeDuringPollIfPollEnded();
      final TurnoutRecord? live =
          next.turnoutRecords[TurnoutSlotIds.livePollInfo];
      final bool lockLive = next.milestones.any(
        (PresidingMilestone m) =>
            (m.id == PresidingMilestoneIds.twoHourlyInfo ||
                m.id == PresidingMilestoneIds.livePollInfo ||
                m.id == PresidingMilestoneIds.pollEnd) &&
            m.isCompleted,
      );
      if (live != null && lockLive && !live.isLocked) {
        next = next.copyWith(
          turnoutRecords: Map<String, TurnoutRecord>.from(next.turnoutRecords)
            ..[TurnoutSlotIds.livePollInfo] = live.copyWith(isLocked: true),
        );
      }
      await _persist(next);
      return next;
    } catch (e, s) {
      AppLogger.w('PO status refresh failed', error: e, stackTrace: s);
      return session;
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
      loginUserName: context.loginUserName ?? current.loginUserName,
      pollingStationCode:
          context.pollingStationCode ?? current.pollingStationCode,
      pollingStationName: context.pollingStationName?.isNotEmpty ?? false
          ? context.pollingStationName!
          : current.pollingStationName,
    );
    await _persist(next);
  }

  @override
  Future<void> clearLocalCache() async {
    await _local.clearSession();
    AppLogger.i('PO local session cache cleared');
  }

  @override
  Stream<PresidingSession> watchSession() async* {
    try {
      yield await loadSession();
    } catch (e, s) {
      AppLogger.w(
        'PO watchSession initial load failed',
        error: e,
        stackTrace: s,
      );
    }
    await for (final List<Map<String, dynamic>> _ in _local.watchAll()) {
      try {
        yield await loadSession();
      } catch (e, s) {
        AppLogger.w('PO watchSession reload failed', error: e, stackTrace: s);
      }
    }
  }

  Future<PresidingSession> _mirrorCountsToLivePoll({
    required PresidingSession session,
    required int male,
    required int female,
    required int other,
    required String sourceSlotId,
  }) async {
    final TurnoutRecord? existingLive =
        session.turnoutRecords[TurnoutSlotIds.livePollInfo];
    if (existingLive?.isLocked ?? false) {
      return session;
    }

    final bool forceExact = TurnoutLiveSync.forcesExactLiveCounts(sourceSlotId);

    if (!forceExact &&
        TurnoutLiveSync.liveAlreadyCoversHourly(
          live: existingLive,
          male: male,
          female: female,
          other: other,
        )) {
      AppLogger.i(
        '[LivePoll] keep live (higher/equal) | '
        'live M=${existingLive?.male ?? 0} F=${existingLive?.female ?? 0} '
        'O=${existingLive?.thirdGender ?? 0} | '
        'hourly M=$male F=$female O=$other',
      );
      return session;
    }

    final ({int male, int female, int other}) merged = forceExact
        ? (male: male, female: female, other: other)
        : TurnoutLiveSync.mergePreferringHigherLive(
            live: existingLive,
            male: male,
            female: female,
            other: other,
          );
    final TurnoutRecord liveDraft = TurnoutRecord(
      slotId: TurnoutSlotIds.livePollInfo,
      male: merged.male,
      female: merged.female,
      thirdGender: merged.other,
      savedAt: DateTime.now(),
      pendingSync: true,
      isLocked: existingLive?.isLocked ?? false,
    );

    final PoElectionActionResult apiResult = await _syncLivePollTurnout(
      session: session,
      record: liveDraft,
    );
    final DateTime savedAt = apiResult.actionDateTime ?? liveDraft.savedAt!;
    final TurnoutRecord livePersisted = liveDraft.copyWith(
      savedAt: savedAt,
      pendingSync: !apiResult.accepted,
    );

    AppLogger.i(
      forceExact
          ? '[LivePoll] auto-sync from final save | '
                'live M=${merged.male} F=${merged.female} O=${merged.other} | '
                'accepted=${apiResult.accepted}'
          : '[LivePoll] auto-sync from hourly save | '
                'live M=${merged.male} F=${merged.female} O=${merged.other} | '
                'hourly M=$male F=$female O=$other | '
                'accepted=${apiResult.accepted}',
    );

    final Map<String, TurnoutRecord> turnout = Map<String, TurnoutRecord>.from(
      session.turnoutRecords,
    )..[TurnoutSlotIds.livePollInfo] = livePersisted;
    return session.copyWith(turnoutRecords: turnout);
  }

  Future<PoElectionActionResult> _syncLivePollTurnout({
    required PresidingSession session,
    required TurnoutRecord record,
  }) async {
    final PresidingConcernRemoteDatasource? remote = await _activeRemote();
    if (remote == null) {
      return const PoElectionActionResult(success: false);
    }

    final PresidingElectionContext? context = await _resolveContext(session);
    if (context == null) {
      return const PoElectionActionResult(success: false);
    }

    final GeoCoordinates? coords = await _locationService
        .getCurrentCoordinates();
    final Map<String, dynamic> body = PoElectionApiMapper.livePollBody(
      context: context,
      record: record,
      lat: coords?.latitude,
      long: coords?.longitude,
    );

    try {
      return await remote.postAction(
        endpoint: PoElectionEndpoints.savePollLive,
        body: body,
      );
    } catch (e, s) {
      AppLogger.w('Live poll auto-sync failed', error: e, stackTrace: s);
      return const PoElectionActionResult(success: false);
    }
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

  Future<String?> _liveLoginUserName() async {
    try {
      final String? raw = await AppServices.secureStorage.read(
        SecureStorageKeys.serviceSession,
      );
      if (raw == null || raw.isEmpty) return null;
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final String name = (decoded['name'] ?? '').toString().trim();
      return name.isEmpty ? null : name;
    } catch (_) {
      return null;
    }
  }

  PresidingSession _seedSession(PresidingElectionContext? context) {
    return PresidingSession(
      electionId: context?.electionId,
      psId: context?.psId,
      areaType: context?.areaType,
      loginUserName: context?.loginUserName,
      isLivePoll: context?.isLivePoll ?? false,
      isIpbms: context?.isIpbms ?? false,
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
    final String? contextArea = context.areaType.isNotEmpty
        ? context.areaType
        : null;
    return session.copyWith(
      electionId: context.electionId > 0
          ? context.electionId
          : session.electionId,
      psId: context.psId.isNotEmpty ? context.psId : session.psId,
      areaType: contextArea ?? session.areaType,
      pollingStationCode: context.pollingStationCode?.isNotEmpty ?? false
          ? context.pollingStationCode!
          : session.pollingStationCode,
      pollingStationName: context.pollingStationName?.isNotEmpty ?? false
          ? context.pollingStationName!
          : session.pollingStationName,
      loginUserName: context.loginUserName?.isNotEmpty ?? false
          ? context.loginUserName
          : session.loginUserName,
      isLivePoll: context.isLivePoll,
      isIpbms: context.isIpbms,
    );
  }

  Future<PresidingElectionContext?> _resolveContext(
    PresidingSession session,
  ) async {
    final PresidingElectionContext? stored = await _contextStore.read();
    if (session.hasElectionContext) {
      return PresidingElectionContext(
        electionId: session.electionId!,
        psId: session.psId!,
        areaType: session.areaType!,
        pollingStationCode: session.pollingStationCode,
        pollingStationName: session.pollingStationName,
        userId: stored?.userId,
        boothLat: stored?.boothLat,
        boothLong: stored?.boothLong,
        maleElectors: stored?.maleElectors,
        femaleElectors: stored?.femaleElectors,
        otherElectors: stored?.otherElectors,
        totalElectors: stored?.totalElectors,
      );
    }
    return stored;
  }

  PresidingSession _ensureMilestoneCatalog(PresidingSession session) {
    final List<PresidingMilestone> catalog =
        PresidingSessionMapper.defaultMilestones();
    final Map<String, PresidingMilestone> byId = <String, PresidingMilestone>{
      for (final PresidingMilestone m in session.milestones) m.id: m,
    };

    final List<PresidingMilestone> ordered = <PresidingMilestone>[
      for (final PresidingMilestone def in catalog)
        PresidingMilestone(
          id: def.id,
          sectionId: def.sectionId,
          labelKey: def.labelKey,
          state: byId[def.id]?.state ?? def.state,
          completedAt: byId[def.id]?.completedAt,
          opensTurnout: def.opensTurnout,
          pendingSync: byId[def.id]?.pendingSync ?? false,
        ),
    ];

    if (_sameMilestoneCatalog(session.milestones, ordered)) {
      return session;
    }
    return session.copyWith(milestones: ordered);
  }

  bool _sameMilestoneCatalog(
    List<PresidingMilestone> a,
    List<PresidingMilestone> b,
  ) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].sectionId != b[i].sectionId ||
          a[i].state != b[i].state ||
          a[i].completedAt != b[i].completedAt ||
          a[i].pendingSync != b[i].pendingSync ||
          a[i].opensTurnout != b[i].opensTurnout) {
        return false;
      }
    }
    return true;
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

  DateTime? _latestLocalTurnoutTime(PresidingSession session) {
    DateTime? latest;
    for (final MapEntry<String, TurnoutRecord> entry
        in session.turnoutRecords.entries) {
      if (entry.key == TurnoutSlotIds.livePollInfo) continue;
      final DateTime? savedAt = entry.value.savedAt;
      if (savedAt == null) continue;
      if (latest == null || savedAt.isAfter(latest)) {
        latest = savedAt;
      }
    }
    return latest;
  }
}
