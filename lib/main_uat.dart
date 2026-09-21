import 'package:evm_management_system/bootstrap/bootstrap.dart';
import 'package:evm_management_system/config/env/uat_constants.dart';
import 'package:evm_management_system/config/flavor.dart';

/// UAT release entry point. Build with `-t lib/main_uat.dart` — see
/// `lib/main_dev.dart` for why this must not import `config/app_constants.dart`.
Future<void> main() async {
  await bootstrap(Flavor.uat, uatConstants);
}
