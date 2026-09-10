import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_action_outcome.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_election_context.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';

abstract interface class PresidingConcernRepository {
  Future<PresidingSession> loadSession();

  Future<PresidingActionOutcome> completeMilestone(String milestoneId);

  Future<PresidingSession> saveTurnout({
    required String slotId,
    int? male,
    int? female,
    int? thirdGender,
    int? queueCount,
  });

  Stream<PresidingSession> watchSession();

  Future<void> applyElectionContext(PresidingElectionContext context);

  Future<void> syncPending();

  Future<PresidingSession> refreshFromServer();

  Future<void> clearLocalCache();
}
