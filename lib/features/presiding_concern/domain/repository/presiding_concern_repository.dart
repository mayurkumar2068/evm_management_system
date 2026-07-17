import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_action_outcome.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_election_context.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';

/// Domain contract for presiding-officer offline-first data.
abstract interface class PresidingConcernRepository {
  /// Loads the active session or seeds defaults for first launch.
  Future<PresidingSession> loadSession();

  /// Marks a milestone complete using the server [ActionDateTime] when available.
  Future<PresidingActionOutcome> completeMilestone(String milestoneId);

  /// Persists turnout figures for a reporting slot.
  Future<PresidingSession> saveTurnout({
    required String slotId,
    int? male,
    int? female,
    int? thirdGender,
    int? queueCount,
  });

  /// Streams session updates for reactive UI.
  Stream<PresidingSession> watchSession();

  /// Applies authenticated election context after officer login.
  Future<void> applyElectionContext(PresidingElectionContext context);

  /// Retries pending milestone and turnout API submissions.
  Future<void> syncPending();

  /// Pulls saved PO status from server and merges into the local session.
  Future<PresidingSession> refreshFromServer();
}
