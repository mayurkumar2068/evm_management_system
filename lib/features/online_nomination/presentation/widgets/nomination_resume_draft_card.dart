import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/features/online_nomination/data/models/nomination_draft.dart';
import 'package:evm_management_system/features/online_nomination/presentation/models/nomination_models.dart';
import 'package:evm_management_system/features/online_nomination/presentation/widgets/nomination_gov_button.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

class NominationResumeDraftCard extends StatelessWidget {
  const NominationResumeDraftCard({
    required this.draft,
    required this.onContinue,
    required this.onStartFresh,
    super.key,
  });

  final NominationDraft draft;
  final VoidCallback onContinue;
  final VoidCallback onStartFresh;

  @override
  Widget build(BuildContext context) {
    final String stepLabel = draft.stepLabelKeyFor(draft.currentStep).tr();
    final String postLabel = draft.postType.labelKey.tr();
    final String electionLabel = draft.electionType.labelKey.tr();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.25),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.restore_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              AppSpacing.gapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      LocaleKeys.nominationDraftResumeTitle.tr(),
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.slate900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppSpacing.vGapXs,
                    Text(
                      LocaleKeys.nominationDraftResumeSubtitle.tr(
                        namedArgs: <String, String>{
                          'step': stepLabel,
                          'post': postLabel,
                          'election': electionLabel,
                        },
                      ),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.slate600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,
          NominationGovButton(
            label: LocaleKeys.nominationDraftContinue.tr(),
            icon: Icons.play_arrow_rounded,
            onPressed: onContinue,
          ),
          AppSpacing.vGapSm,
          NominationGovButton(
            label: LocaleKeys.nominationDraftStartFresh.tr(),
            outlined: true,
            onPressed: onStartFresh,
          ),
        ],
      ),
    );
  }
}
