import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';

/// Mirrors hourly / final turnout counts into live poll (लाइव जानकारी).
abstract final class TurnoutLiveSync {
  static const Set<String> _mirrorSlotIds = <String>{
    TurnoutSlotIds.slot9Am,
    TurnoutSlotIds.slot11Am,
    TurnoutSlotIds.slot1Pm,
    TurnoutSlotIds.slot3Pm,
    TurnoutSlotIds.slot5Pm,
    TurnoutSlotIds.pollCompletion,
  };

  /// Hourly slots + मतदान जानकारी push latest counts to live poll — not queue.
  static bool mirrorsToLivePoll(String slotId) => _mirrorSlotIds.contains(slotId);

  /// अंतिम मतदान की जानकारी is authoritative — live must match exactly.
  static bool forcesExactLiveCounts(String slotId) =>
      slotId == TurnoutSlotIds.pollCompletion;

  /// Live stays if it is already higher; otherwise hourly/final becomes the floor.
  static ({int male, int female, int other}) mergePreferringHigherLive({
    required TurnoutRecord? live,
    required int male,
    required int female,
    required int other,
  }) {
    return (
      male: _max(live?.male ?? 0, male),
      female: _max(live?.female ?? 0, female),
      other: _max(live?.thirdGender ?? 0, other),
    );
  }

  static bool liveAlreadyCoversHourly({
    required TurnoutRecord? live,
    required int male,
    required int female,
    required int other,
  }) {
    return (live?.male ?? 0) >= male &&
        (live?.female ?? 0) >= female &&
        (live?.thirdGender ?? 0) >= other;
  }

  static int _max(int a, int b) => a >= b ? a : b;
}
