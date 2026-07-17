import 'package:evm_management_system/design_system/mpsec/tokens/mpsec_tokens.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Pill-shaped status chip for timestamps or action states.
enum MpSecChipVariant { completed, action, disabled }

class MpSecStatusChip extends StatelessWidget {
  const MpSecStatusChip({
    required this.label,
    this.variant = MpSecChipVariant.action,
    this.onTap,
    super.key,
  });

  final String label;
  final MpSecChipVariant variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    switch (variant) {
      case MpSecChipVariant.completed:
        background = AppColors.slate200;
        foreground = AppColors.slate700;
      case MpSecChipVariant.action:
        background = AppColors.warning;
        foreground = Colors.white;
      case MpSecChipVariant.disabled:
        background = AppColors.warningSurface;
        foreground = AppColors.slate500;
    }

    final Widget chip = Container(
      constraints: const BoxConstraints(minHeight: MpSecTokens.touchTarget / 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTextStyles.caption.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );

    if (onTap == null || variant == MpSecChipVariant.completed) {
      return chip;
    }

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: chip,
        ),
      ),
    );
  }
}
