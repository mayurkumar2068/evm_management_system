import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

abstract final class CurlFormatter {
  static const Set<String> _redactHeaderKeys = <String>{
    'cookie',
    'set-cookie',
  };

  static String toCurl(RequestOptions options, {bool redactSensitive = false}) {
    final StringBuffer buffer = StringBuffer('curl -X ${options.method.toUpperCase()}');

    // Add URL (including query parameters)
    buffer.write(' "${options.uri.toString()}"');

    // Add Headers
    final Map<String, dynamic> headers = <String, dynamic>{
      ...options.headers,
    };

    if (options.contentType != null && !headers.containsKey(Headers.contentTypeHeader)) {
      headers[Headers.contentTypeHeader] = options.contentType;
    }

    for (final MapEntry<String, dynamic> entry in headers.entries) {
      final String key = entry.key;
      final dynamic rawVal = entry.value;
      if (rawVal == null) continue;

      final String val;
      if (redactSensitive && _redactHeaderKeys.contains(key.toLowerCase())) {
        val = '***';
      } else {
        val = rawVal.toString();
      }
      buffer.write(' -H "$key: $val"');
    }

    // Add Body
    final dynamic data = options.data;
    if (data != null) {
      if (data is FormData) {
        for (final MapEntry<String, String> field in data.fields) {
          buffer.write(' -F "${field.key}=${field.value}"');
        }
        for (final MapEntry<String, MultipartFile> file in data.files) {
          buffer.write(' -F "${file.key}=@${file.value.filename ?? 'file'}"');
        }
      } else {
        String bodyString;
        if (data is String) {
          bodyString = data;
        } else if (data is Map || data is List) {
          try {
            bodyString = jsonEncode(data);
          } catch (_) {
            bodyString = data.toString();
          }
        } else {
          bodyString = data.toString();
        }

        // Escape single quotes for bash curl: ' -> '\''
        final String escapedBody = bodyString.replaceAll("'", r"'\''");
        buffer.write(" -d '$escapedBody'");
      }
    }

    return buffer.toString();
  }

  static String get currentDeviceType {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return Platform.operatingSystem;
  }
}
