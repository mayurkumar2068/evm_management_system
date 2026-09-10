import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('online nomination paths are identified for 5.1.1 gating', () {
    expect(AppRoute.onlineNominationHome.isOnlineNomination, isTrue);
    expect(AppRoute.nominationWorkflow.isOnlineNomination, isTrue);
    expect(AppRoute.isOnlineNominationPath('/online-nomination'), isTrue);
    expect(AppRoute.isOnlineNominationPath('/online-nomination/workflow'), isTrue);
    expect(AppRoute.isOnlineNominationPath('/voter-search'), isFalse);
    expect(AppRoute.dashboard.isOnlineNomination, isFalse);
  });
}
