import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/design_system/mpsec/mpsec_design_system.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Hero illustration for the offline hub screen.
class OfflineIllustration extends StatelessWidget {
  const OfflineIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: <Color>[
            MpSecTokens.softBlue.withValues(alpha: 0.15),
            MpSecTokens.purpleAccent.withValues(alpha: 0.12),
          ],
        ),
      ),
      child: const Icon(
        Icons.cloud_off_rounded,
        size: 72,
        color: MpSecTokens.softBlueDark,
      ),
    );
  }
}

/// Connection and storage summary card.
class OfflineStatusCard extends StatelessWidget {
  const OfflineStatusCard({
    required this.connectionLabel,
    required this.pendingRecords,
    required this.lastSync,
    required this.storageUsedMb,
    super.key,
  });

  final String connectionLabel;
  final int pendingRecords;
  final String lastSync;
  final double storageUsedMb;

  @override
  Widget build(BuildContext context) {
    return MpSecEnterpriseCard(
      child: Column(
        children: <Widget>[
          _Row(
            label: LocaleKeys.offlineHubConnection.tr(),
            value: connectionLabel,
            valueColor: AppColors.warning,
          ),
          Divider(height: 28, color: context.appDivider),
          _Row(
            label: LocaleKeys.offlineHubRecordsWaiting.tr(),
            value: '$pendingRecords',
          ),
          Divider(height: 28, color: context.appDivider),
          _Row(label: LocaleKeys.offlineHubLastSync.tr(), value: lastSync),
          Divider(height: 28, color: context.appDivider),
          _Row(
            label: LocaleKeys.offlineHubStorageUsed.tr(),
            value: LocaleKeys.offlineHubStorageMb.tr(
              args: <String>[storageUsedMb.toStringAsFixed(0)],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

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
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            color: valueColor ?? context.appOnSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
