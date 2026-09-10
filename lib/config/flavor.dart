enum Flavor {
  dev,
  uat,
  production;

  String get envFile => switch (this) {
    Flavor.dev => 'assets/env/dev.env',
    Flavor.uat => 'assets/env/uat.env',
    Flavor.production => 'assets/env/prod.env',
  };

  String get label => switch (this) {
    Flavor.dev => 'DEV',
    Flavor.uat => 'UAT',
    Flavor.production => 'PROD',
  };

  bool get isProduction => this == Flavor.production;
}
