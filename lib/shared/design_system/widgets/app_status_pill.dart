import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_colors.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_radius.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Small rounded status badge with a leading dot, mirroring the design's
/// device-status pills (registered / pending / in transit / defective).
class AppStatusPill extends StatelessWidget {
  const AppStatusPill({required this.status, super.key});

  /// Raw status key, e.g. `registered`, `pending`, `in_transit`, `defective`.
  final String status;

  ({String label, Color bg, Color fg}) _config() => switch (status) {
    'registered' => (
      label: LocaleKeys.statsRegistered.tr(),
      bg: AppColors.successSurface,
      fg: const Color(0xFF16A34A),
    ),
    'pending' => (
      label: LocaleKeys.statsPending.tr(),
      bg: AppColors.warningSurface,
      fg: const Color(0xFFB45309),
    ),
    'in_transit' => (
      label: LocaleKeys.statsInTransit.tr(),
      bg: AppColors.infoSurface,
      fg: const Color(0xFF1D4ED8),
    ),
    'defective' => (
      label: LocaleKeys.statsDefective.tr(),
      bg: AppColors.errorSurface,
      fg: const Color(0xFFDC2626),
    ),
    _ => (label: status, bg: AppColors.slate100, fg: AppColors.slate600),
  };

  @override
  Widget build(BuildContext context) {
    final ({String label, Color bg, Color fg}) c = _config();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: c.bg, borderRadius: AppRadius.brPill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c.fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            c.label,
            style: AppTextStyles.caption.copyWith(
              color: c.fg,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
