import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/features/dashboard/presentation/widgets/dashboard_brand.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

class DashboardSectionHeader extends StatelessWidget {
  const DashboardSectionHeader({
    required this.title,
    this.onViewAll,
    super.key,
  });

  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DashboardGap.page),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              textAlign: onViewAll == null ? TextAlign.center : TextAlign.start,
              style: AppTextStyles.titleMedium.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: AppRadius.brSm,
                ),
                child: Row(
                  children: <Widget>[
                    Text(
                      LocaleKeys.dashboardViewAll.tr().replaceAll(' →', ''),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.primaryDark,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
