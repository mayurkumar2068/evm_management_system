import 'package:evm_management_system/shared/design_system/tokens/app_colors.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_radius.dart';
import 'package:flutter/material.dart';

/// Small rounded-square icon affordance used in light top bars (filter,
/// download, etc.). Shared so the same chrome isn't re-declared per screen.
class AppSquareIconButton extends StatelessWidget {
  const AppSquareIconButton({
    required this.icon,
    this.onTap,
    this.size = 38,
    this.iconSize = 16,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final Widget box = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.slate200),
      ),
      child: Icon(icon, size: iconSize, color: AppColors.slate600),
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.brMd,
      child: InkWell(onTap: onTap, borderRadius: AppRadius.brMd, child: box),
    );
  }
}
