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
}
