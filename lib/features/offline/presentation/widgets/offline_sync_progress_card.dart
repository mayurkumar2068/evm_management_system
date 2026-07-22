import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/design_system/mpsec/mpsec_design_system.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Pending sync queue breakdown by media type.
class OfflineSyncProgressCard extends StatelessWidget {
  const OfflineSyncProgressCard({
    required this.pendingSurveys,
    required this.pendingImages,
    required this.pendingVideos,
    required this.pendingGps,
    required this.pendingSignatures,
    super.key,
  });

  final int pendingSurveys;
  final int pendingImages;
  final int pendingVideos;
  final int pendingGps;
  final int pendingSignatures;

  @override
  Widget build(BuildContext context) {
    return MpSecEnterpriseCard(
      title: LocaleKeys.offlineHubSyncProgress.tr(),
      child: Column(
        children: <Widget>[
          _ProgressRow(
            label: LocaleKeys.offlineHubPendingSurveys.tr(),
            count: pendingSurveys,
          ),
          const SizedBox(height: 12),
          _ProgressRow(
            label: LocaleKeys.offlineHubPendingImages.tr(),
            count: pendingImages,
          ),
          const SizedBox(height: 12),
          _ProgressRow(
            label: LocaleKeys.offlineHubPendingVideos.tr(),
            count: pendingVideos,
          ),
          const SizedBox(height: 12),
          _ProgressRow(
            label: LocaleKeys.offlineHubPendingGps.tr(),
            count: pendingGps,
          ),
          const SizedBox(height: 12),
          _ProgressRow(
            label: LocaleKeys.offlineHubPendingSignatures.tr(),
            count: pendingSignatures,
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: context.appMuted),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: context.isAppDark
                ? AppColors.primary.withValues(alpha: 0.18)
                : MpSecTokens.purpleSurface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            '$count',
            style: AppTextStyles.titleSmall.copyWith(
              color: MpSecTokens.purpleAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
