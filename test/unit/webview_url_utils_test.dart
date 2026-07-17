import 'package:evm_management_system/core/webview/url/webview_url_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeWebViewLaunchUrl', () {
    test('adds trailing slash before query on bare origin', () {
      expect(
        normalizeWebViewLaunchUrl('http://localhost:4200?lang=hi'),
        'http://localhost:4200/?lang=hi',
      );
    });

    test('keeps existing path segments', () {
      expect(
        normalizeWebViewLaunchUrl('http://localhost:4200/location?lang=hi'),
        'http://localhost:4200/location?lang=hi',
      );
    });
  });

  group('appendWebViewLang', () {
    test('normalizes origin and appends lang only', () {
      expect(
        appendWebViewLang('http://localhost:4200', lang: 'hi'),
        'http://localhost:4200/?lang=hi',
      );
    });
  });
}
