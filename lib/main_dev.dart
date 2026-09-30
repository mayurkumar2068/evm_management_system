import 'package:MPSECNET/bootstrap/bootstrap.dart';
import 'package:MPSECNET/config/env/dev_constants.dart';
import 'package:MPSECNET/config/flavor.dart';


Future<void> main() async {
  await bootstrap(Flavor.dev, devConstants);
}
