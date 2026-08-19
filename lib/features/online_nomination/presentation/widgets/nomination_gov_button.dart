import 'package:evm_management_system/features/online_nomination/presentation/widgets/nomination_theme.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Primary action button with theme gradient for nomination flows.
class NominationGovButton extends StatelessWidget {
  const NominationGovButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.outlined = false,
    this.expanded = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      final Widget child = _labelRow(
        AppTextStyles.variant(AppTextStyles.button, color: AppColors.primary),
      );
      final Widget button = OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        ),
        child: child,
      );
      return expanded
          ? SizedBox(width: double.infinity, child: button)
          : button;
    }

    final Widget gradientButton = Opacity(
      opacity: onPressed == null ? 0.65 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.brMd,
          child: Ink(
            height: 52,
            decoration: BoxDecoration(
              gradient: NominationTheme.button,
              borderRadius: AppRadius.brMd,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: _labelRow(
                AppTextStyles.variant(
                  AppTextStyles.button,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return expanded
        ? SizedBox(width: double.infinity, child: gradientButton)
        : gradientButton;
  }

  Widget _labelRow(TextStyle style) {
    final Widget labelWidget = Text(
      label,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );

    if (icon == null) {
      return FittedBox(fit: BoxFit.scaleDown, child: labelWidget);
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 20, color: style.color),
          AppSpacing.gapSm,
          Text(
            label,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
