import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/features/online_nomination/data/models/urban_master_dtos.dart';
import 'package:evm_management_system/features/online_nomination/data/repositories/urban_nomination_master_repository.dart';
import 'package:evm_management_system/features/online_nomination/presentation/models/nomination_models.dart';
import 'package:evm_management_system/features/online_nomination/presentation/widgets/online_nomination_widgets.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Same themed card UI as before — election then posts loaded from OLINAPI.
class UrbanNominationSelectionScreen extends StatefulWidget {
  const UrbanNominationSelectionScreen({super.key});

  @override
  State<UrbanNominationSelectionScreen> createState() =>
      _UrbanNominationSelectionScreenState();
}

class _UrbanNominationSelectionScreenState
    extends State<UrbanNominationSelectionScreen> {
  final RxList<NominationOptionItem> _elections = <NominationOptionItem>[].obs;
  final RxList<PostUrbanDto> _posts = <PostUrbanDto>[].obs;
  final RxnString _selectedElectionId = RxnString();
  final RxBool _loadingElections = true.obs;
  final RxBool _loadingPosts = false.obs;
  final RxnString _error = RxnString();

  UrbanNominationMasterRepository get _repo =>
      AppServices.urbanNominationMasters;

  @override
  void initState() {
    super.initState();
    _loadElections();
  }

  Future<void> _loadElections() async {
    _loadingElections.value = true;
    _error.value = null;
    _posts.clear();
    _selectedElectionId.value = null;
    try {
      final List<NominationOptionItem> rows = await _repo.fetchElections();
      _elections.assignAll(rows);
      // Single election → skip picker, load posts (same UX as old direct post list).
      if (rows.length == 1) {
        await _selectElection(rows.first);
      }
    } catch (e) {
      _error.value = e.toString();
      _elections.clear();
    } finally {
      _loadingElections.value = false;
    }
  }

  Future<void> _selectElection(NominationOptionItem election) async {
    _selectedElectionId.value = election.id;
    _posts.clear();
    final int? id = int.tryParse(election.id);
    if (id == null || id <= 0) return;

    _loadingPosts.value = true;
    _error.value = null;
    try {
      final List<PostUrbanDto> rows = await _repo.fetchPosts(id);
      _posts.assignAll(
        rows.where((PostUrbanDto p) => p.postId > 0 && p.postName.isNotEmpty),
      );
    } catch (e) {
      _error.value = e.toString();
      _posts.clear();
    } finally {
      _loadingPosts.value = false;
    }
  }

  void _clearElection() {
    _selectedElectionId.value = null;
    _posts.clear();
    _error.value = null;
  }

  void _openWorkflow(PostUrbanDto post) {
    final String? electionIdRaw = _selectedElectionId.value;
    final int? parsedElectionId = int.tryParse(electionIdRaw ?? '');
    if (parsedElectionId == null || parsedElectionId <= 0) return;

    String? electionName;
    for (final NominationOptionItem e in _elections) {
      if (e.id == electionIdRaw) {
        electionName = e.label;
        break;
      }
    }

    Get.toNamed<void>(
      AppRoute.nominationWorkflow.path,
      arguments: NominationFlowArgs(
        electionType: NominationElectionType.urban,
        postType: UrbanNominationMasterRepository.mapPostType(post.postName),
        urbanElectionId: parsedElectionId,
        urbanElectionName: electionName,
        urbanPostId: post.postId,
        urbanPostName: post.postName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NominationScreenShell(
      body: Column(
        children: <Widget>[
          AppTopBar(
            title: LocaleKeys.nominationUrbanSelectTitle.tr(),
            onBack: () {
              if (_selectedElectionId.value != null && _elections.length > 1) {
                _clearElection();
                return;
              }
              Get.back<void>();
            },
          ),
          Expanded(
            child: Obx(() {
              if (_loadingElections.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_error.value != null && _elections.isEmpty) {
                return _ErrorState(
                  message: _error.value!,
                  onRetry: _loadElections,
                );
              }

              // Same card list UI as before — pick election first when multiple.
              if (_selectedElectionId.value == null) {
                return NominationPostSelectionBody(
                  subtitle: LocaleKeys.nominationSelectElectionHint.tr(),
                  posts: <
                    ({
                      String title,
                      String subtitle,
                      IconData icon,
                      VoidCallback onTap,
                    })
                  >[
                    for (final NominationOptionItem election in _elections)
                      (
                        title: election.label,
                        subtitle: LocaleKeys.nominationFieldElection.tr(),
                        icon: Icons.how_to_vote_outlined,
                        onTap: () => _selectElection(election),
                      ),
                  ],
                );
              }

              if (_loadingPosts.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_error.value != null && _posts.isEmpty) {
                return _ErrorState(
                  message: _error.value!,
                  onRetry: () {
                    final String? id = _selectedElectionId.value;
                    if (id == null) {
                      _loadElections();
                      return;
                    }
                    for (final NominationOptionItem e in _elections) {
                      if (e.id == id) {
                        _selectElection(e);
                        return;
                      }
                    }
                  },
                );
              }

              if (_posts.isEmpty) {
                return NominationPostSelectionBody(
                  subtitle: LocaleKeys.nominationNoPostsFound.tr(),
                  posts: const <
                    ({
                      String title,
                      String subtitle,
                      IconData icon,
                      VoidCallback onTap,
                    })
                  >[],
                );
              }

              // Original themed post cards — data from API.
              return NominationPostSelectionBody(
                subtitle: LocaleKeys.nominationUrbanSelectSubtitle.tr(),
                posts: <
                  ({
                    String title,
                    String subtitle,
                    IconData icon,
                    VoidCallback onTap,
                  })
                >[
                  for (final PostUrbanDto post in _posts)
                    (
                      title: post.postName,
                      subtitle: LocaleKeys.nominationApplyOnline.tr(),
                      icon: _iconForPost(post.postName),
                      onTap: () => _openWorkflow(post),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  IconData _iconForPost(String postName) {
    final NominationPostType type =
        UrbanNominationMasterRepository.mapPostType(postName);
    return switch (type) {
      NominationPostType.mahapaur => Icons.apartment_rounded,
      NominationPostType.adhyaksh => Icons.account_balance_rounded,
      NominationPostType.parshad => Icons.groups_2_outlined,
      _ => Icons.how_to_reg_rounded,
    };
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.page,
      children: <Widget>[
        Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
        ),
        AppSpacing.vGapMd,
        AppGradientButton(
          label: LocaleKeys.nominationActionRetry.tr(),
          onPressed: onRetry,
        ),
        AppSpacing.vGapLg,
        const NominationInfoNote(),
      ],
    );
  }
}
