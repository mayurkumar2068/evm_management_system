enum AppRoute {
  splash('/', 'splash'),
  login('/login', 'login'),
  serviceLogin('/service-login', 'serviceLogin'),
  dashboard('/dashboard', 'dashboard'),
  notifications('/notifications', 'notifications'),
  profile('/profile', 'profile'),
  webView('/web-view', 'webView'),
  offlineFallback('/offline-fallback', 'offlineFallback'),
  offlineHub('/offline', 'offlineHub'),
  presidingDashboard('/presiding', 'presidingDashboard'),
  presidingPoDetails('/presiding-po-details', 'presidingPoDetails'),
  presidingPartyDetails('/presiding-party', 'presidingPartyDetails'),
  presidingPartyOtp('/presiding-party-otp', 'presidingPartyOtp'),
  presidingTurnout('/presiding-turnout', 'presidingTurnout'),
  presidingLivePoll('/presiding-live', 'presidingLivePoll'),
  voterSearch('/voter-search', 'voterSearch');

  const AppRoute(this.path, this.name);

  final String path;
  final String name;

  @override
  String toString() => name;
}
