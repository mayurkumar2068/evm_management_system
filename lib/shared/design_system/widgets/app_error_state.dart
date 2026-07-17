import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/error/failure.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_colors.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_icons.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_spacing.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_text_styles.dart';
import 'package:evm_management_system/shared/design_system/widgets/app_button.dart';
import 'package:flutter/material.dart';

/// Renders a [Failure] as a localized, retryable error view.
class AppErrorState extends StatelessWidget {
  const AppErrorState({required this.failure, this.onRetry, super.key});

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.page,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(AppIcons.error, size: 64, color: AppColors.error),
            AppSpacing.vGapMd,
            Text(
              failure.localizationKey.tr(),
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...<Widget>[
              AppSpacing.vGapLg,
              AppButton(
                label: LocaleKeys.commonRetry.tr(),
                onPressed: onRetry,
                expanded: false,
                variant: AppButtonVariant.outline,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
