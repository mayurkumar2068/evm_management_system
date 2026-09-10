import 'package:evm_management_system/core/legal/privacy_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('privacy policy URL is the official MPSEC statement', () {
    expect(
      PrivacyPolicy.defaultUrl,
      'https://mplocalelection.mp.gov.in/privacystatement.aspx',
    );
    expect(PrivacyPolicy.resolveUri().isAbsolute, isTrue);
    expect(PrivacyPolicy.resolveUri().scheme, 'https');
    expect(PrivacyPolicy.resolveUri().host, 'mplocalelection.mp.gov.in');
    expect(PrivacyPolicy.resolveUri().path, '/privacystatement.aspx');
  });
}
