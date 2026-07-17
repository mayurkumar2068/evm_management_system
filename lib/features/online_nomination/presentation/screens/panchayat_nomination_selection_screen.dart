import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/features/online_nomination/presentation/models/nomination_models.dart';
import 'package:evm_management_system/features/online_nomination/presentation/widgets/online_nomination_widgets.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

class PanchayatNominationSelectionScreen extends StatelessWidget {
  const PanchayatNominationSelectionScreen({super.key});

  void _openWorkflow(NominationPostType postType) {
    Get.toNamed<void>(
      AppRoute.nominationWorkflow.path,
      arguments: NominationFlowArgs(
        electionType: NominationElectionType.panchayat,
        postType: postType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NominationScreenShell(
      body: Column(
        children: <Widget>[
          AppTopBar(
            title: LocaleKeys.nominationPanchayatSelectTitle.tr(),
            onBack: () => Get.back<void>(),
          ),
          Expanded(
            child: NominationPostSelectionBody(
              subtitle: LocaleKeys.nominationPanchayatSelectSubtitle.tr(),
              posts:
                  <
                    ({
                      String title,
                      String subtitle,
                      IconData icon,
                      VoidCallback onTap,
                    })
                  >[
                    (
                      title: LocaleKeys.nominationDistrictPanchayatMember.tr(),
                      subtitle: LocaleKeys.nominationApplyOnline.tr(),
                      icon: Icons.groups_2_outlined,
                      onTap: () => _openWorkflow(
                        NominationPostType.districtPanchayatMember,
                      ),
                    ),
                    (
                      title: LocaleKeys.nominationJanpadPanchayatMember.tr(),
                      subtitle: LocaleKeys.nominationApplyOnline.tr(),
                      icon: Icons.location_city_rounded,
                      onTap: () => _openWorkflow(
                        NominationPostType.janpadPanchayatMember,
                      ),
                    ),
                    (
                      title: LocaleKeys.nominationSarpanch.tr(),
                      subtitle: LocaleKeys.nominationApplyOnline.tr(),
                      icon: Icons.account_balance_outlined,
                      onTap: () => _openWorkflow(NominationPostType.sarpanch),
                    ),
                  ],
            ),
          ),
        ],
      ),
    );
  }
}
