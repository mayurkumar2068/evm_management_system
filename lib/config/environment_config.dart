import 'package:evm_management_system/config/flavor.dart';
import 'package:evm_management_system/core/legal/privacy_urls.dart';
import 'package:evm_management_system/core/network/api_endpoints.dart';
import 'package:evm_management_system/core/utils/json_map.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentConfig {
  const EnvironmentConfig({
    required this.flavor,
    required this.apiBaseUrl,
    required this.poElectionApiBaseUrl,
    required this.olinApiBaseUrl,
    required this.surveyApiBaseUrl,
    required this.surveyWebBaseUrl,
    required this.voterSearchEngineUrl,
    required this.voterSearchApiBaseUrl,
    required this.voterSearchPassKey,
    required this.voterSearchAesKey,
    required this.voterRegistrationUrl,
    required this.candidateExpenditureUrl,
    required this.emsUrl,
    required this.privacyPolicyUrl,
    required this.electionId,
    required this.devPoPsId,
    required this.devPoAreaType,
    required this.devPoPollingStationCode,
    required this.devPoPollingStationName,
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.sendTimeout,
    required this.enableLogging,
    required this.enableSslPinning,
    required this.sslPinSha256,
    required this.sessionTimeout,
    required this.syncInterval,
    required this.syncMaxRetry,
    required this.showRegistrationDefault,
    required this.featureFlagsPath,
    required this.poSelfRegisterUrl,
    required this.psSelfRegisterUrl,
  });

  factory EnvironmentConfig.load(Flavor flavor) {
    String require(String key) {
      final String? value = dotenv.env[key];
      if (value == null || value.isEmpty) {
        if (key == 'SSL_PIN_SHA256') return '';
        throw StateError('Missing required env key: $key');
      }
      return value;
    }

    int requireInt(String key) => int.parse(require(key));
    bool requireBool(String key) => require(key).toLowerCase() == 'true';

    int? optionalInt(String key) {
      final String? value = dotenv.env[key];
      if (value == null || value.trim().isEmpty) return null;
      return int.tryParse(value.trim());
    }

    String? optionalString(String key) {
      final String? value = dotenv.env[key]?.trim();
      if (value == null || value.isEmpty) return null;
      return value;
    }

    bool optionalBool(String key, {required bool defaultValue}) {
      final String? value = dotenv.env[key]?.trim();
      if (value == null || value.isEmpty) return defaultValue;
      return parseLooseBoolOr(value, defaultValue: defaultValue);
    }

    final String apiBaseUrl = require('API_BASE_URL');
    final String? poElectionRaw = dotenv.env['PO_ELECTION_API_BASE_URL']
        ?.trim();
    final String? olinApiRaw = dotenv.env['OLIN_API_BASE_URL']?.trim();
    final String? surveyApiRaw = dotenv.env['SURVEY_API_BASE_URL']?.trim();
    final String? surveyWebRaw = dotenv.env['SURVEY_WEB_BASE_URL']?.trim();
    final String? voterSearchRaw = dotenv.env['VOTER_SEARCH_ENGINE_URL']
        ?.trim();
    final String? voterSearchApiRaw = dotenv.env['VOTER_SEARCH_API_BASE_URL']
        ?.trim();
    final String? voterSearchPassKeyRaw = dotenv.env['VOTER_SEARCH_PASS_KEY']
        ?.trim();
    final String? voterSearchAesKeyRaw = dotenv.env['VOTER_SEARCH_AES_KEY']
        ?.trim();
    final String? voterRegistrationRaw = dotenv.env['VOTER_REGISTRATION_URL']
        ?.trim();
    final String? candidateExpenditureRaw = dotenv
        .env['CANDIDATE_EXPENDITURE_URL']
        ?.trim();
    final String? emsRaw = dotenv.env['EMS_URL']?.trim();
    final String? privacyPolicyRaw = dotenv.env['PRIVACY_POLICY_URL']?.trim();

    return EnvironmentConfig(
      flavor: flavor,
      apiBaseUrl: apiBaseUrl,
      poElectionApiBaseUrl: (poElectionRaw != null && poElectionRaw.isNotEmpty)
          ? poElectionRaw
          : _defaultPoElectionBaseUrl(apiBaseUrl),
      olinApiBaseUrl: (olinApiRaw != null && olinApiRaw.isNotEmpty)
          ? olinApiRaw
          : 'http://10.115.197.192/OLINAPI',
      surveyApiBaseUrl: (surveyApiRaw != null && surveyApiRaw.isNotEmpty)
          ? surveyApiRaw
          : _localServiceDefault(
              flavor,
              'SURVEY_API_BASE_URL',
              'http://10.115.197.192/POElectionAPI/api',
              nonDevFallback: apiBaseUrl,
            ),
      surveyWebBaseUrl: (surveyWebRaw != null && surveyWebRaw.isNotEmpty)
          ? surveyWebRaw
          : _localServiceDefault(
              flavor,
              'SURVEY_WEB_BASE_URL',
              'http://localhost:4200/',
            ),
      voterSearchEngineUrl:
          (voterSearchRaw != null && voterSearchRaw.isNotEmpty)
          ? voterSearchRaw
          : _defaultVoterSearchUrl(
              (poElectionRaw != null && poElectionRaw.isNotEmpty)
                  ? poElectionRaw
                  : _defaultPoElectionBaseUrl(apiBaseUrl),
            ),
      voterSearchApiBaseUrl:
          (voterSearchApiRaw != null && voterSearchApiRaw.isNotEmpty)
          ? voterSearchApiRaw
          : 'https://mpsecerms.mp.gov.in/SECSearchAPI',
      voterSearchPassKey:
          (voterSearchPassKeyRaw != null && voterSearchPassKeyRaw.isNotEmpty)
          ? voterSearchPassKeyRaw
          : '3fb7Fb5dBbl643',
      voterSearchAesKey:
          (voterSearchAesKeyRaw != null && voterSearchAesKeyRaw.isNotEmpty)
          ? voterSearchAesKeyRaw
          : '7ed64fb158a45676bef0e0c565c9be53',
      voterRegistrationUrl:
          (voterRegistrationRaw != null && voterRegistrationRaw.isNotEmpty)
          ? voterRegistrationRaw
          : 'https://mpsecerms.mp.gov.in/secforms',
      candidateExpenditureUrl:
          (candidateExpenditureRaw != null &&
              candidateExpenditureRaw.isNotEmpty)
          ? candidateExpenditureRaw
          : 'http://10.115.197.192/CandidateExpenditure/Home.aspx',
      emsUrl: (emsRaw != null && emsRaw.isNotEmpty)
          ? emsRaw
          : 'https://www.mplocalelection.mp.gov.in/iems/EMS/Login.aspx',
      privacyPolicyUrl:
          (privacyPolicyRaw != null && privacyPolicyRaw.isNotEmpty)
          ? privacyPolicyRaw
          : PrivacyUrls.statement,
      electionId: optionalInt('ELECTION_ID'),
      devPoPsId: optionalString('DEV_PO_PS_ID'),
      devPoAreaType: optionalString('DEV_PO_AREA_TYPE'),
      devPoPollingStationCode: optionalString('DEV_PO_POLLING_STATION_CODE'),
      devPoPollingStationName: optionalString('DEV_PO_POLLING_STATION_NAME'),
      connectTimeout: Duration(
        milliseconds: requireInt('API_CONNECT_TIMEOUT_MS'),
      ),
      receiveTimeout: Duration(
        milliseconds: requireInt('API_RECEIVE_TIMEOUT_MS'),
      ),
      sendTimeout: Duration(milliseconds: requireInt('API_SEND_TIMEOUT_MS')),
      enableLogging: requireBool('ENABLE_LOGGING'),
      enableSslPinning: requireBool('ENABLE_SSL_PINNING'),
      sslPinSha256: dotenv.env['SSL_PIN_SHA256'] ?? '',
      sessionTimeout: Duration(minutes: requireInt('SESSION_TIMEOUT_MINUTES')),
      syncInterval: Duration(seconds: requireInt('SYNC_INTERVAL_SECONDS')),
      syncMaxRetry: requireInt('SYNC_MAX_RETRY'),

      showRegistrationDefault: optionalBool(
        'SHOW_REGISTRATION',
        defaultValue: true,
      ),
      featureFlagsPath:
          optionalString('FEATURE_FLAGS_PATH') ??
          PoElectionEndpoints.appFeatureFlags,
      poSelfRegisterUrl: optionalString('PO_SELF_REGISTER_URL') ?? '',
      psSelfRegisterUrl: optionalString('PS_SELF_REGISTER_URL') ?? '',
    );
  }

  final Flavor flavor;
  final String apiBaseUrl;

  final String poElectionApiBaseUrl;

  final String olinApiBaseUrl;

  final String surveyApiBaseUrl;

  final String surveyWebBaseUrl;

  final String voterSearchEngineUrl;

  final String voterSearchApiBaseUrl;

  final String voterSearchPassKey;

  final String voterSearchAesKey;

  final String voterRegistrationUrl;

  final String candidateExpenditureUrl;

  final String emsUrl;

  final String privacyPolicyUrl;

  final int? electionId;

  final String? devPoPsId;
  final String? devPoAreaType;
  final String? devPoPollingStationCode;
  final String? devPoPollingStationName;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;
  final bool enableLogging;
  final bool enableSslPinning;
  final String sslPinSha256;
  final Duration sessionTimeout;
  final Duration syncInterval;
  final int syncMaxRetry;

  final bool showRegistrationDefault;

  final String featureFlagsPath;

  final String poSelfRegisterUrl;

  final String psSelfRegisterUrl;

  bool get isProduction => flavor.isProduction;

  static String _defaultPoElectionBaseUrl(String apiBaseUrl) {
    final Uri uri = Uri.parse(apiBaseUrl);
    final String origin = uri.hasPort
        ? '${uri.scheme}://${uri.host}:${uri.port}'
        : '${uri.scheme}://${uri.host}';
    return origin;
  }

  static String _defaultVoterSearchUrl(String poElectionOrigin) {
    final Uri uri = Uri.parse(poElectionOrigin);
    final String origin = uri.hasPort
        ? '${uri.scheme}://${uri.host}:${uri.port}'
        : '${uri.scheme}://${uri.host}';
    return '$origin/SECSearchEngine';
  }

  static String _localServiceDefault(
    Flavor flavor,
    String key,
    String devDefault, {
    String? nonDevFallback,
  }) {
    if (flavor == Flavor.dev) {
      return devDefault;
    }
    final String? fallback = nonDevFallback?.trim();
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }
    throw StateError('Missing required env key: $key');
  }
}
