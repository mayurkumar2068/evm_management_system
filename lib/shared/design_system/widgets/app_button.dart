import 'package:evm_management_system/shared/design_system/tokens/app_colors.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_radius.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_spacing.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_text_styles.dart';
import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, outline, text, danger }

/// The single button used across the app. Encapsulates variants, loading and
/// disabled states so no screen builds raw [ElevatedButton]s.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || isLoading;
    final Widget child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
            ),
          )
        : _content();

    final ButtonStyle style = _styleFor(variant);
    final Widget button = switch (variant) {
      AppButtonVariant.outline => OutlinedButton(
        onPressed: disabled ? null : onPressed,
        style: style,
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: disabled ? null : onPressed,
        style: style,
        child: child,
      ),
      _ => ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: style,
        child: child,
      ),
    };

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _content() {
    if (icon == null) return Text(label, style: AppTextStyles.button);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 20),
        AppSpacing.gapSm,
        Text(label, style: AppTextStyles.button),
      ],
    );
  }

  ButtonStyle _styleFor(AppButtonVariant variant) {
    const RoundedRectangleBorder shape = RoundedRectangleBorder(
      borderRadius: AppRadius.brMd,
    );
    const Size minSize = Size.fromHeight(52);
    return switch (variant) {
      AppButtonVariant.primary => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        minimumSize: minSize,
        shape: shape,
      ),
      AppButtonVariant.secondary => ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.onPrimary,
        minimumSize: minSize,
        shape: shape,
      ),
      AppButtonVariant.danger => ElevatedButton.styleFrom(
        backgroundColor: AppColors.error,
        foregroundColor: AppColors.onPrimary,
        minimumSize: minSize,
        shape: shape,
      ),
      AppButtonVariant.outline => OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: minSize,
        side: const BorderSide(color: AppColors.primary),
        shape: shape,
      ),
      AppButtonVariant.text => TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: minSize,
        shape: shape,
      ),
    };
  }
}
