abstract final class ApiEndpoints {
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/profile';

  static const String surveyLoginPass = '/Account/login-survey-pass';

  static const String surveyIsPsUserExistsOtp =
      '/Account/is-ps-user-exists-otp';

  static const String surveyPsLoginWithOtp = '/Account/ps-login-with-otp';

  static const String surveyRegisterPsUser = '/Account/register-ps-user';

  static String surveyDistrictById(String id) => '/Masters/districts/$id';
}

abstract final class PoElectionEndpoints {
  static const String loginPoPass = '/api/Account/login-po-pass';

  static const String registerPoUser = '/api/Account/register-po-user';
  static const String poLogout = '/api/Account/po-logout';

  static const String psLogout = '/api/Account/ps-logout';

  static const String poStatus = '/api/POElection/po-status';

  static const String poPartyDetails = '/api/POElection/po-party-details';

  static const String savePoParty = '/api/POElection/save-po-party';

  static const String poDetails = '/api/POElection/po-details';

  static const String poSendOtp = '/api/POElection/po-send-otp';

  static const String poDetailSaveWithOtp =
      '/api/POElection/po-detail-save-with-otp';

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

  static const String appFeatureFlags = '/api/App/feature-flags';

  static const String mastersCardList = '/api/Masters/card-list';
}
