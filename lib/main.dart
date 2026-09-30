import 'package:MPSECNET/bootstrap/bootstrap.dart';
import 'package:MPSECNET/config/app_config.dart';
import 'package:MPSECNET/config/app_constants.dart';
import 'package:MPSECNET/config/flavor.dart';

Future<void> main() async {
  final Flavor flavor = AppConfig.environment;
  await bootstrap(flavor, AppConstants.forFlavor(flavor));
}
