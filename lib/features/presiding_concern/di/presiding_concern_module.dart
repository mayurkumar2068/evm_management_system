import 'package:evm_management_system/core/di/app_services.dart';
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

  static Stream<PresidingSession> watchSession() async* {
    await bootstrap.ensureContext();
    await repository.refreshFromServer();
    await repository.syncPending();
    yield* repository.watchSession();
  }
}

/// Coordinates milestone actions for the presiding-officer dashboard.
final class PresidingDashboardController extends GetxController {
  PresidingConcernRepository get _repository =>
      PresidingConcernModule.repository;

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
