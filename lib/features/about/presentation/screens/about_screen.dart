import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// About — application identity and version metadata.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: <Widget>[
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(LocaleKeys.appName.tr(), style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(LocaleKeys.appTagline.tr(), style: AppTextStyles.bodyMedium),
              const Divider(height: AppSpacing.xl),
              Text(
                LocaleKeys.appVersion.tr(args: ['1']),
                style: AppTextStyles.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
