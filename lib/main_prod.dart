import 'package:evm_management_system/bootstrap/bootstrap.dart';
import 'package:evm_management_system/config/env/prod_constants.dart';
import 'package:evm_management_system/config/flavor.dart';


Future<void> main() async {
  await bootstrap(Flavor.production, prodConstants);
}
