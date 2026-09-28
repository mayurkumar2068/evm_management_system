/// DEV-flavor build-time configuration values.
///
/// Kept in its own file, separate from `uat_constants.dart`/`prod_constants.dart`,
/// so `lib/main_dev.dart` can import *only* this file. That import isolation is
/// what lets the Dart AOT tree shaker drop this map (and its private LAN IP)
/// entirely from prod/uat release binaries — see
/// docs/L2_VAPT_IMPLEMENTATION.md (F-06) for why a shared aggregator/switch
/// can't achieve the same guarantee.
const Map<String, String> devConstants = <String, String>{
  'API_BASE_URL': 'http://10.115.197.192/POElectionAPI/api',
  'API_CONNECT_TIMEOUT_MS': '20000',
  'API_RECEIVE_TIMEOUT_MS': '20000',
  'API_SEND_TIMEOUT_MS': '20000',
  'ENABLE_LOGGING': 'true',
  'ENABLE_SSL_PINNING': 'false',
  'SESSION_TIMEOUT_MINUTES': '15',
  'SYNC_INTERVAL_SECONDS': '60',
  'SYNC_MAX_RETRY': '5',
  'ELECTION_ID': '1',
  'DEV_PO_AREA_TYPE': 'U',
  'PO_ELECTION_API_BASE_URL': 'http://10.115.197.192/POElectionAPI',
  // Local mcc-backend (complaints_backend/mcc-backend) for grievance module testing.
  'GRIEVANCE_API_BASE_URL': 'http://localhost:8000',
  'OLIN_API_BASE_URL': 'http://10.115.197.192/OLINAPI',
  'SURVEY_API_BASE_URL': 'http://10.115.197.192/POElectionAPI/api',
  'SURVEY_WEB_BASE_URL': 'https://mplocalelection.mp.gov.in/pssurvey/',
  'VOTER_SEARCH_ENGINE_URL': 'https://mpsecerms.mp.gov.in/SECSearchEngine/',
  'VOTER_SEARCH_API_BASE_URL': 'https://mpsecerms.mp.gov.in/SECSearchAPI',
  'VOTER_SEARCH_PASS_KEY': '3fb7Fb5dBbl643',
  'VOTER_SEARCH_AES_KEY': '7ed64fb158a45676bef0e0c565c9be53',
  'VOTER_REGISTRATION_URL': 'https://mpsecerms.mp.gov.in/secforms',
  'SHOW_REGISTRATION': 'true',
  'CANDIDATE_EXPENDITURE_URL':
      'http://10.115.197.192/CandidateExpenditure/Home.aspx',
  'EMS_URL': 'https://www.mplocalelection.mp.gov.in/iems/EMS/Login.aspx',
  'PRIVACY_POLICY_URL':
      'https://mplocalelection.mp.gov.in/privacystatement.aspx',
};
