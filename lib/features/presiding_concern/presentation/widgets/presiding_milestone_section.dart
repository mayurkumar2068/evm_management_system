import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/design_system/mpsec/mpsec_design_system.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Numbered section card with milestone rows for the presiding dashboard.
class PresidingMilestoneSectionCard extends StatelessWidget {
  const PresidingMilestoneSectionCard({
    required this.index,
    required this.title,
    required this.milestones,
    required this.onMilestoneTap,
    super.key,
  });

  final int index;
  final String title;
  final List<PresidingMilestone> milestones;
  final Future<void> Function(PresidingMilestone milestone) onMilestoneTap;

  @override
  Widget build(BuildContext context) {
    return MpSecEnterpriseCard(
      title: '$index. $title',
      child: Column(
        children: <Widget>[
          for (int i = 0; i < milestones.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 24, color: AppColors.slate100),
            PresidingMilestoneRow(
              milestone: milestones[i],
              onTap: () => onMilestoneTap(milestones[i]),
            ),
          ],
        ],
      ),
    );
  }
}

/// Single milestone row with label and status chip.
class PresidingMilestoneRow extends StatelessWidget {
  const PresidingMilestoneRow({
    required this.milestone,
    required this.onTap,
    super.key,
  });

  final PresidingMilestone milestone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String label = milestone.labelKey.tr();
    if (milestone.isCompleted && milestone.completedAt != null) {
      final String timestamp = DateFormat(
        'dd-MMM-yyyy HH:mm:ss',
      ).format(milestone.completedAt!.toLocal());
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.slate700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          MpSecStatusChip(
            label: timestamp,
            variant: MpSecChipVariant.completed,
          ),
        ],
      );
    }

    final MpSecChipVariant variant =
        milestone.sectionId == PresidingSectionIds.postPoll &&
            milestone.id == PresidingMilestoneIds.pollEnd
        ? MpSecChipVariant.completed
        : MpSecChipVariant.action;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.slate700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        MpSecStatusChip(
          label: LocaleKeys.presidingMarkComplete.tr(),
          variant: variant,
          onTap: onTap,
        ),
      ],
    );
  }
}
