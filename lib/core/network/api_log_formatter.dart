import 'dart:convert';

import 'package:dio/dio.dart';

/// Formats HTTP traffic for debug logs with redaction and size limits.
abstract final class ApiLogFormatter {
  static const int _maxBodyChars = 2048;

  static const Set<String> _redactedHeaderKeys = <String>{
    'authorization',
    'cookie',
    'set-cookie',
  };

  static const Set<String> _redactedBodyKeys = <String>{
    'password',
    'accesstoken',
    'access_token',
    'refreshtoken',
    'refresh_token',
    'token',
  };

  /// Builds a multi-line request log block.
  static String formatRequest(RequestOptions options) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('${options.method} ${options.uri}')
      ..writeln('headers: ${_encode(_redactHeaders(options.headers))}');

    final dynamic data = options.data;
    if (data != null) {
      buffer.writeln('body: ${_encodeBody(data)}');
    }

    final Map<String, dynamic> query = options.queryParameters;
    if (query.isNotEmpty) {
      buffer.writeln('query: ${_encode(_redactMap(query))}');
    }

    return buffer.toString().trimRight();
  }

  /// Builds a multi-line response log block including [statusCode].
  static String formatResponse(Response<dynamic> response) {
    final RequestOptions request = response.requestOptions;
    final StringBuffer buffer = StringBuffer()
      ..writeln('${request.method} ${request.uri}')
      ..writeln('status: ${response.statusCode}')
      ..writeln('body: ${_encodeBody(response.data)}');
    return buffer.toString().trimRight();
  }

  /// Builds a multi-line error log block when Dio throws.
  static String formatError(DioException error) {
    final RequestOptions request = error.requestOptions;
    final StringBuffer buffer = StringBuffer()
      ..writeln('${request.method} ${request.uri}')
      ..writeln('status: ${error.response?.statusCode ?? '—'}')
      ..writeln('type: ${error.type.name}')
      ..writeln('message: ${error.message ?? 'unknown'}');

    final dynamic body = error.response?.data;
    if (body != null) {
      buffer.writeln('body: ${_encodeBody(body)}');
    }

    return buffer.toString().trimRight();
  }

  static Map<String, dynamic> _redactHeaders(Map<String, dynamic> headers) {
    return headers.map(
      (String key, dynamic value) => MapEntry<String, dynamic>(
        key,
        _redactedHeaderKeys.contains(key.toLowerCase()) ? '***' : value,
      ),
    );
  }

  static Map<String, dynamic> _redactMap(Map<String, dynamic> input) {
    return input.map(
      (String key, dynamic value) => MapEntry<String, dynamic>(
        key,
        _redactedBodyKeys.contains(key.toLowerCase())
            ? '***'
            : _redactValue(value),
      ),
    );
  }

  static dynamic _redactValue(dynamic value) {
    if (value is Map) {
      return _redactMap(value.cast<String, dynamic>());
    }
    if (value is List) {
      return value.map(_redactValue).toList(growable: false);
    }
    return value;
  }

  static String _encodeBody(dynamic data) {
    if (data == null) return '<empty>';
    if (data is Map || data is List) {
      return _truncate(_encode(_redactValue(data)));
    }
    return _truncate(data.toString());
  }

  static String _encode(Object? value) {
    try {
      return jsonEncode(value);
    } on Object {
      return value.toString();
    }
  }

  static String _truncate(String value) {
    if (value.length <= _maxBodyChars) return value;
    return '${value.substring(0, _maxBodyChars)}… [truncated]';
  }
}
