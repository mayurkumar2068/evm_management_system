import 'package:evm_management_system/config/flavor.dart';
import 'package:flutter/services.dart' show appFlavor;

class AppConfig {
  const AppConfig._();

  static const Flavor defaultFlavor = Flavor.production;

  static const String _override = String.fromEnvironment('APP_FLAVOR');

  static Flavor get environment =>
      _fromLabel(_override) ?? _fromLabel(appFlavor) ?? defaultFlavor;

  static Flavor? _fromLabel(String? label) => switch (label) {
    'dev' => Flavor.dev,
    'uat' => Flavor.uat,
    'prod' || 'production' => Flavor.production,
    _ => null,
  };
}
