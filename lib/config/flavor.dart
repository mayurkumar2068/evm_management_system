enum Flavor {
  dev,
  uat,
  production;

  String get label => switch (this) {
    Flavor.dev => 'DEV',
    Flavor.uat => 'UAT',
    Flavor.production => 'PROD',
  };

  bool get isProduction => this == Flavor.production;
}
