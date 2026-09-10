import 'dart:convert';

abstract final class JwtUtils {
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final List<String> parts = token.split('.');
      if (parts.length != 3) return null;
      final String normalized = base64Url.normalize(parts[1]);
      final Object? decoded = jsonDecode(
        utf8.decode(base64Url.decode(normalized)),
      );
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static String? sessionId(String token) {
    final Object? value = decodePayload(token)?['SessionId'];
    final String str = value?.toString().trim() ?? '';
    return str.isEmpty ? null : str;
  }
}
