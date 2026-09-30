import 'package:MPSECNET/bootstrap/bootstrap.dart';
import 'package:MPSECNET/config/env/uat_constants.dart';
import 'package:MPSECNET/config/flavor.dart';


Future<void> main() async {
  await bootstrap(Flavor.uat, uatConstants);
}
