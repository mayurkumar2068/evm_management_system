import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/features/online_nomination/presentation/widgets/nomination_theme.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

class NominationTimelineTile extends StatelessWidget {
  const NominationTimelineTile({
    required this.index,
    required this.label,
    required this.timestamp,
    required this.status,
    required this.isLast,
    this.officer,
    this.remarks,
    super.key,
  });

  final int index;
  final String label;
  final String timestamp;
  final String status;
  final bool isLast;
  final String? officer;
  final String? remarks;

  @override
  Widget build(BuildContext context) {
    final bool isDone = status == LocaleKeys.nominationStatusDone.tr();
    final bool isInProgress =
        status == LocaleKeys.nominationStatusInProgress.tr();

    final Decoration nodeDecoration = isDone
        ? NominationTheme.gradientCircle()
        : BoxDecoration(
            color: isInProgress ? AppColors.warning : AppColors.slate300,
            shape: BoxShape.circle,
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          children: <Widget>[
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: nodeDecoration,
              child: isDone
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text(
                      '${index + 1}',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
            ),
            if (!isLast)
              Container(width: 2, height: 56, color: AppColors.slate200),
          ],
        ),
        AppSpacing.gapSm,
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.brMd,
              border: Border.all(color: AppColors.slate200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        label,
                        style: AppTextStyles.variant(
                          AppTextStyles.bodyMedium,
                          color: AppColors.slate900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _StatusBadge(
                      status: status,
                      isDone: isDone,
                      isInProgress: isInProgress,
                    ),
                  ],
                ),
                AppSpacing.vGapXs,
                Text(
                  timestamp,
                  style: AppTextStyles.variant(
                    AppTextStyles.caption,
                    color: AppColors.slate500,
                  ),
                ),
                if (officer != null) ...<Widget>[
                  AppSpacing.vGapXs,
                  Text(
                    '${LocaleKeys.nominationTimelineOfficer.tr()}: $officer',
                    style: AppTextStyles.variant(
                      AppTextStyles.caption,
                      color: AppColors.slate600,
                    ),
                  ),
                ],
                if (remarks != null) ...<Widget>[
                  AppSpacing.vGapXs,
                  Text(
                    '${LocaleKeys.nominationTimelineRemarks.tr()}: $remarks',
                    style: AppTextStyles.variant(
                      AppTextStyles.caption,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.isDone,
    required this.isInProgress,
  });

  final String status;
  final bool isDone;
  final bool isInProgress;

  @override
  Widget build(BuildContext context) {
    if (isDone) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: NominationTheme.gradientPill(),
        child: Text(
          status,
          style: AppTextStyles.variant(
            AppTextStyles.caption,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isInProgress ? AppColors.warningSurface : AppColors.slate100,
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        status,
        style: AppTextStyles.variant(
          AppTextStyles.caption,
          color: isInProgress ? AppColors.warning : AppColors.slate500,
          fontWeight: FontWeight.w700,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}
