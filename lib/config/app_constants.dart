import 'package:evm_management_system/config/env/dev_constants.dart';
import 'package:evm_management_system/config/env/prod_constants.dart';
import 'package:evm_management_system/config/env/uat_constants.dart';
import 'package:evm_management_system/config/flavor.dart';

/// Convenience aggregator over the three per-flavor constant files.
///
/// **Only safe for non-shipping entry points** (the default `lib/main.dart`,
/// used for ad hoc `flutter run` without an explicit `-t`/`--target`, and
/// tests). Importing this class pulls all three flavor maps into the same
/// compilation unit, so nothing that imports it can be tree-shaken flavor by
/// flavor. Release builds must go through `lib/main_dev.dart`,
/// `lib/main_uat.dart`, or `lib/main_prod.dart`, each of which imports only
/// its own `env/*_constants.dart` file directly — never this one. See
/// docs/L2_VAPT_IMPLEMENTATION.md (F-01/F-06) for why that isolation matters.
abstract final class AppConstants {
  static Map<String, String> forFlavor(Flavor flavor) => switch (flavor) {
    Flavor.dev => devConstants,
    Flavor.uat => uatConstants,
    Flavor.production => prodConstants,
  };
}
