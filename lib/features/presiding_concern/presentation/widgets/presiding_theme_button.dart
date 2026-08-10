import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Presiding CTA using the shared app theme gradient (blue → mint).
class PresidingThemeButton extends StatelessWidget {
  const PresidingThemeButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 48,
    this.expanded = true,
    this.borderRadius = 14,
    this.outlined = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final bool expanded;
  final double borderRadius;

  /// When true, uses outline style (secondary actions like Back).
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || isLoading;
    final Widget content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            gradient: disabled || outlined
                ? null
                : AppGradients.primaryButton,
            color: disabled
                ? AppColors.slate200
                : outlined
                ? Colors.white
                : null,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: disabled
                  ? AppColors.slate300
                  : outlined
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.2),
              width: outlined ? 1.5 : 1,
            ),
            boxShadow: disabled || outlined
                ? null
                : <BoxShadow>[
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: outlined ? AppColors.primary : Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (icon != null) ...<Widget>[
                        Icon(
                          icon,
                          size: 18,
                          color: disabled
                              ? AppColors.slate500
                              : outlined
                              ? AppColors.primary
                              : Colors.white,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: disabled
                                ? AppColors.slate500
                                : outlined
                                ? AppColors.primary
                                : Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    if (!expanded) return content;
    return SizedBox(width: double.infinity, child: content);
  }
}
