import 'package:evm_management_system/core/webview/config/webview_config.dart';
import 'package:evm_management_system/core/webview/service/webview_logger.dart';
import 'package:evm_management_system/core/webview/service/webview_navigation_policy.dart';
import 'package:evm_management_system/core/webview/service/webview_security.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit coverage for reusable WebView navigation and SSL decisions.
void main() {
  group('WebViewNavigationPolicy', () {
    /// Returns a new policy for each test.
    WebViewNavigationPolicy createPolicy() {
      return const WebViewNavigationPolicy();
    }

    test('allows normal https pages', () {
      final WebNavigationDecision decision = createPolicy().decide(
        Uri.parse('https://google.com/search?q=evm'),
      );

      expect(decision.action, WebNavDecision.allow);
      expect(decision.reason, 'web_navigation');
    });

    test('opens supported external schemes outside the webview', () {
      final WebNavigationDecision decision = createPolicy().decide(
        Uri.parse('mailto:test@example.com'),
      );

      expect(decision.action, WebNavDecision.external);
      expect(decision.reason, 'supported_external_scheme');
    });

    test('opens geo and map app schemes externally', () {
      expect(
        createPolicy().decide(Uri.parse('geo:22.7,75.8')).action,
        WebNavDecision.external,
      );
      expect(
        createPolicy().decide(Uri.parse('comgooglemaps://?daddr=22.7,75.8')).action,
        WebNavDecision.external,
      );
    });

    test('opens google maps web urls externally', () {
      final WebNavigationDecision decision = createPolicy().decide(
        Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=22.7,75.8',
        ),
      );

      expect(decision.action, WebNavDecision.external);
      expect(decision.reason, 'external_map_url');
    });

    test('blocks unsupported custom schemes', () {
      final WebNavigationDecision decision = createPolicy().decide(
        Uri.parse('customapp://launch'),
      );

      expect(decision.action, WebNavDecision.block);
      expect(decision.reason, 'unsupported_custom_scheme');
    });
  });

  group('WebViewSecurity', () {
    /// Creates a trust challenge for the supplied host.
    ServerTrustChallenge createChallenge(String host, {SslError? sslError}) {
      return ServerTrustChallenge(
        protectionSpace: URLProtectionSpace(host: host, sslError: sslError),
      );
    }

    test('compatibility mode proceeds for challenged certificates', () async {
      final WebViewSecurity security = WebViewSecurity(
        serverTrustPolicy: WebViewServerTrustPolicy.compatibility,
        pinnedSha256: const <String>{},
        logger: const WebViewLogger(),
      );

      final ServerTrustAuthResponse response = await security.decide(
        createChallenge('mpsecerms.mp.gov.in'),
      );

      expect(response.action, ServerTrustAuthResponseAction.PROCEED);
    });

    test(
      'strict mode cancels challenged certificates with ssl errors',
      () async {
        final WebViewSecurity security = WebViewSecurity(
          serverTrustPolicy: WebViewServerTrustPolicy.strict,
          pinnedSha256: const <String>{},
          logger: const WebViewLogger(),
        );

        final ServerTrustAuthResponse response = await security.decide(
          createChallenge(
            'secure.example.com',
            sslError: SslError(
              code: SslErrorType.UNSPECIFIED,
              message: 'invalid chain',
            ),
          ),
        );

        expect(response.action, ServerTrustAuthResponseAction.CANCEL);
      },
    );
  });
}
