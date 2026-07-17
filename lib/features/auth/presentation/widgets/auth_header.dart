import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Branded header shown above the login form.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          height: 64,
          width: 64,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: AppRadius.brLg,
          ),
          child: const Icon(
            AppIcons.ballotUnit,
            color: AppColors.onPrimary,
            size: 34,
          ),
        ),
        AppSpacing.vGapLg,
        Text(
          LocaleKeys.authLoginTitle.tr(),
          style: AppTextStyles.headlineMedium,
        ),
        AppSpacing.vGapXs,
        Text(
          LocaleKeys.authLoginSubtitle.tr(),
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}
