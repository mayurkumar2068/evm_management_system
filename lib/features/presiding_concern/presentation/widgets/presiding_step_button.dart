import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Unified +/- step button used across presiding turnout UIs.
class PresidingStepButton extends StatelessWidget {
  const PresidingStepButton({
    required this.icon,
    required this.onPressed,
    this.enabled = true,
    this.color,
    this.size = 28,
    super.key,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = color ?? AppColors.slate700;
    final bool isDisabled = !enabled;

    if (color != null) {
      return Material(
        color: isDisabled
            ? effectiveColor.withValues(alpha: 0.35)
            : effectiveColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: Colors.white, size: size * 0.73),
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: isDisabled ? AppColors.slate100 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isDisabled ? AppColors.slate300 : AppColors.slate700,
            ),
          ),
        ),
      ),
    );
  }
}
