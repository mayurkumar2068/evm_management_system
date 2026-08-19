import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/features/dashboard/presentation/models/dashboard_models.dart';
import 'package:evm_management_system/features/dashboard/presentation/widgets/dashboard_brand.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

class DashboardCategoryToggle extends StatelessWidget {
  const DashboardCategoryToggle({
    required this.active,
    required this.onChanged,
    super.key,
  });

  final DashboardCategory active;
  final ValueChanged<DashboardCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DashboardGap.page),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.appChip,
          borderRadius: AppRadius.brPill,
          border: Border.all(color: context.appOutline),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _ToggleOption(
                label: LocaleKeys.dashboardVoterServices.tr(),
                selected: active == DashboardCategory.voterServices,
                onTap: () => onChanged(DashboardCategory.voterServices),
              ),
            ),
            Expanded(
              child: _ToggleOption(
                label: LocaleKeys.dashboardAboutElections.tr(),
                selected: active == DashboardCategory.aboutElections,
                onTap: () => onChanged(DashboardCategory.aboutElections),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : Colors.transparent,
          borderRadius: AppRadius.brPill,
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            color: selected ? Colors.white : context.appOnSurface,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
