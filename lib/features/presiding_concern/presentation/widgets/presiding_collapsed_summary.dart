import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

class PresidingCollapsedSummary extends StatelessWidget {
  const PresidingCollapsedSummary({
    required this.title,
    required this.record,
    required this.onTap,
    this.locked = false,
    super.key,
  });

  final String title;
  final TurnoutRecord? record;
  final VoidCallback? onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final bool saved = record?.savedAt != null;
    final int total =
        (record?.male ?? 0) +
        (record?.female ?? 0) +
        (record?.thirdGender ?? 0);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Opacity(
        opacity: locked ? 0.55 : 1,
        child: Row(
          children: <Widget>[
            Icon(
              locked
                  ? Icons.lock_rounded
                  : saved
                      ? Icons.check_circle_rounded
                      : Icons.pending_actions_rounded,
              color: locked
                  ? AppColors.slate400
                  : saved
                      ? AppColors.success
                      : AppColors.slate400,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (saved)
                    Text(
                      record!.queueCount != null
                          ? LocaleKeys.presidingQueueSummary.tr(
                              args: <String>['${record!.queueCount}'],
                            )
                          : LocaleKeys.presidingTotalVotesSummary.tr(
                              args: <String>['$total'],
                            ),
                      style: AppTextStyles.caption,
                    ),
                ],
              ),
            ),
            Icon(
              locked
                  ? Icons.lock_outline_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppColors.slate400,
            ),
          ],
        ),
      ),
    );
  }
}
