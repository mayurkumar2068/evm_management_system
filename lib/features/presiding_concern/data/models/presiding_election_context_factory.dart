import 'package:evm_management_system/config/environment_config.dart';
import 'package:evm_management_system/config/flavor.dart';
import 'package:evm_management_system/features/auth/data/models/user_model.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_election_context.dart';

/// Builds [PresidingElectionContext] from auth user payloads.
abstract final class PresidingElectionContextFactory {
  /// Returns a complete context when login/profile includes required fields.
  static PresidingElectionContext? fromUserModel(
    UserModel user, {
    int? fallbackElectionId,
  }) {
    final int electionId = user.electionId ?? fallbackElectionId ?? 0;
    final String psId = user.psId?.trim() ?? '';
    final String areaType = PresidingElectionContext.normalizeAreaType(
      user.areaType,
    );
    if (electionId <= 0 || psId.isEmpty || areaType.isEmpty) {
      return null;
    }
    return PresidingElectionContext(
      electionId: electionId,
      psId: psId,
      areaType: areaType,
      pollingStationCode: user.pollingStationCode,
      pollingStationName: user.pollingStationName,
    );
  }

  /// DEV-only fallback from `assets/env/dev.env` for local PO API testing.
  static PresidingElectionContext? fromDevEnv(EnvironmentConfig config) {
    if (config.flavor != Flavor.dev) return null;
    final int? electionId = config.electionId;
    final String psId = config.devPoPsId?.trim() ?? '';
    final String areaType = PresidingElectionContext.normalizeAreaType(
      config.devPoAreaType,
    );
    if (electionId == null ||
        electionId <= 0 ||
        psId.isEmpty ||
        areaType.isEmpty) {
      return null;
    }
    return PresidingElectionContext(
      electionId: electionId,
      psId: psId,
      areaType: areaType,
      pollingStationCode: config.devPoPollingStationCode,
      pollingStationName: config.devPoPollingStationName,
    );
  }
}
