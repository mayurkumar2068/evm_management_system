import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/design_system/mpsec/mpsec_design_system.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Offline usage tips for field officers.
class OfflineTipsCard extends StatelessWidget {
  const OfflineTipsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> tips = <String>[
      LocaleKeys.offlineHubTipGps.tr(),
      LocaleKeys.offlineHubTipUninstall.tr(),
      LocaleKeys.offlineHubTipEncrypted.tr(),
      LocaleKeys.offlineHubTipAutoSync.tr(),
    ];

    return MpSecEnterpriseCard(
      title: LocaleKeys.offlineHubTips.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final String tip in tips) ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 18,
                  color: MpSecTokens.softBlueDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tip,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.slate600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            if (tip != tips.last) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}
