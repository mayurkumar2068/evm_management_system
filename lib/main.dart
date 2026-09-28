import 'package:evm_management_system/bootstrap/bootstrap.dart';
import 'package:evm_management_system/config/app_config.dart';
import 'package:evm_management_system/config/app_constants.dart';
import 'package:evm_management_system/config/flavor.dart';

Future<void> main() async {
  final Flavor flavor = AppConfig.environment;
  await bootstrap(flavor, AppConstants.forFlavor(flavor));
}
