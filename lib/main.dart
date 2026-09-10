import 'package:evm_management_system/bootstrap/bootstrap.dart';
import 'package:evm_management_system/config/app_config.dart';

Future<void> main() async {
  await bootstrap(AppConfig.environment);
}
