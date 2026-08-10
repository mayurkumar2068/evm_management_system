import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:evm_management_system/features/voter_search/data/models/voter_search_models.dart';
import 'package:evm_management_system/features/voter_search/data/voter_search_crypto.dart';
import 'package:evm_management_system/features/voter_search/data/voter_search_endpoints.dart';
import 'package:flutter/foundation.dart';

/// Remote datasource for SECSearchAPI voter search.
///
/// - [PassKey] is AES-GCM encrypted short passkey (refreshed per request).
/// - [ReqData] stays plaintext (empty / district GUID / JSON) as required by API.
/// - Response [Data] is AES-GCM encrypted JSON (decrypted here).
class VoterSearchRemoteDatasource {
  VoterSearchRemoteDatasource({
    required Dio dio,
    required String passKey,
    required VoterSearchCrypto crypto,
  }) : _dio = dio,
       _passKey = passKey,
       _crypto = crypto;

  final Dio _dio;
  final String _passKey;
  final VoterSearchCrypto _crypto;

  Future<List<VoterDistrict>> fetchDistricts() async {
    final VoterSearchEnvelope envelope = await _post(
      VoterSearchEndpoints.districtList,
      reqData: '',
    );
    return _parseList(envelope, VoterDistrict.fromJson);
  }

  Future<List<VoterBlock>> fetchBlocks(String districtId) async {
    final VoterSearchEnvelope envelope = await _post(
      VoterSearchEndpoints.blockList,
      reqData: districtId,
    );
    return _parseList(envelope, VoterBlock.fromJson);
  }

  Future<List<VoterUrbanBody>> fetchUrbanBodies(String districtId) async {
    final VoterSearchEnvelope envelope = await _post(
      VoterSearchEndpoints.ubList,
      reqData: districtId,
    );
    return _parseList(envelope, VoterUrbanBody.fromJson);
  }

  Future<List<VoterElector>> searchElectors(ElectorSearchQuery query) async {
    final String reqData = jsonEncode(query.toJson());
    debugPrint(
      '[VoterSearchAPI] search-elector '
      'elecType=${query.elecType} distNo=${query.distNo} '
      'blockNo=${query.blockNo} ubNo=${query.ubNo} '
      'panchayatNo=${query.panchayatNo.isEmpty ? "(empty)" : query.panchayatNo} '
      'nameLen=${query.elecName.length} '
      'nameScript=${_nameScript(query.elecName)} '
      'relLen=${query.relName.length} '
      'age=${query.age.isEmpty ? "-" : query.age} '
      'gender=${query.gender.isEmpty ? "-" : query.gender} '
      'epic=${query.epicNo.isEmpty ? "-" : "set"}',
    );
    final VoterSearchEnvelope envelope = await _post(
      VoterSearchEndpoints.searchElector,
      reqData: reqData,
    );
    return _parseList(envelope, VoterElector.fromJson);
  }

  Future<List<VoterElector>> searchElectorsByEpic(
    ElectorEpicSearchQuery query,
  ) async {
    final String reqData = jsonEncode(query.toJson());
    debugPrint(
      '[VoterSearchAPI] search-elector-epic '
      'distNo=${query.distNo} epic=${query.epicNo}',
    );
    final VoterSearchEnvelope envelope = await _post(
      VoterSearchEndpoints.searchElectorEpic,
      reqData: reqData,
    );
    return _parseList(envelope, VoterElector.fromJson);
  }

  String _nameScript(String name) {
    if (name.trim().isEmpty) return 'empty';
    if (RegExp(r'[\u0900-\u097F]').hasMatch(name)) return 'hindi';
    if (RegExp(r'[A-Za-z]').hasMatch(name)) return 'latin';
    return 'other';
  }

  /// Fetches voter photo. Response shape (Postman / API doc):
  /// `{ "Status": true, "Data": "{\"photo\":\"/9j/...\"}" }`
  /// [Data] may be plaintext JSON or AES-encrypted; photo is JPEG base64.
  Future<String?> fetchPhoto({
    required String distNo,
    required String electorId,
  }) async {
    final Stopwatch sw = Stopwatch()..start();
    final String reqData = jsonEncode(<String, String>{
      'distNo': distNo,
      'ID': electorId,
    });
    try {
      final String encryptedPassKey = await _crypto.encrypt(_passKey);
      debugPrint(
        '[VoterSearchAPI] → POST ${VoterSearchEndpoints.photo} '
        'distNo=$distNo id=$electorId reqLen=${reqData.length}',
      );

      // Plain avoids Dio JSON transformer failing on large photo payloads.
      final Response<dynamic> response = await _dio.post<dynamic>(
        VoterSearchEndpoints.photo,
        data: VoterSearchRequest(
          reqData: reqData,
          passKey: encryptedPassKey,
        ).toJson(),
        options: Options(
          contentType: Headers.jsonContentType,
          responseType: ResponseType.plain,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 90),
          // Photo must be JSON 2xx — Dio's default validateStatus (<500)
          // treats 403 HTML gateway pages as success and breaks jsonDecode.
          validateStatus: (int? code) => code != null && code >= 200 && code < 300,
        ),
      );

      final Object? rawBody = response.data;
      if (rawBody is String) {
        final String trimmed = rawBody.trimLeft();
        if (trimmed.startsWith('<') || trimmed.toLowerCase().startsWith('<!doctype')) {
          debugPrint(
            '[VoterSearchAPI] ✕ photo html_body http=${response.statusCode} '
            'ms=${sw.elapsedMilliseconds}',
          );
          return null;
        }
      }

      final Map<String, dynamic> body = _asJsonMap(rawBody);
      final VoterSearchEnvelope raw = VoterSearchEnvelope.fromJson(body);
      debugPrint(
        '[VoterSearchAPI] ← ${VoterSearchEndpoints.photo} '
        'http=${response.statusCode} status=${raw.status} '
        'dataLen=${raw.data.length} ms=${sw.elapsedMilliseconds}',
      );

      if (!raw.status) {
        throw VoterSearchApiException(
          raw.message.isNotEmpty ? raw.message : 'Photo fetch failed',
        );
      }
      if (raw.data.trim().isEmpty) {
        debugPrint('[VoterSearchAPI] photo empty Data');
        return null;
      }

      final String? photo = await _resolvePhotoBase64(raw.data);
      debugPrint(
        '[VoterSearchAPI] photo extractedLen=${photo?.length ?? 0} '
        'ms=${sw.elapsedMilliseconds}',
      );
      return photo;
    } on VoterSearchApiException catch (e) {
      debugPrint('[VoterSearchAPI] Photo fetch failed: $e');
      return null;
    } on DioException catch (e) {
      debugPrint(
        '[VoterSearchAPI] ✕ photo dio=${e.type} '
        'http=${e.response?.statusCode} ms=${sw.elapsedMilliseconds}',
      );
      rethrow;
    } catch (e) {
      debugPrint(
        '[VoterSearchAPI] ✕ photo error=$e ms=${sw.elapsedMilliseconds}',
      );
      rethrow;
    }
  }

  /// Resolves photo [Data]: plaintext JSON, AES JSON, or AES raw JPEG bytes.
  Future<String?> _resolvePhotoBase64(String data) async {
    final String trimmed = data.trim();
    if (trimmed.isEmpty) return null;

    // 1) Plaintext JSON / already-decrypted string field.
    try {
      final String plain = await _crypto.decryptDataField(trimmed);
      final String? fromPlain = _extractPhotoBase64FromPlain(plain);
      if (fromPlain != null && fromPlain.isNotEmpty) {
        debugPrint(
          '[VoterSearchAPI] photo via decryptDataField '
          'plainLen=${plain.length} prefix=${plain.substring(0, plain.length.clamp(0, 24))}',
        );
        return fromPlain;
      }
    } catch (e) {
      debugPrint('[VoterSearchAPI] photo decryptDataField failed: $e');
    }

    // 2) AES → bytes (JSON UTF-8 or raw image).
    try {
      final Uint8List bytes = await _crypto.decryptToBytes(trimmed);
      if (_looksLikeImageBytes(bytes)) {
        debugPrint(
          '[VoterSearchAPI] photo via decryptToBytes image bytes=${bytes.length}',
        );
        return base64Encode(bytes);
      }
      final String asText = utf8.decode(bytes);
      final String? fromText = _extractPhotoBase64FromPlain(asText);
      if (fromText != null && fromText.isNotEmpty) {
        debugPrint(
          '[VoterSearchAPI] photo via decryptToBytes json len=${fromText.length}',
        );
        return fromText;
      }
    } catch (e) {
      debugPrint('[VoterSearchAPI] photo decryptToBytes failed: $e');
    }

    // 3) Data itself may be raw base64 JPEG.
    return _normalizeBase64(trimmed);
  }

  static bool _looksLikeImageBytes(Uint8List bytes) {
    if (bytes.length < 4) return false;
    // JPEG
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
    // PNG
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }
    // GIF
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) return true;
    // WEBP (RIFF....WEBP)
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }
    return false;
  }

  /// Normalizes Dio [ResponseType.plain] / json body into a map.
  static Map<String, dynamic> _asJsonMap(Object? raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is String) {
      final String trimmed = raw.trim();
      if (trimmed.isEmpty) {
        throw const VoterSearchApiException('Invalid response from server');
      }
      final Object? decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }
    throw const VoterSearchApiException('Invalid response from server');
  }

  /// Photo API [Data] may be JSON object OR a raw base64 image string.
  static String? _extractPhotoBase64FromPlain(String plain) {
    if (plain.isEmpty) return null;

    // JSON object / array — doc shape: {"photo":"..."}
    if (plain.startsWith('{') || plain.startsWith('[')) {
      try {
        final dynamic decoded = jsonDecode(plain);
        return _extractPhotoBase64(decoded);
      } catch (_) {
        // Fall through — treat as raw payload.
      }
    }

    // JSON-encoded string: "iVBORw0KGgo..."
    if (plain.startsWith('"') && plain.endsWith('"')) {
      try {
        final dynamic decoded = jsonDecode(plain);
        if (decoded is String) return _normalizeBase64(decoded);
      } catch (_) {}
    }

    return _normalizeBase64(plain);
  }

  /// Accepts map payloads (`photo` / `Photo` / …) or a raw base64 string.
  static String? _extractPhotoBase64(dynamic decoded) {
    if (decoded == null) return null;

    if (decoded is String) {
      return _normalizeBase64(decoded);
    }

    if (decoded is List && decoded.isNotEmpty) {
      return _extractPhotoBase64(decoded.first);
    }

    if (decoded is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(decoded);
      const List<String> keys = <String>[
        'photo',
        'Photo',
        'PHOTO',
        'photoBase64',
        'PhotoBase64',
        'image',
        'Image',
        'ImageData',
        'imageData',
        'data',
        'Data',
        'FileData',
        'fileData',
        'base64',
        'Base64',
      ];
      for (final String key in keys) {
        final Object? value = map[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          final String? normalized = _normalizeBase64(value.toString());
          if (normalized != null) return normalized;
        }
      }
      // Case-insensitive key scan.
      for (final MapEntry<String, dynamic> e in map.entries) {
        if (e.key.toLowerCase().contains('photo') ||
            e.key.toLowerCase().contains('image') ||
            e.key.toLowerCase().contains('base64')) {
          final String? normalized = _normalizeBase64(e.value.toString());
          if (normalized != null) return normalized;
        }
      }
      if (map.length == 1) {
        final Object? only = map.values.first;
        if (only != null && only.toString().trim().length > 64) {
          return _normalizeBase64(only.toString());
        }
      }
    }

    return null;
  }

  static String? _normalizeBase64(String raw) {
    String value = raw.trim();
    if (value.isEmpty) return null;
    if (value.startsWith('data:') && value.contains(',')) {
      value = value.split(',').last.trim();
    }
    value = value.replaceAll(RegExp(r'\s+'), '');
    if (value.length < 32) return null;
    final int mod = value.length % 4;
    if (mod > 0) {
      value = value.padRight(value.length + (4 - mod), '=');
    }
    return value;
  }

  Future<VoterSearchEnvelope> _post(
    String path, {
    required String reqData,
  }) async {
    final Stopwatch sw = Stopwatch()..start();
    try {
      final String encryptedPassKey = await _crypto.encrypt(_passKey);
      debugPrint(
        '[VoterSearchAPI] → POST $path '
        'reqLen=${reqData.length} encryptedPassKey=yes',
      );

      final Response<dynamic> response = await _dio.post<dynamic>(
        path,
        data: VoterSearchRequest(
          reqData: reqData,
          passKey: encryptedPassKey,
        ).toJson(),
        options: Options(
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      );

      final Object? body = response.data;
      if (body is! Map) {
        throw const VoterSearchApiException('Invalid response from server');
      }

      final VoterSearchEnvelope raw = VoterSearchEnvelope.fromJson(
        Map<String, dynamic>.from(body),
      );

      String plainData = '';
      if (raw.data.trim().isNotEmpty) {
        plainData = await _crypto.decryptDataField(raw.data);
      }

      final VoterSearchEnvelope envelope = VoterSearchEnvelope(
        status: raw.status,
        message: raw.message,
        data: plainData,
        pubKey: raw.pubKey,
      );

      final int? count = _countHint(plainData);
      debugPrint(
        '[VoterSearchAPI] ← $path '
        'http=${response.statusCode} status=${envelope.status} '
        'msg="${envelope.message}" dataLen=${plainData.length} '
        '${count != null ? 'items=$count ' : ''}'
        'ms=${sw.elapsedMilliseconds}',
      );

      if (!envelope.status) {
        throw VoterSearchApiException(
          envelope.message.isNotEmpty ? envelope.message : 'Request failed',
        );
      }
      return envelope;
    } on VoterSearchApiException {
      rethrow;
    } on DioException catch (e) {
      debugPrint(
        '[VoterSearchAPI] ✕ $path dio=${e.type} '
        'http=${e.response?.statusCode} ms=${sw.elapsedMilliseconds}',
      );
      throw VoterSearchApiException(
        e.message?.isNotEmpty == true
            ? e.message!
            : 'Network error. Please try again.',
      );
    } catch (e) {
      debugPrint(
        '[VoterSearchAPI] ✕ $path error=$e ms=${sw.elapsedMilliseconds}',
      );
      throw VoterSearchApiException(
        e is FormatException
            ? 'Unable to decrypt server response'
            : 'Request failed. Please try again.',
      );
    }
  }

  int? _countHint(String plainData) {
    final String t = plainData.trim();
    if (!t.startsWith('[')) return null;
    try {
      final dynamic decoded = jsonDecode(t);
      return decoded is List ? decoded.length : null;
    } catch (_) {
      return null;
    }
  }

  List<T> _parseList<T>(
    VoterSearchEnvelope envelope,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final dynamic decoded = envelope.decodeData();
    if (decoded == null) return <T>[];
    if (decoded is! List) {
      throw const VoterSearchApiException('Unexpected data format');
    }
    return decoded
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (Map<dynamic, dynamic> item) =>
              fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }
}

class VoterSearchApiException implements Exception {
  const VoterSearchApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
