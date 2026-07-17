import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/features/online_nomination/presentation/models/nomination_models.dart';
import 'package:evm_management_system/features/online_nomination/presentation/widgets/online_nomination_widgets.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

class NominationTrackStatusScreen extends StatelessWidget {
  const NominationTrackStatusScreen({required this.args, super.key});

  final NominationFlowArgs args;

  String get _applicationNumber =>
      args.applicationNumber ?? 'NOM/2026/IND/000123';

  @override
  Widget build(BuildContext context) {
    final List<
      ({
        String label,
        String timestamp,
        String status,
        String? officer,
        String? remarks,
      })
    >
    timeline =
        <
          ({
            String label,
            String timestamp,
            String status,
            String? officer,
            String? remarks,
          })
        >[
          (
            label: LocaleKeys.nominationStatusSubmitted.tr(),
            timestamp: args.submittedAt != null
                ? DateFormat('dd MMM yyyy, hh:mm a').format(args.submittedAt!)
                : '15 Jul 2026, 11:30 AM',
            status: LocaleKeys.nominationStatusDone.tr(),
            officer: 'RO Office',
            remarks: LocaleKeys.nominationStatusReceived.tr(),
          ),
          (
            label: LocaleKeys.nominationStatusVerification.tr(),
            timestamp: '16 Jul 2026, 10:15 AM',
            status: LocaleKeys.nominationStatusInProgress.tr(),
            officer: 'Document Cell',
            remarks: LocaleKeys.nominationStatusInProgress.tr(),
          ),
          (
            label: LocaleKeys.nominationStatusScrutiny.tr(),
            timestamp: '17 Jul 2026, 10:30 AM',
            status: LocaleKeys.nominationStatusQueued.tr(),
            officer: 'Scrutiny Officer',
            remarks: LocaleKeys.nominationStatusPending.tr(),
          ),
          (
            label: LocaleKeys.nominationStatusFinalList.tr(),
            timestamp: '-',
            status: LocaleKeys.nominationStatusPending.tr(),
            officer: null,
            remarks: null,
          ),
        ];

    return NominationScreenShell(
      body: Column(
        children: <Widget>[
          AppTopBar(
            title: LocaleKeys.nominationTrackTitle.tr(),
            onBack: () => Get.back<void>(),
          ),
          Expanded(
            child: ListView(
              padding: AppSpacing.page,
              children: <Widget>[
                AppCard(
                  borderRadius: AppRadius.brXl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        LocaleKeys.nominationTrackSubtitle.tr(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.slate600,
                        ),
                      ),
                      AppSpacing.vGapMd,
                      Text(
                        '${LocaleKeys.nominationApplicationNumber.tr()}: $_applicationNumber',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.slate900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapLg,
                for (int i = 0; i < timeline.length; i++)
                  NominationTimelineTile(
                    index: i,
                    label: timeline[i].label,
                    timestamp: timeline[i].timestamp,
                    status: timeline[i].status,
                    officer: timeline[i].officer,
                    remarks: timeline[i].remarks,
                    isLast: i == timeline.length - 1,
                  ),
                AppSpacing.vGapLg,
                const NominationInfoNote(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
