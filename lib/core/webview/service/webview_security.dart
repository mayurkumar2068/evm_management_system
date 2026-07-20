import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../config/webview_config.dart';
import 'webview_logger.dart';

/// Server-trust / TLS policy for the engine.
///
/// `flutter_inappwebview` requires an explicit response whenever the native
/// layer surfaces a trust challenge. For high-compatibility portals we proceed
/// after logging the event, while still allowing an app-specific strict mode or
/// SHA-256 pinning to reject unexpected certificates.
class WebViewSecurity {
  /// Creates the WebView security policy.
  WebViewSecurity({
    required this.serverTrustPolicy,
    required this.pinnedSha256,
    required this.logger,
    this.allowCleartextLocalhost = true,
  });

  /// Optional set of base64 SHA-256 fingerprints of the leaf certificate's
  /// DER bytes. Empty = no pinning (rely on the OS trust store).
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

  /// Returns `true` when the host is a development-only loopback / LAN target.
  bool _isDevHost(String? host) {
    if (host == null) return false;
    final String normalized = host.toLowerCase();
    if (_devHosts.contains(normalized)) return true;
    // Allow other private LAN hosts used for internal staging IIS.
    return normalized.startsWith('10.');
  }

  /// Decide a server-trust challenge. Returns a PROCEED/CANCEL response.
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

  /// Returns the SHA-256 fingerprint of the leaf certificate, if available.
  String? _leafFingerprint(URLProtectionSpace space) {
    try {
      final dynamic der = space.sslCertificate?.x509Certificate;
      if (der is List<int>) {
        return base64.encode(sha256.convert(der).bytes);
      }
    } catch (_) {
      // Certificate bytes unavailable on this platform — skip pinning.
    }
    return null;
  }

  /// Builds a `PROCEED` trust response.
  ServerTrustAuthResponse _proceed() {
    return ServerTrustAuthResponse(
      action: ServerTrustAuthResponseAction.PROCEED,
    );
  }

  /// Builds a `CANCEL` trust response.
  ServerTrustAuthResponse _cancel() {
    return ServerTrustAuthResponse(
      action: ServerTrustAuthResponseAction.CANCEL,
    );
  }
}
