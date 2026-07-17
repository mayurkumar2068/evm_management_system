import 'package:evm_management_system/config/flavor.dart';

/// Central place to select which environment the app runs against.
///
/// There is a single entrypoint (`lib/main.dart`). To switch between
/// DEV / UAT / PRODUCTION while developing, just change [defaultFlavor] below
/// and run the app — no separate `main_*.dart` files are needed.
///
/// CI / release builds may override the flavor without editing code by passing
/// `--dart-define=APP_FLAVOR=uat` (values: `dev`, `uat`, `prod`).
class AppConfig {
  const AppConfig._();

  /// 👉 Change this value to switch environment while developing.
  static const Flavor defaultFlavor = Flavor.dev;

  /// Optional build-time override, e.g. `--dart-define=APP_FLAVOR=uat`.
  static const String _override = String.fromEnvironment('APP_FLAVOR');

  /// The environment the app should boot with.
  static Flavor get environment => switch (_override) {
    'dev' => Flavor.dev,
    'uat' => Flavor.uat,
    'prod' || 'production' => Flavor.production,
    _ => defaultFlavor,
  };
}
