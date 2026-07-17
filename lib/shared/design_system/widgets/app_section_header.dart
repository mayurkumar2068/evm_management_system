import 'package:evm_management_system/shared/design_system/tokens/app_colors.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_text_styles.dart';
import 'package:flutter/material.dart';

/// A section title row with an optional trailing action (text or widget),
/// used to head content groups on dashboards and lists.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    required this.title,
    this.trailingLabel,
    this.onTrailingTap,
    this.trailing,
    super.key,
  });

  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          title,
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.slate700,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (trailing != null)
          trailing!
        else if (trailingLabel != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(
              trailingLabel!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
