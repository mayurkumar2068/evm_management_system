import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';
import 'package:evm_management_system/features/presiding_concern/domain/turnout_live_sync.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('forcesExactLiveCounts only for poll_completion', () {
    expect(
      TurnoutLiveSync.forcesExactLiveCounts(TurnoutSlotIds.pollCompletion),
      isTrue,
    );
    expect(
      TurnoutLiveSync.forcesExactLiveCounts(TurnoutSlotIds.slot9Am),
      isFalse,
    );
    expect(
      TurnoutLiveSync.forcesExactLiveCounts(TurnoutSlotIds.livePollInfo),
      isFalse,
    );
  });

  test('poll_completion is included in mirrorsToLivePoll', () {
    expect(
      TurnoutLiveSync.mirrorsToLivePoll(TurnoutSlotIds.pollCompletion),
      isTrue,
    );
  });
}
