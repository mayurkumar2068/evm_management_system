/// Shared dev/LAN host detection. Used by [WebViewSecurity] (TLS-trust
/// exceptions) and [WebViewTrustedHosts] (navigation allowlist), and only
/// ever consulted by callers that have independently confirmed cleartext/dev
/// mode is allowed — never in production.
abstract final class WebViewDevHost {
  static const Set<String> _devHosts = <String>{
    'localhost',
    '127.0.0.1',
    '10.0.2.2',
  };

  static bool matches(String? host) {
    if (host == null) return false;
    final String normalized = host.toLowerCase();
    if (_devHosts.contains(normalized)) return true;
    // Emulator / private LAN ranges — only when cleartext localhost is
    // allowed (dev builds). Avoid hardcoding specific internal IPs.
    return normalized.startsWith('10.') ||
        normalized.startsWith('192.168.') ||
        normalized.startsWith('172.');
  }
}
