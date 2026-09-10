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

abstract final class PresidingConcernModule {
  static PresidingElectionContextBootstrap? _bootstrap;
  static PresidingConcernLocalDatasource? _local;
  static PresidingConcernRemoteDatasource? _remote;
  static PresidingConcernRepository? _repository;

  static void resetClients() {
    PoElectionApiClient.reset();
    _remote = null;
    _repository = null;
    _resetWarmSyncState();
  }

  static Future<void> clearLocalCache() async {
    _resetWarmSyncState();
    try {
      final PresidingConcernLocalDatasource local = _local ??=
          PresidingConcernLocalDatasource(AppServices.database);
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

  static bool _warmSyncDone = false;
  static bool _warmSyncInFlight = false;

  // ignore: cancel_subscriptions
  static StreamSubscription<bool>? _connectivitySub;

  static Stream<PresidingSession> watchSession() async* {
    await bootstrap.ensureContext();
    _ensureConnectivityWatcher();
    unawaited(_attemptWarmSync());
    yield* repository.watchSession();
  }

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

      _warmSyncDone = true;
    } catch (_) {
    } finally {
      _warmSyncInFlight = false;
    }
  }

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

  @visibleForTesting
  static bool offlineToOnline(bool wasOnline, bool isOnline) =>
      !wasOnline && isOnline;

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
