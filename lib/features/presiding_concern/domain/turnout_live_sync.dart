import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';

abstract final class TurnoutLiveSync {
  static const Set<String> _mirrorSlotIds = <String>{
    TurnoutSlotIds.slot9Am,
    TurnoutSlotIds.slot11Am,
    TurnoutSlotIds.slot1Pm,
    TurnoutSlotIds.slot3Pm,
    TurnoutSlotIds.slot5Pm,
    TurnoutSlotIds.pollCompletion,
  };

  static bool mirrorsToLivePoll(String slotId) =>
      _mirrorSlotIds.contains(slotId);

  static bool forcesExactLiveCounts(String slotId) =>
      slotId == TurnoutSlotIds.pollCompletion;

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
