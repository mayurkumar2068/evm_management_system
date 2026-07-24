import 'package:dio/dio.dart';
import 'package:evm_management_system/core/network/api_endpoints.dart';
import 'package:evm_management_system/features/online_nomination/data/models/urban_master_dtos.dart';

/// Remote datasource for OLINAPI urban nomination master cascade.
class UrbanNominationRemoteDatasource {
  UrbanNominationRemoteDatasource(this._dio);

  final Dio _dio;

  Future<List<ElectionUrbanDto>> getElections() =>
      _getList(OlinEndpoints.getElectionUrban, ElectionUrbanDto.fromJson);

  Future<List<PostUrbanDto>> getPosts(int electionId) => _getList(
    OlinEndpoints.getPostUrban,
    PostUrbanDto.fromJson,
    query: <String, dynamic>{'electionId': electionId},
  );

  Future<List<DistrictUrbanDto>> getDistricts({
    required int electionId,
    required int postId,
  }) => _getList(
    OlinEndpoints.getDistrictUrban,
    DistrictUrbanDto.fromJson,
    query: <String, dynamic>{'electionId': electionId, 'postId': postId},
  );

  Future<List<UrbanBodyDto>> getUrbanBodies({
    required int postId,
    required String dstId,
    int? electionId,
  }) {
    final Map<String, dynamic> query = <String, dynamic>{
      'postId': postId,
      'dstId': dstId,
    };
    // Send electionId only when available; backend ignores if unsupported.
    if (electionId != null && electionId > 0) {
      query['electionId'] = electionId;
    }
    return _getList(
      OlinEndpoints.getUtbanBody,
      UrbanBodyDto.fromJson,
      query: query,
    );
  }

  /// Alternate body list for president-style posts.
  Future<List<UrbanBodyDto>> getUbPresident({
    required String dstId,
    required String postId,
  }) => _getList(
    OlinEndpoints.getUbPresident,
    UrbanBodyDto.fromJson,
    query: <String, dynamic>{'dstId': dstId, 'postId': postId},
  );

  Future<List<UrbanWardDto>> getWards({
    required int postId,
    required String dstId,
    required String ubId,
  }) => _getList(
    OlinEndpoints.getUrbanWard,
    UrbanWardDto.fromJson,
    query: <String, dynamic>{
      'postId': postId,
      'dstId': dstId,
      'ubId': ubId,
    },
  );

  Future<UrbanRegistrationResponse> insertUrbanRegistration(
    UrbanRegistrationRequest request,
  ) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        OlinEndpoints.insertUrbanReg,
        data: request.toJson(),
        options: Options(
          headers: <String, dynamic>{
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      final int? code = response.statusCode;
      if (code != null && code >= 400) {
        throw UrbanMasterApiException(_messageFromBody(response.data, code));
      }

      final Object? data = response.data;
      final Map<String, dynamic>? map = _asStringKeyedMap(data);
      if (map == null) {
        throw UrbanMasterApiException(
          'Unexpected registration response (${code ?? 'no status'}).',
        );
      }

      // Support both flat and { data: {...} } envelopes.
      final Map<String, dynamic> payload =
          _asStringKeyedMap(map['data']) ?? map;

      final UrbanRegistrationResponse parsed =
          UrbanRegistrationResponse.fromJson(payload);
      if (parsed.regID.isEmpty) {
        throw UrbanMasterApiException(
          _messageFromBody(payload, code) == 'Request failed.'
              ? 'Registration succeeded but regID missing in response.'
              : _messageFromBody(payload, code),
        );
      }
      return parsed;
    } on UrbanMasterApiException {
      rethrow;
    } on DioException catch (e) {
      final String fromBody = _messageFromBody(
        e.response?.data,
        e.response?.statusCode,
      );
      if (fromBody != 'Request failed.' &&
          !fromBody.startsWith('Request failed (HTTP')) {
        throw UrbanMasterApiException(fromBody);
      }
      final String? dioMsg = e.message?.trim();
      throw UrbanMasterApiException(
        (dioMsg != null && dioMsg.isNotEmpty)
            ? dioMsg
            : 'Unable to reach nomination registration API.',
      );
    }
  }

  Future<List<T>> _getList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        path,
        queryParameters: query,
        options: Options(
          headers: <String, dynamic>{'Accept': 'application/json'},
        ),
      );

      if (response.statusCode == 400) {
        throw UrbanMasterApiException(_messageFromBody(response.data));
      }
      if (response.statusCode != null &&
          response.statusCode! >= 400 &&
          response.statusCode! < 500) {
        throw UrbanMasterApiException(_messageFromBody(response.data));
      }

      final Object? data = response.data;
      if (data == null) return const [];
      if (data is! List) {
        throw UrbanMasterApiException('Unexpected response format.');
      }

      return data
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (Map<dynamic, dynamic> row) =>
                fromJson(Map<String, dynamic>.from(row)),
          )
          .toList(growable: false);
    } on UrbanMasterApiException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw UrbanMasterApiException(_messageFromBody(e.response?.data));
      }
      throw UrbanMasterApiException(
        e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Unable to reach nomination master API.',
      );
    }
  }

  static Map<String, dynamic>? _asStringKeyedMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map(
        (Object? key, Object? value) =>
            MapEntry<String, dynamic>(key.toString(), value),
      );
    }
    return null;
  }

  static String _messageFromBody(Object? data, [int? statusCode]) {
    if (data is String && data.trim().isNotEmpty) {
      final String trimmed = data.trim();
      // Avoid dumping huge HTML pages.
      if (trimmed.startsWith('<')) {
        return statusCode != null
            ? 'Request failed (HTTP $statusCode).'
            : 'Request failed.';
      }
      return trimmed.length > 240 ? '${trimmed.substring(0, 240)}…' : trimmed;
    }

    final Map<String, dynamic>? map = _asStringKeyedMap(data);
    if (map != null) {
      for (final String key in <String>[
        'message',
        'Message',
        'title',
        'Title',
        'error',
        'Error',
        'detail',
        'Detail',
      ]) {
        final Object? value = map[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }

      // ASP.NET validation: { "errors": { "Field": ["msg"] } }
      final Object? errors = map['errors'] ?? map['Errors'];
      if (errors is Map) {
        final List<String> parts = <String>[];
        errors.forEach((Object? key, Object? value) {
          if (value is List) {
            for (final Object? item in value) {
              if (item != null && item.toString().trim().isNotEmpty) {
                parts.add(item.toString().trim());
              }
            }
          } else if (value != null && value.toString().trim().isNotEmpty) {
            parts.add(value.toString().trim());
          }
        });
        if (parts.isNotEmpty) return parts.join(' ');
      }
    }

    return statusCode != null
        ? 'Request failed (HTTP $statusCode).'
        : 'Request failed.';
  }
}

class UrbanMasterApiException implements Exception {
  UrbanMasterApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
