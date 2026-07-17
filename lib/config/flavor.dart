/// The build flavors / environments supported by the application.
enum Flavor {
  dev,
  uat,
  production;

  /// The bundled `.env` asset for this flavor.
  String get envFile => switch (this) {
    Flavor.dev => 'assets/env/dev.env',
    Flavor.uat => 'assets/env/uat.env',
    Flavor.production => 'assets/env/prod.env',
  };

  /// Display label shown in non-production banners.
  String get label => switch (this) {
    Flavor.dev => 'DEV',
    Flavor.uat => 'UAT',
    Flavor.production => 'PROD',
  };

  bool get isProduction => this == Flavor.production;
}
