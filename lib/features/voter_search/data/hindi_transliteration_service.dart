import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// English → Hindi transliteration via Google Input Tools (same as SEC portal).
///
/// Converts Latin words to Devanagari. Failures are silent — original text kept.
class HindiTransliterationService {
  HindiTransliterationService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 4),
                receiveTimeout: const Duration(seconds: 4),
                sendTimeout: const Duration(seconds: 4),
                responseType: ResponseType.plain,
              ),
            );

  final Dio _dio;
  final Map<String, String> _cache = <String, String>{};

  static final RegExp _latinWord = RegExp(r'[A-Za-z]');

  /// Transliterates Latin tokens in [text]; Devanagari/other stays unchanged.
  ///
  /// Multi-word input keeps spaces: `mayur bobade` → `मयूर बोबाडे`.
  Future<String> transliterateText(String text) async {
    if (text.trim().isEmpty) return text;

    final String leading = RegExp(r'^\s*').firstMatch(text)?.group(0) ?? '';
    final String trailing = RegExp(r'\s*$').firstMatch(text)?.group(0) ?? '';
    final List<String> words = text.trim().split(RegExp(r'\s+'));
    final List<String> converted = <String>[];

    for (final String word in words) {
      if (word.isEmpty) continue;
      if (!_latinWord.hasMatch(word)) {
        converted.add(word);
        continue;
      }
      converted.add(await transliterateWord(word));
    }

    return '$leading${converted.join(' ')}$trailing';
  }

  Future<String> transliterateWord(String word) async {
    final String key = word.toLowerCase();
    final String? cached = _cache[key];
    if (cached != null) return _preserveCaseShape(word, cached);

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        'https://inputtools.google.com/request',
        queryParameters: <String, dynamic>{
          'text': word,
          'itc': 'hi-t-i0-und',
          'num': 1,
          'cp': 0,
          'cs': 1,
          'ie': 'utf-8',
          'oe': 'utf-8',
          'app': 'mpsecnet',
        },
      );
      final String? hindi = _parseFirstCandidate(response.data);
      if (hindi == null || hindi.isEmpty) return word;
      _cache[key] = hindi;
      return hindi;
    } catch (e) {
      debugPrint('[Transliterate] fail wordLen=${word.length} err=$e');
      return word;
    }
  }

  String? _parseFirstCandidate(Object? raw) {
    try {
      final dynamic decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! List || decoded.isEmpty) return null;
      if (decoded.first.toString() != 'SUCCESS') return null;
      if (decoded.length < 2 || decoded[1] is! List) return null;
      final List<dynamic> payload = decoded[1] as List<dynamic>;
      if (payload.isEmpty || payload.first is! List) return null;
      final List<dynamic> row = payload.first as List<dynamic>;
      if (row.length < 2 || row[1] is! List) return null;
      final List<dynamic> candidates = row[1] as List<dynamic>;
      if (candidates.isEmpty) return null;
      return candidates.first.toString();
    } catch (_) {
      return null;
    }
  }

  String _preserveCaseShape(String original, String hindi) => hindi;
}
