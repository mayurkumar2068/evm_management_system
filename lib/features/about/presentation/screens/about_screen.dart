import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/app_build_info.dart';
import 'package:evm_management_system/core/legal/privacy_policy.dart';
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
                LocaleKeys.appVersion.tr(
                  args: <String>[AppBuildInfo.versionWithBuild],
                ),
                style: AppTextStyles.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppBuildInfo.flavorLabel,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          onTap: () => PrivacyPolicy.open(context),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      LocaleKeys.legalPrivacyPolicy.tr(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      LocaleKeys.legalPrivacyPolicySub.tr(),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: context.appMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
