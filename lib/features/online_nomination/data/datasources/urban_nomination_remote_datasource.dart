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
  }) => _getList(
    OlinEndpoints.getUtbanBody,
    UrbanBodyDto.fromJson,
    query: <String, dynamic>{'postId': postId, 'dstId': dstId},
  );

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

  Future<List<T>> _getList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        path,
        queryParameters: query,
        options: Options(headers: <String, dynamic>{'Accept': 'application/json'}),
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

  static String _messageFromBody(Object? data) {
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return 'Request failed.';
  }
}

class UrbanMasterApiException implements Exception {
  UrbanMasterApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
