import 'package:evm_management_system/config/flavor.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Strongly-typed, immutable view over the active `.env` configuration.
///
/// No URL or tunable is ever hardcoded in the codebase — everything is read
/// from the flavor-specific `.env` file loaded at bootstrap. Construct exactly
/// one instance via [EnvironmentConfig.load] and expose it through Riverpod.
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
  });

  /// Reads values from the already-loaded [dotenv] for the given [flavor].
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

    final String apiBaseUrl = require('API_BASE_URL');
    final String? poElectionRaw = dotenv.env['PO_ELECTION_API_BASE_URL']
        ?.trim();
    final String? olinApiRaw = dotenv.env['OLIN_API_BASE_URL']?.trim();
    final String? surveyApiRaw = dotenv.env['SURVEY_API_BASE_URL']?.trim();
    final String? surveyWebRaw = dotenv.env['SURVEY_WEB_BASE_URL']?.trim();
    final String? voterSearchRaw = dotenv.env['VOTER_SEARCH_ENGINE_URL']?.trim();
    final String? voterSearchApiRaw =
        dotenv.env['VOTER_SEARCH_API_BASE_URL']?.trim();
    final String? voterSearchPassKeyRaw =
        dotenv.env['VOTER_SEARCH_PASS_KEY']?.trim();
    final String? voterSearchAesKeyRaw =
        dotenv.env['VOTER_SEARCH_AES_KEY']?.trim();
    final String? voterRegistrationRaw =
        dotenv.env['VOTER_REGISTRATION_URL']?.trim();
    final String? candidateExpenditureRaw =
        dotenv.env['CANDIDATE_EXPENDITURE_URL']?.trim();

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
      voterSearchEngineUrl: (voterSearchRaw != null && voterSearchRaw.isNotEmpty)
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
    );
  }

  final Flavor flavor;
  final String apiBaseUrl;

  /// Base URL for PO Election APIs (`POElectionAPI v1` OpenAPI).
  final String poElectionApiBaseUrl;

  /// Base URL for Online Nomination (OLINAPI) master lookups.
  final String olinApiBaseUrl;

  /// Base URL for survey / PSSurvey APIs (`POElectionAPI/api`).
  final String surveyApiBaseUrl;

  /// Base URL for the embedded Angular survey micro-app (`survey_web/`).
  final String surveyWebBaseUrl;

  /// Legacy voter search portal URL (WebView; retained for reference).
  final String voterSearchEngineUrl;

  /// SECSearchAPI base for native voter search.
  final String voterSearchApiBaseUrl;

  /// Short PassKey (AES-GCM encrypted before each SECSearchAPI request).
  final String voterSearchPassKey;

  /// AES-256-GCM private key (32 UTF-8 chars) for SECSearchAPI.
  final String voterSearchAesKey;

  /// Voter registration portal opened from the dashboard grid.
  final String voterRegistrationUrl;

  /// Candidate expenditure portal opened from the dashboard grid.
  final String candidateExpenditureUrl;

  /// Active election cycle ID sent with officer login (deployment config).
  final int? electionId;

  /// DEV-only PO test identifiers (see `assets/env/dev.env`).
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

  /// DEV may omit survey URLs (localhost defaults).
  /// UAT/PROD should set env keys; if survey API is blank, reuse [nonDevFallback]
  /// (typically [apiBaseUrl]) so boot does not crash.
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
