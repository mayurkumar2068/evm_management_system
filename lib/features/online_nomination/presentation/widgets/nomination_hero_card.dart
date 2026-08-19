import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/features/online_nomination/presentation/widgets/nomination_theme.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

class NominationHeroCard extends StatelessWidget {
  const NominationHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.35),
        borderRadius: AppRadius.brXl,
        border: Border.all(color: AppColors.slate200),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Positioned(
                  right: 36,
                  top: 8,
                  child: Icon(
                    Icons.verified_user_rounded,
                    size: 36,
                    color: AppColors.green.withValues(alpha: 0.35),
                  ),
                ),
                Positioned(
                  left: 28,
                  bottom: 12,
                  child: Icon(
                    Icons.description_outlined,
                    size: 32,
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.brLg,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.laptop_mac_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          NominationGradientText(
            LocaleKeys.nominationTitle.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          AppSpacing.vGapXs,
          Text(
            LocaleKeys.nominationTagline.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.variant(
              AppTextStyles.bodyMedium,
              color: AppColors.slate600,
            ),
          ),
        ],
      ),
    );
  }
}
