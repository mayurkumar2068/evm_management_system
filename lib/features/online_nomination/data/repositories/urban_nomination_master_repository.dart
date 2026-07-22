import 'package:evm_management_system/features/online_nomination/data/datasources/urban_nomination_remote_datasource.dart';
import 'package:evm_management_system/features/online_nomination/data/models/urban_master_dtos.dart';
import 'package:evm_management_system/features/online_nomination/presentation/models/nomination_models.dart';

/// Maps OLINAPI urban master responses into UI option items / post types.
class UrbanNominationMasterRepository {
  UrbanNominationMasterRepository(this._remote);

  final UrbanNominationRemoteDatasource _remote;

  Future<List<NominationOptionItem>> fetchElections() async {
    final List<ElectionUrbanDto> rows = await _remote.getElections();
    return rows
        .where((ElectionUrbanDto e) => e.electionId > 0 && e.ename.isNotEmpty)
        .map(
          (ElectionUrbanDto e) => NominationOptionItem.api(
            id: '${e.electionId}',
            label: e.ename,
          ),
        )
        .toList(growable: false);
  }

  Future<List<PostUrbanDto>> fetchPosts(int electionId) =>
      _remote.getPosts(electionId);

  Future<List<NominationOptionItem>> fetchDistricts({
    required int electionId,
    required int postId,
  }) async {
    final List<DistrictUrbanDto> rows = await _remote.getDistricts(
      electionId: electionId,
      postId: postId,
    );
    return rows
        .where((DistrictUrbanDto d) => d.dstId.isNotEmpty)
        .map(
          (DistrictUrbanDto d) => NominationOptionItem.api(
            id: d.dstId,
            label: d.dstName.isNotEmpty ? d.dstName : d.dstId,
          ),
        )
        .toList(growable: false);
  }

  Future<List<UrbanBodyDto>> fetchUrbanBodies({
    required int postId,
    required String dstId,
    required NominationPostType postType,
  }) async {
    if (postType == NominationPostType.adhyaksh ||
        postType == NominationPostType.mahapaur) {
      try {
        final List<UrbanBodyDto> president = await _remote.getUbPresident(
          dstId: dstId,
          postId: '$postId',
        );
        if (president.isNotEmpty) return president;
      } catch (_) {
        // Fall through to general urban-body list.
      }
    }
    return _remote.getUrbanBodies(postId: postId, dstId: dstId);
  }

  Future<List<NominationOptionItem>> fetchUrbanBodyOptions({
    required int postId,
    required String dstId,
    required NominationPostType postType,
  }) async {
    final List<UrbanBodyDto> rows = await fetchUrbanBodies(
      postId: postId,
      dstId: dstId,
      postType: postType,
    );
    return rows
        .where((UrbanBodyDto b) => b.ubId.isNotEmpty)
        .map(
          (UrbanBodyDto b) => NominationOptionItem.api(
            id: b.ubId,
            label: b.ubName.isNotEmpty ? b.ubName : b.ubId,
            meta: <String, String>{'typeId': '${b.typeId}'},
          ),
        )
        .toList(growable: false);
  }

  Future<List<NominationOptionItem>> fetchWards({
    required int postId,
    required String dstId,
    required String ubId,
  }) async {
    final List<UrbanWardDto> rows = await _remote.getWards(
      postId: postId,
      dstId: dstId,
      ubId: ubId,
    );
    final List<UrbanWardDto> sorted = List<UrbanWardDto>.from(rows)
      ..sort((UrbanWardDto a, UrbanWardDto b) => a.wardNo.compareTo(b.wardNo));
    return sorted
        .where((UrbanWardDto w) => w.wardId.isNotEmpty)
        .map(
          (UrbanWardDto w) => NominationOptionItem.api(
            id: w.wardId,
            label: w.wardNo > 0 ? '${w.wardNo}' : w.wardId,
            meta: <String, String>{'wardNo': '${w.wardNo}'},
          ),
        )
        .toList(growable: false);
  }

  /// Maps API post display name → existing cascade rules enum.
  static NominationPostType mapPostType(String postName) {
    final String n = postName.toLowerCase().trim();
    if (n.contains('mayor') ||
        n.contains('mahapaur') ||
        n.contains('महापौर') ||
        n.contains('nigam')) {
      return NominationPostType.mahapaur;
    }
    if (n.contains('president') ||
        n.contains('chair') ||
        n.contains('adhyaksh') ||
        n.contains('अध्यक्ष') ||
        n.contains('palika')) {
      return NominationPostType.adhyaksh;
    }
    if (n.contains('councillor') ||
        n.contains('councilor') ||
        n.contains('parshad') ||
        n.contains('पार्षद') ||
        n.contains('ward') ||
        n.contains('member')) {
      return NominationPostType.parshad;
    }
    // Default: body required, ward optional (president/chair style).
    return NominationPostType.adhyaksh;
  }
}
