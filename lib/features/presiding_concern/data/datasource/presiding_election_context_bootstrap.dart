import 'package:evm_management_system/config/environment_config.dart';
import 'package:evm_management_system/config/flavor.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:evm_management_system/features/auth/data/datasource/auth_local_datasource.dart';
import 'package:evm_management_system/features/auth/data/models/user_model.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/presiding_election_context_store.dart';
import 'package:evm_management_system/features/presiding_concern/data/models/presiding_election_context_factory.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_election_context.dart';

/// Ensures [PresidingElectionContext] exists before PO Election API calls.
final class PresidingElectionContextBootstrap {
  const PresidingElectionContextBootstrap({
    required AuthLocalDataSource authLocal,
    required PresidingElectionContextStore contextStore,
    required EnvironmentConfig config,
  }) : _authLocal = authLocal,
       _contextStore = contextStore,
       _config = config;

  final AuthLocalDataSource _authLocal;
  final PresidingElectionContextStore _contextStore;
  final EnvironmentConfig _config;

  /// Loads context from secure storage, cached user, or DEV env (in that order).
  Future<PresidingElectionContext?> ensureContext() async {
    final PresidingElectionContext? existing = await _contextStore.read();
    if (existing != null) return existing;

    final UserModel? user = await _authLocal.readUser();
    if (user != null) {
      final PresidingElectionContext? fromUser =
          PresidingElectionContextFactory.fromUserModel(
            user,
            fallbackElectionId: _config.electionId,
          );
      if (fromUser != null) {
        await _contextStore.save(fromUser);
        AppLogger.i('Presiding election context restored from saved user');
        return fromUser;
      }
      _logMissingFields(user);
    }

    if (_config.flavor == Flavor.dev) {
      final PresidingElectionContext? fromEnv =
          PresidingElectionContextFactory.fromDevEnv(_config);
      if (fromEnv != null) {
        await _contextStore.save(fromEnv);
        AppLogger.i(
          'DEV presiding election context loaded from assets/env/dev.env',
        );
        return fromEnv;
      }
      AppLogger.w(
        'DEV presiding context unavailable — set ELECTION_ID, DEV_PO_PS_ID, '
        'and DEV_PO_AREA_TYPE (U/R) in assets/env/dev.env, or login with a '
        'presiding officer account whose API returns psId + areaType.',
      );
    }

    return null;
  }

  void _logMissingFields(UserModel user) {
    final List<String> missing = <String>[];
    final int electionId = user.electionId ?? _config.electionId ?? 0;
    if (electionId <= 0) missing.add('electionId');
    if ((user.psId ?? '').trim().isEmpty) missing.add('psId');
    if (PresidingElectionContext.normalizeAreaType(user.areaType).isEmpty) {
      missing.add('areaType');
    }
    if (missing.isEmpty) return;
    AppLogger.w(
      'Logged-in user missing presiding fields: ${missing.join(', ')}',
    );
  }
}
