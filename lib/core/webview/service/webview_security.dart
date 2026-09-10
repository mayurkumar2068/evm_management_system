import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../config/webview_config.dart';
import 'webview_logger.dart';

class WebViewSecurity {
  WebViewSecurity({
    required this.serverTrustPolicy,
    required this.pinnedSha256,
    required this.logger,
    this.allowCleartextLocalhost = true,
  });

  final Set<String> pinnedSha256;
  final WebViewServerTrustPolicy serverTrustPolicy;
  final bool allowCleartextLocalhost;
  final WebViewLogger logger;

  static const Set<String> _devHosts = <String>{
    'localhost',
    '127.0.0.1',
    '10.0.2.2',
    '10.115.197.192',
  };

  bool _isDevHost(String? host) {
    if (host == null) return false;
    final String normalized = host.toLowerCase();
    if (_devHosts.contains(normalized)) return true;

    return normalized.startsWith('10.');
  }

  Future<ServerTrustAuthResponse> decide(
    URLAuthenticationChallenge challenge,
  ) async {
    final URLProtectionSpace space = challenge.protectionSpace;
    final String host = space.host;

    if (allowCleartextLocalhost && _isDevHost(host)) {
      logger.logSslDecision(
        host: host,
        action: 'proceed',
        reason: 'localhost_exception',
        sslError: space.sslError,
      );
      return _proceed();
    }

    if (pinnedSha256.isNotEmpty) {
      final String? fp = _leafFingerprint(space);
      if (fp != null && pinnedSha256.contains(fp)) {
        logger.logSslDecision(
          host: host,
          action: 'proceed',
          reason: 'certificate_pin_match',
          sslError: space.sslError,
        );
        return _proceed();
      }
      logger.logSslDecision(
        host: host,
        action: 'cancel',
        reason: 'certificate_pin_mismatch',
        sslError: space.sslError,
      );
      return _cancel();
    }

    if (serverTrustPolicy == WebViewServerTrustPolicy.strict &&
        space.sslError != null) {
      logger.logSslDecision(
        host: host,
        action: 'cancel',
        reason: 'strict_mode_ssl_error',
        sslError: space.sslError,
      );
      return _cancel();
    }

    logger.logSslDecision(
      host: host,
      action: 'proceed',
      reason: space.sslError == null
          ? 'platform_trust_challenge'
          : 'compatibility_mode_ssl_error',
      sslError: space.sslError,
    );
    return _proceed();
  }

  String? _leafFingerprint(URLProtectionSpace space) {
    try {
      final dynamic der = space.sslCertificate?.x509Certificate;
      if (der is List<int>) {
        return base64.encode(sha256.convert(der).bytes);
      }
    } catch (_) {}
    return null;
  }

  ServerTrustAuthResponse _proceed() {
    return ServerTrustAuthResponse(
      action: ServerTrustAuthResponseAction.PROCEED,
    );
  }

  ServerTrustAuthResponse _cancel() {
    return ServerTrustAuthResponse(
      action: ServerTrustAuthResponseAction.CANCEL,
    );
  }
}
