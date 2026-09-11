import 'package:evm_management_system/config/environment_config.dart';
import 'package:evm_management_system/config/flavor.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prod env loads without private IP fallbacks', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: 'assets/env/prod.env');
    final EnvironmentConfig config = EnvironmentConfig.load(Flavor.production);
    expect(config.apiBaseUrl.startsWith('https://'), isTrue);
    expect(config.olinApiBaseUrl.contains('10.115'), isFalse);
    expect(config.candidateExpenditureUrl.contains('10.115'), isFalse);
    expect(config.voterSearchPassKey.isNotEmpty, isTrue);
    expect(config.voterSearchAesKey.isNotEmpty, isTrue);
  });

  test('dev env keeps LAN hosts from asset only', () {
    dotenv.loadFromString(
      envString: '''
ENVIRONMENT=DEV
API_BASE_URL=http://10.115.197.192/POElectionAPI/api
API_CONNECT_TIMEOUT_MS=20000
API_RECEIVE_TIMEOUT_MS=20000
API_SEND_TIMEOUT_MS=20000
ENABLE_LOGGING=true
ENABLE_SSL_PINNING=false
SESSION_TIMEOUT_MINUTES=15
SYNC_INTERVAL_SECONDS=60
SYNC_MAX_RETRY=5
PO_ELECTION_API_BASE_URL=http://10.115.197.192/POElectionAPI
OLIN_API_BASE_URL=http://10.115.197.192/OLINAPI
SURVEY_API_BASE_URL=http://10.115.197.192/POElectionAPI/api
SURVEY_WEB_BASE_URL=http://localhost:4200/
VOTER_SEARCH_PASS_KEY=test-pass
VOTER_SEARCH_AES_KEY=test-aes-key-32charsxxxxxxxxxxxx
CANDIDATE_EXPENDITURE_URL=http://10.115.197.192/CandidateExpenditure/Home.aspx
''',
    );
    final EnvironmentConfig config = EnvironmentConfig.load(Flavor.dev);
    expect(config.olinApiBaseUrl, contains('10.115.197.192'));
    expect(config.voterSearchPassKey, 'test-pass');
  });
}
