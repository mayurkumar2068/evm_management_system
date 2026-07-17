/// Central source of truth for all application routes.
/// Combines name and path into a single type-safe enum to follow DRY principles.
enum AppRoute {
  splash('/', 'splash'),
  onboarding('/onboarding', 'onboarding'),
  login('/login', 'login'),
  serviceLogin('/service-login', 'serviceLogin'),
  dashboard('/dashboard', 'dashboard'),
  activityHistory('/dashboard/history', 'activityHistory'),
  masterStockRegister('/stock-register', 'masterStockRegister'),
  controlUnit('/control-units', 'controlUnit'),
  ballotUnit('/ballot-units', 'ballotUnit'),
  deviceDetail('/device-detail', 'deviceDetail'),
  scanner('/scanner', 'scanner'),
  reports('/reports', 'reports'),
  notifications('/notifications', 'notifications'),
  profile('/profile', 'profile'),
  settings('/settings', 'settings'),
  auditTrail('/audit-trail', 'auditTrail'),
  syncManagement('/sync', 'syncManagement'),
  search('/search', 'search'),
  help('/help', 'help'),
  about('/about', 'about'),
  webView('/web-view', 'webView'),
  offlineFallback('/offline-fallback', 'offlineFallback'),
  offlineHub('/offline', 'offlineHub'),
  presidingDashboard('/presiding', 'presidingDashboard'),
  presidingTurnout('/presiding-turnout', 'presidingTurnout'),
  presidingLivePoll('/presiding-live', 'presidingLivePoll'),
  onlineNominationHome('/online-nomination', 'onlineNominationHome'),
  urbanNominationSelection(
    '/online-nomination/urban',
    'urbanNominationSelection',
  ),
  panchayatNominationSelection(
    '/online-nomination/panchayat',
    'panchayatNominationSelection',
  ),
  nominationWorkflow('/online-nomination/workflow', 'nominationWorkflow'),
  nominationSuccess('/online-nomination/success', 'nominationSuccess'),
  nominationReceipt('/online-nomination/receipt', 'nominationReceipt'),
  nominationTrackStatus(
    '/online-nomination/track-status',
    'nominationTrackStatus',
  );

  const AppRoute(this.path, this.name);

  final String path;
  final String name;

  @override
  String toString() => name;
}
