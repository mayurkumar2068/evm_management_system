import 'package:evm_management_system/bootstrap/bootstrap.dart';
import 'package:evm_management_system/config/env/dev_constants.dart';
import 'package:evm_management_system/config/flavor.dart';

/// DEV release entry point. Build with `-t lib/main_dev.dart` (see
/// `.github/workflows/build.yml`) so only `devConstants` is reachable from
/// this binary — `uat_constants.dart`/`prod_constants.dart` are never
/// imported here and are dropped by the tree shaker. Do not import
/// `config/app_constants.dart` from this file.
Future<void> main() async {
  await bootstrap(Flavor.dev, devConstants);
}
