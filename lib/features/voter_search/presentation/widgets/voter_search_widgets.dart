import 'package:easy_localization/easy_localization.dart';
import 'package:MPSECNET/localization/locale_keys.dart';
import 'package:MPSECNET/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

class VoterSearchInstructionCard extends StatelessWidget {
  const VoterSearchInstructionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              width: 5,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.md),
                  bottomLeft: Radius.circular(AppRadius.md),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      LocaleKeys.voterSearchEngineTitle.tr(),
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.appOnSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      LocaleKeys.voterSearchInstruction.tr(),
                      style: AppTextStyles.caption.copyWith(
                        color: context.appMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VoterAreaTypeRadioRow extends StatelessWidget {
  const VoterAreaTypeRadioRow({
    required this.isUrban,
    required this.onChanged,
    super.key,
  });

  final bool isUrban;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          LocaleKeys.voterSearchUrbanRural.tr(),
          style: AppTextStyles.label.copyWith(
            color: context.appMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: _AreaChip(
                label: LocaleKeys.voterSearchUrban.tr(),
                selected: isUrban,
                icon: Icons.location_city_rounded,
                onTap: () => onChanged(true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AreaChip(
                label: LocaleKeys.voterSearchRural.tr(),
                selected: !isUrban,
                icon: Icons.agriculture_rounded,
                onTap: () => onChanged(false),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AreaChip extends StatelessWidget {
  const _AreaChip({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isAppDark;
    final Color selectedBg = isDark
        ? AppColors.primary.withValues(alpha: 0.22)
        : AppColors.primary.withValues(alpha: 0.12);
    final Color unselectedBg = isDark ? AppColors.darkSurface : AppColors.slate50;
    final Color borderColor = selected
        ? AppColors.primary
        : (isDark ? AppColors.darkOutline : AppColors.slate200);
    final Color textColor = selected
        ? (isDark ? AppColors.primaryBright : AppColors.primary)
        : (isDark ? AppColors.darkTextPrimary : AppColors.slate700);
    final Color iconColor = selected
        ? (isDark ? AppColors.primaryBright : AppColors.primary)
        : (isDark ? AppColors.darkTextSecondary : AppColors.slate500);
    final Color radioColor = selected
        ? (isDark ? AppColors.primaryBright : AppColors.primary)
        : (isDark ? AppColors.darkOutline : AppColors.slate400);

    return Material(
      color: selected ? selectedBg : unselectedBg,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: Container(
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            border: Border.all(
              color: borderColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 18,
                color: iconColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 18,
                color: radioColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
