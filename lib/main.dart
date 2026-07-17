import 'package:evm_management_system/bootstrap/bootstrap.dart';
import 'package:evm_management_system/config/app_config.dart';

/// Single application entrypoint for every environment.
///
/// The active environment (DEV / UAT / PRODUCTION) is selected in
/// [AppConfig.environment]. Change that one constant to switch flavors.
Future<void> main() => bootstrap(AppConfig.environment);
