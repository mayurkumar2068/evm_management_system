import 'package:evm_management_system/shared/design_system/tokens/app_colors.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_radius.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// Standard white surface container with the signature soft blue shadow and
/// 20px radius used throughout the EVM design system.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = AppSpacing.card,
    this.color,
    this.borderRadius = AppRadius.brLg,
    this.border,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final BorderRadius borderRadius;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final surface = color ?? Theme.of(context).colorScheme.surface;

    return Material(
      color: surface,
      borderRadius: borderRadius,
      child: Ink(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: borderRadius,
          border: border,
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
