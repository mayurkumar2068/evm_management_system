import 'dart:convert';

/// Minimal, dependency-free JWT payload reader.
///
/// Only decodes the middle (payload) segment to read claims — it does
/// **not** verify the signature. Only use this to read claims off a token
/// the app already received from a trusted server response (e.g. to echo
/// a claim back on logout); never to authenticate or trust an incoming
/// token.
abstract final class JwtUtils {
  /// Decodes the JWT payload segment into a claims map, or `null` when the
  /// token is malformed / not a JWT.
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final List<String> parts = token.split('.');
      if (parts.length != 3) return null;
      final String normalized = base64Url.normalize(parts[1]);
      final Object? decoded = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// Reads the `SessionId` claim — the PO Election API's concurrent-login
  /// guard is keyed by this, not just the user id, so `po-logout` needs it
  /// to release the correct session lock.
  static String? sessionId(String token) {
    final Object? value = decodePayload(token)?['SessionId'];
    final String str = value?.toString().trim() ?? '';
    return str.isEmpty ? null : str;
  }
}
