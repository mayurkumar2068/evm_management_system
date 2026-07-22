import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

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
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: context.appOutline),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const BrandLogo(width: 44),
          ),
          const SizedBox(width: 12),
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
                    color: context.appMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  LocaleKeys.nominationTitle.tr(),
                  style: AppTextStyles.variant(
                    AppTextStyles.titleMedium,
                    color: context.appOnSurface,
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
      color: context.appSurface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.appSurface,
            border: Border.all(color: context.appOutline),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: context.isAppDark
                    ? Colors.black.withValues(alpha: 0.35)
                    : AppColors.cardShadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: context.appOnSurface, size: 20),
        ),
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
        color: context.appChip,
        borderRadius: AppRadius.brXl,
        padding: const EdgeInsets.all(AppSpacing.xl),
        border: Border.all(color: context.appOutline),
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: context.isAppDark ? 0.18 : 0.12,
                ),
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
                color: context.appMuted,
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
      border: Border.all(color: context.appOutline),
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
                    color: context.appOnSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                AppSpacing.vGapXs,
                Text(
                  subtitle,
                  style: AppTextStyles.variant(
                    AppTextStyles.bodyMedium,
                    color: context.appMuted,
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
        color: AppColors.primary.withValues(
          alpha: context.isAppDark ? 0.16 : 0.1,
        ),
        borderRadius: AppRadius.brMd,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        LocaleKeys.nominationSubtitle.tr(),
        style: AppTextStyles.variant(
          AppTextStyles.bodyMedium,
          color: context.isAppDark
              ? AppColors.primaryBright
              : AppColors.primaryDeep,
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
          style: AppTextStyles.bodyMedium.copyWith(color: context.appMuted),
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
