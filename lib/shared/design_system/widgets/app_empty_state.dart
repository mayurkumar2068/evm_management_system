import 'package:evm_management_system/shared/design_system/tokens/app_colors.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_icons.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_spacing.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_text_styles.dart';
import 'package:evm_management_system/shared/design_system/widgets/app_button.dart';
import 'package:flutter/material.dart';

/// Friendly placeholder shown when a list or screen has no data.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.title,
    this.message,
    this.icon = AppIcons.empty,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.page,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 64, color: AppColors.textDisabled),
            AppSpacing.vGapMd,
            Text(
              title,
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...<Widget>[
              AppSpacing.vGapSm,
              Text(
                message!,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              AppSpacing.vGapLg,
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
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
