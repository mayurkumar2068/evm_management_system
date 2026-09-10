import 'package:evm_management_system/core/offline/web_form_submission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web submission JSON never stores authToken', () {
    final WebFormSubmission submission = WebFormSubmission(
      clientId: 'c1',
      formType: 'survey',
      endpoint: '/survey/submit',
      payload: <String, dynamic>{'q': 1},
      authToken: 'secret-bearer',
      createdAt: DateTime.utc(2026, 9, 9),
    );

    final Map<String, dynamic> json = submission.toJson();
    expect(json.containsKey('authToken'), isFalse);

    final WebFormSubmission restored = WebFormSubmission.fromJson(
      <String, dynamic>{
        ...json,
        'authToken': 'should-be-ignored',
      },
    );
    expect(restored.authToken, isEmpty);
  });
}
