import 'package:evm_management_system/features/presiding_concern/data/datasource/presiding_election_context_store.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_election_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const PresidingElectionContext withElectors = PresidingElectionContext(
    electionId: 1,
    psId: 'ps-1',
    areaType: 'U',
    maleElectors: 100,
    femaleElectors: 90,
    otherElectors: 2,
    totalElectors: 192,
  );

  const PresidingElectionContext withoutElectors = PresidingElectionContext(
    electionId: 1,
    psId: 'ps-1',
    areaType: 'U',
  );

  test('mergePreservingElectors keeps counts from fallback', () {
    final PresidingElectionContext merged =
        PresidingElectionContextStore.mergePreservingElectors(
          withoutElectors,
          withElectors,
        );

    expect(merged.maleElectors, 100);
    expect(merged.femaleElectors, 90);
    expect(merged.otherElectors, 2);
    expect(merged.totalElectors, 192);
  });

  test('mergePreservingElectors does not overwrite existing counts', () {
    final PresidingElectionContext merged =
        PresidingElectionContextStore.mergePreservingElectors(
          withElectors,
          withoutElectors,
        );

    expect(merged, withElectors);
  });

  test('preferWithElectors prefers context that has elector counts', () {
    final PresidingElectionContext? picked =
        PresidingElectionContextStore.preferWithElectors(
          withoutElectors,
          withElectors,
        );

    expect(picked?.hasElectorCounts, isTrue);
    expect(picked?.maleElectors, 100);
  });

  test('mergePreservingIdentity keeps userId from disk fallback', () {
    const PresidingElectionContext electorsOnly = PresidingElectionContext(
      electionId: 0,
      psId: '',
      areaType: 'R',
      maleElectors: 50,
      femaleElectors: 45,
      totalElectors: 95,
    );
    const PresidingElectionContext fromDisk = PresidingElectionContext(
      electionId: 7,
      psId: 'ps-rural',
      areaType: 'R',
      userId: 'po-123',
      loginUserName: 'Rural PO',
    );

    final PresidingElectionContext merged =
        PresidingElectionContextStore.mergePreservingIdentity(
          electorsOnly,
          fromDisk,
        );

    expect(merged.userId, 'po-123');
    expect(merged.loginUserName, 'Rural PO');
    expect(merged.psId, 'ps-rural');
    expect(merged.totalElectors, 95);
  });

  test('hasElectorCounts is false when all elector fields are absent', () {
    expect(withoutElectors.hasElectorCounts, isFalse);
    expect(withElectors.hasElectorCounts, isTrue);
  });
}
