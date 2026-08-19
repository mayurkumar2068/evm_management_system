import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/features/online_nomination/presentation/widgets/nomination_summary_row.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

class NominationReceiptCard extends StatelessWidget {
  const NominationReceiptCard({
    required this.applicationNumber,
    required this.electionType,
    required this.post,
    required this.submittedAt,
    super.key,
  });

  final String applicationNumber;
  final String electionType;
  final String post;
  final String submittedAt;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: AppRadius.brXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const BrandLogo(width: 40),
              AppSpacing.gapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      LocaleKeys.nominationDigitalReceipt.tr(),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.slate900,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      LocaleKeys.nominationReceiptSubtitle.tr(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 64,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: AppRadius.brSm,
                  border: Border.all(color: AppColors.slate200),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 36,
                  color: AppColors.slate400,
                ),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  children: <Widget>[
                    NominationSummaryRow(
                      label: LocaleKeys.nominationApplicationNumber.tr(),
                      value: applicationNumber,
                    ),
                    NominationSummaryRow(
                      label: LocaleKeys.nominationElectionType.tr(),
                      value: electionType,
                    ),
                    NominationSummaryRow(
                      label: LocaleKeys.nominationPost.tr(),
                      value: post,
                    ),
                    NominationSummaryRow(
                      label: LocaleKeys.nominationStatusSubmitted.tr(),
                      value: submittedAt,
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: AppRadius.brSm,
                border: Border.all(color: AppColors.slate200),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                size: 56,
                color: AppColors.slate700,
              ),
            ),
          ),
          AppSpacing.vGapSm,
          Center(
            child: Text(
              LocaleKeys.nominationStatusSubmitted.tr(),
              style: AppTextStyles.caption.copyWith(color: AppColors.slate500),
            ),
          ),
        ],
      ),
    );
  }
}
