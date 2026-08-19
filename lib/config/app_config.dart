import 'package:evm_management_system/config/flavor.dart';
import 'package:flutter/services.dart' show appFlavor;

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

  /// 👉 Change this value to switch environment when neither `--flavor` nor
  /// `--dart-define=APP_FLAVOR=...` is supplied (e.g. plain `flutter run`).
  static const Flavor defaultFlavor = Flavor.production;

  /// Optional build-time override, e.g. `--dart-define=APP_FLAVOR=uat`.
  static const String _override = String.fromEnvironment('APP_FLAVOR');

  /// The environment the app should boot with.
  ///
  /// Resolution order:
  /// 1. `--dart-define=APP_FLAVOR=...` — explicit override, required for UAT
  ///    since there is no separate Android `uat` product flavor.
  /// 2. The native `--flavor` the app was actually built with ([appFlavor],
  ///    the Android `dev`/`prod` product flavor) — so a `dev`-flavored build
  ///    can never silently point at the production API, or a `prod` build
  ///    silently point at dev, just because `--dart-define` was forgotten.
  /// 3. [defaultFlavor], when neither is set.
  static Flavor get environment =>
      _fromLabel(_override) ?? _fromLabel(appFlavor) ?? defaultFlavor;

  static Flavor? _fromLabel(String? label) => switch (label) {
    'dev' => Flavor.dev,
    'uat' => Flavor.uat,
    'prod' || 'production' => Flavor.production,
    _ => null,
  };
}
