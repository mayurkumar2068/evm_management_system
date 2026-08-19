import 'dart:async';

import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/network/connectivity_service.dart';
import 'package:evm_management_system/core/network/po_election_api_client.dart';
import 'package:evm_management_system/core/network/po_election_auth.dart';
import 'package:evm_management_system/features/auth/di/auth_module.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/presiding_concern_local_datasource.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/presiding_concern_remote_datasource.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/presiding_election_context_bootstrap.dart';
import 'package:evm_management_system/features/presiding_concern/data/repository_impl/presiding_concern_repository_impl.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_action_outcome.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';
import 'package:evm_management_system/features/presiding_concern/domain/repository/presiding_concern_repository.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/controllers/presiding_party_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Trans;

/// Lazily wires presiding concern dependencies via GetX.
abstract final class PresidingConcernModule {
  static PresidingElectionContextBootstrap? _bootstrap;
  static PresidingConcernLocalDatasource? _local;
  static PresidingConcernRemoteDatasource? _remote;
  static PresidingConcernRepository? _repository;

  /// Clears cached network clients so the next call uses a fresh auth token.
  static void resetClients() {
    PoElectionApiClient.reset();
    _remote = null;
    _repository = null;
    _resetWarmSyncState();
  }

  /// Wipes PO local DB cache (logout / re-login). Does not delete GetX
  /// controllers — those are permanent and deleting them causes a white screen.
  static Future<void> clearLocalCache() async {
    _resetWarmSyncState();
    try {
      final PresidingConcernLocalDatasource local =
          _local ??= PresidingConcernLocalDatasource(AppServices.database);
      await local.clearSession();
    } catch (_) {}
    resetClients();
  }

  static PresidingElectionContextBootstrap get bootstrap =>
      _bootstrap ??= PresidingElectionContextBootstrap(
        authLocal: AuthModule.localDataSource,
        contextStore: AuthModule.presidingContextStore,
        config: AppServices.config,
      );

  static PresidingConcernRepository get repository =>
      _repository ??= PresidingConcernRepositoryImpl(
        local: _local ??= PresidingConcernLocalDatasource(AppServices.database),
        contextStore: AuthModule.presidingContextStore,
        connectivity: AppServices.connectivity,
        remote: _remote ??= PresidingConcernRemoteDatasourceImpl(
          config: AppServices.config,
          getAccessToken: PoElectionAuth.accessToken,
        ),
      );

  // True only once a warm sync has genuinely completed (pending actions
  // pushed + latest PO status pulled). Never set optimistically — a failed
  // or skipped (offline) attempt must be retried, not treated as done.
  static bool _warmSyncDone = false;
  static bool _warmSyncInFlight = false;
  // Lives for the app process, like the static clients above — never cancelled.
  // ignore: cancel_subscriptions
  static StreamSubscription<bool>? _connectivitySub;

  /// Local session stream. Warm-syncs pending actions + latest PO status.
  static Stream<PresidingSession> watchSession() async* {
    await bootstrap.ensureContext();
    _ensureConnectivityWatcher();
    unawaited(_attemptWarmSync());
    yield* repository.watchSession();
  }

  /// Runs the warm sync when it hasn't succeeded yet and isn't already
  /// running. Safe to call repeatedly (screen revisits, reconnects) — it's a
  /// no-op once a sync has actually gone through.
  static Future<void> _attemptWarmSync() async {
    if (_warmSyncDone || _warmSyncInFlight) return;
    _warmSyncInFlight = true;
    try {
      if (!await AppServices.connectivity.isOnline) return;
      await repository.syncPending();
      if (Get.isRegistered<PresidingPartyController>()) {
        await Get.find<PresidingPartyController>().syncPending();
      }
      await repository.refreshFromServer();
      // Only reached when every step above succeeded.
      _warmSyncDone = true;
    } catch (_) {
      // Leave _warmSyncDone false — the next watchSession() call or the
      // connectivity watcher below will retry automatically.
    } finally {
      _warmSyncInFlight = false;
    }
  }

  /// Auto-retries the warm sync the moment connectivity returns, so a PO who
  /// re-logs in without a network yet still gets API data as soon as they're
  /// back online — without needing to leave/reopen the dashboard.
  static void _ensureConnectivityWatcher() {
    if (_connectivitySub != null) return;
    _connectivitySub = AppServices.connectivity.onStatusChange.listen((
      bool online,
    ) {
      if (online && !_warmSyncDone) {
        unawaited(_attemptWarmSync());
      }
    });
  }

  static void _resetWarmSyncState() {
    _warmSyncDone = false;
    _warmSyncInFlight = false;
  }
}

/// Coordinates milestone actions for the presiding-officer dashboard.
final class PresidingDashboardController extends GetxController {
  PresidingConcernRepository get _repository =>
      PresidingConcernModule.repository;

  final RxBool isOnline = true.obs;
  final RxBool isSyncing = false.obs;

  StreamSubscription<bool>? _connectivitySub;
  bool _wasOnline = true;

  @override
  void onInit() {
    super.onInit();
    unawaited(_bindConnectivity());
    // First paint uses watchSession warm sync (API-first). Manual / reconnect use syncNow.
  }

  @override
  void onClose() {
    _connectivitySub?.cancel();
    super.onClose();
  }

  Future<void> _bindConnectivity() async {
    final ConnectivityService connectivity = AppServices.connectivity;
    final bool online = await connectivity.isOnline;
    _wasOnline = online;
    isOnline.value = online;
    _connectivitySub = connectivity.onStatusChange.listen((bool online) {
      final bool cameOnline = offlineToOnline(_wasOnline, online);
      _wasOnline = online;
      isOnline.value = online;
      if (cameOnline) {
        unawaited(syncNow());
      }
    });
  }

  /// True when connectivity flips from offline → online.
  @visibleForTesting
  static bool offlineToOnline(bool wasOnline, bool isOnline) =>
      !wasOnline && isOnline;

  /// Uploads pending local actions and then refreshes latest PO status.
  Future<bool> syncNow() async {
    if (isSyncing.value) return false;
    isSyncing.value = true;
    try {
      final bool online = await AppServices.connectivity.isOnline;
      isOnline.value = online;
      if (!online) return false;
      await PresidingConcernModule.bootstrap.ensureContext();
      await _repository.syncPending();
      if (Get.isRegistered<PresidingPartyController>()) {
        await Get.find<PresidingPartyController>().syncPending();
      }
      await _repository.refreshFromServer();
      return true;
    } catch (_) {
      return false;
    } finally {
      isSyncing.value = false;
    }
  }

  Future<PresidingActionOutcome> completeMilestone(String milestoneId) async {
    await PresidingConcernModule.bootstrap.ensureContext();
    return _repository.completeMilestone(milestoneId);
  }
}

/// Coordinates turnout slot persistence.
final class PresidingTurnoutController extends GetxController {
  PresidingConcernRepository get _repository =>
      PresidingConcernModule.repository;

  Future<PresidingSession> saveTurnout({
    required String slotId,
    int? male,
    int? female,
    int? thirdGender,
    int? queueCount,
  }) async {
    await PresidingConcernModule.bootstrap.ensureContext();
    return _repository.saveTurnout(
      slotId: slotId,
      male: male,
      female: female,
      thirdGender: thirdGender,
      queueCount: queueCount,
    );
  }
}
