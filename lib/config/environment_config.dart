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
    required this.surveyApiBaseUrl,
    required this.surveyWebBaseUrl,
    required this.voterSearchEngineUrl,
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
    final String? surveyApiRaw = dotenv.env['SURVEY_API_BASE_URL']?.trim();
    final String? surveyWebRaw = dotenv.env['SURVEY_WEB_BASE_URL']?.trim();
    final String? voterSearchRaw = dotenv.env['VOTER_SEARCH_ENGINE_URL']?.trim();

    return EnvironmentConfig(
      flavor: flavor,
      apiBaseUrl: apiBaseUrl,
      poElectionApiBaseUrl: (poElectionRaw != null && poElectionRaw.isNotEmpty)
          ? poElectionRaw
          : _defaultPoElectionBaseUrl(apiBaseUrl),
      surveyApiBaseUrl: (surveyApiRaw != null && surveyApiRaw.isNotEmpty)
          ? surveyApiRaw
          : _localServiceDefault(
              flavor,
              'SURVEY_API_BASE_URL',
              'http://localhost:3000/api',
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

  /// Base URL for the survey Node API (`survey_api/`), including `/api` suffix.
  final String surveyApiBaseUrl;

  /// Base URL for the embedded Angular survey micro-app (`survey_web/`).
  final String surveyWebBaseUrl;

  /// Voter search engine portal opened from the dashboard grid.
  final String voterSearchEngineUrl;

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

  /// DEV may omit survey URLs (localhost defaults). UAT/PROD must set env keys.
  static String _localServiceDefault(
    Flavor flavor,
    String key,
    String devDefault,
  ) {
    if (flavor == Flavor.dev) {
      return devDefault;
    }
    throw StateError('Missing required env key: $key');
  }
}
