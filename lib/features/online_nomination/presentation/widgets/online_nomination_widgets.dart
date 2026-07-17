import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'nomination_components.dart';
import 'nomination_theme.dart';

export 'nomination_components.dart';
export 'nomination_screen_shell.dart';
export 'nomination_theme.dart';

class OnlineNominationHeader extends StatelessWidget {
  const OnlineNominationHeader({
    required this.onProfile,
    required this.onNotifications,
    super.key,
  });

  final VoidCallback onProfile;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        top + AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          const BrandLogo(width: 44),
          AppSpacing.gapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  LocaleKeys.nominationHeaderDepartment.tr(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.variant(
                    AppTextStyles.caption,
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  LocaleKeys.nominationTitle.tr(),
                  style: AppTextStyles.variant(
                    AppTextStyles.titleMedium,
                    color: AppColors.slate900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          NominationActionIconButton(
            icon: Icons.notifications_none_rounded,
            onTap: onNotifications,
          ),
          AppSpacing.gapXs,
          NominationActionIconButton(
            icon: Icons.account_circle_outlined,
            onTap: onProfile,
          ),
        ],
      ),
    );
  }
}

class NominationActionIconButton extends StatelessWidget {
  const NominationActionIconButton({
    required this.icon,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.slate700, size: 20),
        ),
      ),
    );
  }
}

class NominationBannerCard extends StatelessWidget {
  const NominationBannerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: AppRadius.brXl,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.greenExtraLight,
              borderRadius: AppRadius.brLg,
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              size: 36,
              color: AppColors.greenDark,
            ),
          ),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  LocaleKeys.nominationWelcomeTitle.tr(),
                  style: AppTextStyles.variant(
                    AppTextStyles.titleMedium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate900,
                  ),
                ),
                AppSpacing.vGapXs,
                Text(
                  LocaleKeys.nominationWelcomeSubtitle.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.slate600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NominationLargeOptionCard extends StatelessWidget {
  const NominationLargeOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.featured = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    if (featured) {
      return AppCard(
        onTap: onTap,
        borderRadius: AppRadius.brXl,
        padding: const EdgeInsets.all(AppSpacing.xl),
        border: Border.all(color: AppColors.slate200),
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.35),
                borderRadius: AppRadius.brLg,
              ),
              child: Icon(icon, size: 56, color: AppColors.primary),
            ),
            AppSpacing.vGapMd,
            NominationGradientText(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            AppSpacing.vGapXs,
            Text(
              subtitle,
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

    return AppCard(
      onTap: onTap,
      borderRadius: AppRadius.brXl,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: Border.all(color: AppColors.slate200),
      child: Row(
        children: <Widget>[
          NominationGradientIcon(icon: icon, size: 44, iconSize: 22),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTextStyles.variant(
                    AppTextStyles.titleSmall,
                    color: AppColors.slate900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                AppSpacing.vGapXs,
                Text(
                  subtitle,
                  style: AppTextStyles.variant(
                    AppTextStyles.bodyMedium,
                    color: AppColors.slate600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class NominationInfoNote extends StatelessWidget {
  const NominationInfoNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.4),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        LocaleKeys.nominationSubtitle.tr(),
        style: AppTextStyles.variant(
          AppTextStyles.bodyMedium,
          color: AppColors.primaryDeep,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Shared post-selection body for urban and panchayat screens.
class NominationPostSelectionBody extends StatelessWidget {
  const NominationPostSelectionBody({
    required this.subtitle,
    required this.posts,
    super.key,
  });

  final String subtitle;
  final List<
    ({String title, String subtitle, IconData icon, VoidCallback onTap})
  >
  posts;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.page,
      children: <Widget>[
        Text(
          subtitle,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.slate600),
        ),
        AppSpacing.vGapLg,
        for (final ({
              String title,
              String subtitle,
              IconData icon,
              VoidCallback onTap,
            })
            post
            in posts) ...<Widget>[
          NominationLargeOptionCard(
            title: post.title,
            subtitle: post.subtitle,
            icon: post.icon,
            onTap: post.onTap,
          ),
          AppSpacing.vGapMd,
        ],
        const NominationInfoNote(),
      ],
    );
  }
}

// Backward-compatible alias.
typedef NominationWorkflowStepper = NominationHorizontalStepper;
