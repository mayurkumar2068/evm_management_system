import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';

final class PoApiLoggingInterceptor extends Interceptor {
  PoApiLoggingInterceptor({this.maxBodyChars = 8000});

  final int maxBodyChars;
  int _seq = 0;

  static const String _idKey = 'poApiLogId';
  static const Set<String> _redactKeys = <String>{
    'password',
    'accesstoken',
    'access_token',
    'refreshtoken',
    'refresh_token',
    'authorization',
    'token',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final int id = ++_seq;
    options.extra[_idKey] = id;
    final String body = options.data == null
        ? ''
        : '\n  body: ${_encode(options.data)}';
    final String query = options.queryParameters.isEmpty
        ? ''
        : '\n  query: ${_encode(options.queryParameters)}';
    AppLogger.w(
      '[PO API #$id] → ${options.method} ${_redactedUri(options.uri)}$query$body',
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final Object? id = response.requestOptions.extra[_idKey];
    final RequestOptions req = response.requestOptions;
    AppLogger.w(
      '[PO API #$id] ← ${response.statusCode} ${req.method} ${_redactedUri(req.uri)}\n'
      '  body: ${_encode(response.data)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final Object? id = err.requestOptions.extra[_idKey];
    final RequestOptions req = err.requestOptions;
    final Object? body = err.response?.data;
    AppLogger.w(
      '[PO API #$id] ✕ ${err.response?.statusCode ?? '—'} '
      '${req.method} ${_redactedUri(req.uri)}\n'
      '  type: ${err.type.name}\n'
      '  message: ${err.message ?? ''}'
      '${body == null ? '' : '\n  body: ${_encode(body)}'}',
    );
    handler.next(err);
  }

  String _redactedUri(Uri uri) {
    if (uri.queryParameters.isEmpty) return uri.toString();
    final Map<String, String> redacted = <String, String>{
      for (final MapEntry<String, String> entry in uri.queryParameters.entries)
        entry.key: _redactKeys.contains(entry.key.toLowerCase())
            ? 'REDACTED'
            : entry.value,
    };
    return uri.replace(queryParameters: redacted).toString();
  }

  String _encode(Object? data) {
    if (data == null) return '<empty>';
    try {
      final Object? redacted = _redact(data);
      final String text = redacted is String ? redacted : jsonEncode(redacted);
      if (text.length <= maxBodyChars) return text;
      return '${text.substring(0, maxBodyChars)}… [truncated ${text.length} chars]';
    } catch (_) {
      final String text = data.toString();
      if (text.length <= maxBodyChars) return text;
      return '${text.substring(0, maxBodyChars)}… [truncated]';
    }
  }

  Object? _redact(Object? value) {
    if (value is Map) {
      return value.map((Object? k, Object? v) {
        final String key = k.toString();
        if (_redactKeys.contains(key.toLowerCase())) {
          return MapEntry<Object?, Object?>(k, '***');
        }
        return MapEntry<Object?, Object?>(k, _redact(v));
      });
    }
    if (value is List) {
      return value.map(_redact).toList(growable: false);
    }
    return value;
  }
}
