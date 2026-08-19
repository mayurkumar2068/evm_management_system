import 'package:evm_management_system/shared/design_system/tokens/app_colors.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_text_styles.dart';
import 'package:flutter/material.dart';

enum StatusTone { success, error, info, warning }

class AppStatusBanner extends StatelessWidget {
  const AppStatusBanner({
    required this.message,
    this.tone = StatusTone.info,
    this.icon,
    super.key,
  });

  final String message;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color border, Color text) = switch (tone) {
      StatusTone.success => (
        AppColors.green.withValues(alpha: 0.10),
        AppColors.green.withValues(alpha: 0.25),
        AppColors.greenDark,
      ),
      StatusTone.error => (
        AppColors.error.withValues(alpha: 0.08),
        AppColors.error.withValues(alpha: 0.25),
        AppColors.error,
      ),
      StatusTone.info => (
        AppColors.primary.withValues(alpha: 0.08),
        AppColors.primary.withValues(alpha: 0.22),
        AppColors.primaryDark,
      ),
      StatusTone.warning => (
        AppColors.saffron.withValues(alpha: 0.10),
        AppColors.saffron.withValues(alpha: 0.30),
        const Color(0xFFB45309),
      ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: <Widget>[
          if (icon != null) ...[
            Icon(icon, size: 18, color: text),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(
                color: text,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
