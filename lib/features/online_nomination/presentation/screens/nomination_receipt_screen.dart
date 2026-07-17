import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/features/online_nomination/presentation/models/nomination_models.dart';
import 'package:evm_management_system/features/online_nomination/presentation/widgets/online_nomination_widgets.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

class NominationReceiptScreen extends StatelessWidget {
  const NominationReceiptScreen({required this.args, super.key});

  final NominationFlowArgs args;

  String get _applicationNumber =>
      args.applicationNumber ?? 'NOM/2026/IND/000123';

  String get _submittedAt {
    if (args.submittedAt != null) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(args.submittedAt!);
    }
    return '15 Jul 2026, 11:30 AM';
  }

  @override
  Widget build(BuildContext context) {
    return NominationScreenShell(
      body: Column(
        children: <Widget>[
          AppTopBar(
            title: LocaleKeys.nominationReceiptTitle.tr(),
            onBack: () => Get.back<void>(),
          ),
          Expanded(
            child: ListView(
              padding: AppSpacing.page,
              children: <Widget>[
                NominationReceiptCard(
                  applicationNumber: _applicationNumber,
                  electionType: args.electionType.labelKey.tr(),
                  post: args.postType.labelKey.tr(),
                  submittedAt: _submittedAt,
                ),
                AppSpacing.vGapLg,
                Row(
                  children: <Widget>[
                    Expanded(
                      child: NominationGovButton(
                        label: LocaleKeys.nominationShare.tr(),
                        outlined: true,
                        expanded: false,
                        icon: Icons.share_outlined,
                        onPressed: () {},
                      ),
                    ),
                    AppSpacing.gapSm,
                    Expanded(
                      child: NominationGovButton(
                        label: LocaleKeys.nominationPrint.tr(),
                        expanded: false,
                        icon: Icons.download_outlined,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
