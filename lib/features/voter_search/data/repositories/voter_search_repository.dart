import 'package:evm_management_system/features/voter_search/data/datasources/voter_search_remote_datasource.dart';
import 'package:evm_management_system/features/voter_search/data/models/voter_search_models.dart';

/// Repository facade over [VoterSearchRemoteDatasource].
class VoterSearchRepository {
  VoterSearchRepository(this._remote);

  final VoterSearchRemoteDatasource _remote;

  Future<List<VoterDistrict>> fetchDistricts() => _remote.fetchDistricts();

  Future<List<VoterBlock>> fetchBlocks(String districtId) =>
      _remote.fetchBlocks(districtId);

  Future<List<VoterUrbanBody>> fetchUrbanBodies(String districtId) =>
      _remote.fetchUrbanBodies(districtId);

  Future<List<VoterElector>> searchElectors(ElectorSearchQuery query) =>
      _remote.searchElectors(query);

  Future<List<VoterElector>> searchElectorsByEpic(
    ElectorEpicSearchQuery query,
  ) => _remote.searchElectorsByEpic(query);

  Future<String?> fetchPhoto({
    required String distNo,
    required String electorId,
  }) => _remote.fetchPhoto(distNo: distNo, electorId: electorId);
}
