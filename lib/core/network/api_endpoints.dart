/// Centralized registry of relative API paths.
///
/// Base URLs come from [EnvironmentConfig]; only relative paths live here so
/// there is a single source of truth and no hardcoded hosts in this file.
abstract final class ApiEndpoints {
  // Auth
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/profile';

  // Dashboard
  static const String dashboardSummary = '/dashboard/summary';
  static const String recentActivity = '/dashboard/recent-activity';

  // Control / Ballot Units
  static const String controlUnits = '/control-units';
  static const String ballotUnits = '/ballot-units';
  static String controlUnit(String id) => '/control-units/$id';
  static String ballotUnit(String id) => '/ballot-units/$id';

  // Stock register
  static const String stockRegister = '/stock-register';

  // Sync
  static const String syncBatch = '/sync/batch';

  // Notifications
  static const String notifications = '/notifications';
  static const String registerDevice = '/notifications/register-device';

  // Audit
  static const String auditTrail = '/audit-trail';

  // Survey service auth + masters
  // Base URL is expected to include `/api` (e.g. http://host/api)
  static const String surveyLoginPass = '/Account/login-survey-pass';
  static String surveyDistrictById(String id) => '/Masters/districts/$id';
}

/// PO Election API paths (OpenAPI: POElectionAPI v1).
///
/// Base URL: [EnvironmentConfig.poElectionApiBaseUrl] (`PO_ELECTION_API_BASE_URL`).
abstract final class PoElectionEndpoints {
  // Account / Auth
  static const String loginPoPass = '/api/Account/login-po-pass';

  /// GET `/api/POElection/get-po-status?id={userId}`
  static String getPoStatus(String userId) =>
      '/api/POElection/get-po-status?id=$userId';

  // Milestones
  static const String savePollLive = '/api/POElection/save-poll-live';
  static const String insertDepartFromHome =
      '/api/POElection/insert-depart-from-home';
  static const String insertReachedToPs =
      '/api/POElection/insert-reached-to-ps';
  static const String insertMaterialReceived =
      '/api/POElection/insert-material-received';
  static const String insertMockPollConducted =
      '/api/POElection/insert-mock-poll-conducted';
  static const String insertPollStarted = '/api/POElection/insert-poll-started';
  static const String insert09AmCount = '/api/POElection/insert-09am-count';
  static const String insert11AmCount = '/api/POElection/insert-11am-count';
  static const String insert01PmCount = '/api/POElection/insert-01pm-count';
  static const String insert03PmCount = '/api/POElection/insert-03pm-count';
  static const String insert05PmCount = '/api/POElection/insert-05pm-count';
  static const String insertFinalCount = '/api/POElection/insert-final-count';
  static const String insertLineCount = '/api/POElection/insert-line-count';
  static const String insertPollEnded = '/api/POElection/insert-poll-ended';
  static const String insertMachineSealed =
      '/api/POElection/insert-machine-sealed';
  static const String insertMaterialSubmitted =
      '/api/POElection/insert-material-submitted';
}
