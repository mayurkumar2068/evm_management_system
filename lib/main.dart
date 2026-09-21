import 'package:evm_management_system/bootstrap/bootstrap.dart';
import 'package:evm_management_system/config/app_config.dart';
import 'package:evm_management_system/config/app_constants.dart';
import 'package:evm_management_system/config/flavor.dart';

/// Default entry point for ad hoc `flutter run`/`flutter test` without an
/// explicit `-t`/`--target`. Not flavor-isolated at compile time (imports
/// [AppConstants], which pulls in all three flavor maps) — release builds
/// must use `main_dev.dart`/`main_uat.dart`/`main_prod.dart` instead. See
/// docs/L2_VAPT_IMPLEMENTATION.md (F-06).
Future<void> main() async {
  final Flavor flavor = AppConfig.environment;
  await bootstrap(flavor, AppConstants.forFlavor(flavor));
}
