/// PROD-flavor build-time configuration values.
///
/// Kept in its own file so `lib/main_prod.dart` can import *only* this file —
/// see `dev_constants.dart` for why that isolation matters.
const Map<String, String> prodConstants = <String, String>{
  'API_BASE_URL': 'https://mplocalelection.mp.gov.in/POElectionAPI/api',
  'API_CONNECT_TIMEOUT_MS': '30000',
  'API_RECEIVE_TIMEOUT_MS': '30000',
  'API_SEND_TIMEOUT_MS': '30000',
  'ENABLE_LOGGING': 'false',
  'ENABLE_SSL_PINNING': 'false',
  'SESSION_TIMEOUT_MINUTES': '10',
  'SYNC_INTERVAL_SECONDS': '120',
  'SYNC_MAX_RETRY': '8',
  'ELECTION_ID': '1',
  'PO_ELECTION_API_BASE_URL':
      'https://mplocalelection.mp.gov.in/POElectionAPI',
  'OLIN_API_BASE_URL': 'https://mplocalelection.mp.gov.in/OLINAPI',
  'SURVEY_API_BASE_URL':
      'https://mplocalelection.mp.gov.in/POElectionAPI/api',
  'SURVEY_WEB_BASE_URL': 'https://mplocalelection.mp.gov.in/pssurvey/',
  'VOTER_SEARCH_ENGINE_URL': 'https://mpsecerms.mp.gov.in/SECSearchEngine/',
  'VOTER_SEARCH_API_BASE_URL': 'https://mpsecerms.mp.gov.in/SECSearchAPI',
  'VOTER_SEARCH_PASS_KEY': '3fb7Fb5dBbl643',
  'VOTER_SEARCH_AES_KEY': '7ed64fb158a45676bef0e0c565c9be53',
  'VOTER_REGISTRATION_URL': 'https://mpsecerms.mp.gov.in/secforms',
  'SHOW_REGISTRATION': 'true',
  'CANDIDATE_EXPENDITURE_URL':
      'https://mplocalelection.mp.gov.in/CandidateExpenditure/Home.aspx',
  'EMS_URL': 'https://www.mplocalelection.mp.gov.in/iems/EMS/Login.aspx',
  'PRIVACY_POLICY_URL':
      'https://mplocalelection.mp.gov.in/privacystatement.aspx',
};
