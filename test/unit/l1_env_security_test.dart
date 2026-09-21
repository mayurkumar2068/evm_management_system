import 'package:evm_management_system/config/app_constants.dart';
import 'package:evm_management_system/config/environment_config.dart';
import 'package:evm_management_system/config/flavor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prod config loads without private IP fallbacks', () {
    final EnvironmentConfig config = EnvironmentConfig.load(
      Flavor.production,
      AppConstants.forFlavor(Flavor.production),
    );
    expect(config.apiBaseUrl.startsWith('https://'), isTrue);
    expect(config.olinApiBaseUrl.contains('10.115'), isFalse);
    expect(config.candidateExpenditureUrl.contains('10.115'), isFalse);
    expect(config.voterSearchPassKey.isNotEmpty, isTrue);
    expect(config.voterSearchAesKey.isNotEmpty, isTrue);
  });

  test('dev config keeps LAN hosts scoped to the dev flavor only', () {
    final EnvironmentConfig dev = EnvironmentConfig.load(
      Flavor.dev,
      AppConstants.forFlavor(Flavor.dev),
    );
    final EnvironmentConfig prod = EnvironmentConfig.load(
      Flavor.production,
      AppConstants.forFlavor(Flavor.production),
    );
    final EnvironmentConfig uat = EnvironmentConfig.load(
      Flavor.uat,
      AppConstants.forFlavor(Flavor.uat),
    );

    expect(dev.olinApiBaseUrl, contains('10.115.197.192'));
    expect(prod.olinApiBaseUrl.contains('10.115'), isFalse);
    expect(uat.olinApiBaseUrl.contains('10.115'), isFalse);
  });
}
