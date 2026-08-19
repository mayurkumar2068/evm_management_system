import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/features/online_nomination/presentation/widgets/nomination_theme.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

class NominationSuccessCard extends StatelessWidget {
  const NominationSuccessCard({
    required this.applicationNumber,
    required this.onCopy,
    this.submittedAt,
    this.userId,
    this.password,
    super.key,
  });

  final String applicationNumber;
  final VoidCallback onCopy;
  final DateTime? submittedAt;
  final String? userId;
  final String? password;

  String get _formattedDate {
    if (submittedAt != null) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(submittedAt!);
    }
    return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Stack(
          alignment: Alignment.center,
          children: <Widget>[
            ..._confettiDots(),
            Container(
              width: 96,
              height: 96,
              decoration: NominationTheme.gradientCircle(),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
          ],
        ),
        AppSpacing.vGapMd,
        NominationGradientText(
          LocaleKeys.nominationSuccessTitle.tr(),
          textAlign: TextAlign.center,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        AppSpacing.vGapXs,
        Text(
          LocaleKeys.nominationSuccessSubtitle.tr(),
          textAlign: TextAlign.center,
          style: AppTextStyles.variant(
            AppTextStyles.bodyMedium,
            color: AppColors.slate600,
          ),
        ),
        AppSpacing.vGapLg,
        AppCard(
          borderRadius: AppRadius.brXl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                LocaleKeys.nominationApplicationNumber.tr(),
                style: AppTextStyles.variant(
                  AppTextStyles.label,
                  color: AppColors.slate500,
                ),
              ),
              AppSpacing.vGapSm,
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.infoSurface,
                  borderRadius: AppRadius.brMd,
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        applicationNumber,
                        style: AppTextStyles.variant(
                          AppTextStyles.titleSmall,
                          color: AppColors.slate900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onCopy,
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      color: AppColors.primary,
                      tooltip: LocaleKeys.nominationActionCopyId.tr(),
                    ),
                  ],
                ),
              ),
              AppSpacing.vGapMd,
              if (userId != null && userId!.trim().isNotEmpty) ...<Widget>[
                Text(
                  LocaleKeys.profileUserId.tr(),
                  style: AppTextStyles.variant(
                    AppTextStyles.label,
                    color: AppColors.slate500,
                  ),
                ),
                AppSpacing.vGapSm,
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.infoSurface,
                    borderRadius: AppRadius.brMd,
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Text(
                    userId!,
                    style: AppTextStyles.variant(
                      AppTextStyles.titleSmall,
                      color: AppColors.slate900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AppSpacing.vGapMd,
              ],
              if (password != null && password!.trim().isNotEmpty) ...<Widget>[
                Text(
                  LocaleKeys.authPassword.tr(),
                  style: AppTextStyles.variant(
                    AppTextStyles.label,
                    color: AppColors.slate500,
                  ),
                ),
                AppSpacing.vGapSm,
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.infoSurface,
                    borderRadius: AppRadius.brMd,
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Text(
                    password!,
                    style: AppTextStyles.variant(
                      AppTextStyles.titleSmall,
                      color: AppColors.slate900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AppSpacing.vGapMd,
              ],
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          LocaleKeys.nominationSubmittedDate.tr(),
                          style: AppTextStyles.variant(
                            AppTextStyles.caption,
                            color: AppColors.slate500,
                          ),
                        ),
                        AppSpacing.vGapXs,
                        Text(
                          _formattedDate,
                          style: AppTextStyles.variant(
                            AppTextStyles.bodyMedium,
                            color: AppColors.slate800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          LocaleKeys.nominationStatusLabel.tr(),
                          style: AppTextStyles.variant(
                            AppTextStyles.caption,
                            color: AppColors.slate500,
                          ),
                        ),
                        AppSpacing.vGapXs,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: const BoxDecoration(
                            gradient: NominationTheme.button,
                            borderRadius: AppRadius.brPill,
                          ),
                          child: Text(
                            LocaleKeys.nominationStatusReceived.tr(),
                            style: AppTextStyles.variant(
                              AppTextStyles.caption,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        AppSpacing.vGapMd,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.45),
            borderRadius: AppRadius.brMd,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.info_outline,
                size: 18,
                color: AppColors.primary,
              ),
              AppSpacing.gapSm,
              Expanded(
                child: Text(
                  LocaleKeys.nominationSuccessConfirmation.tr(),
                  style: AppTextStyles.variant(
                    AppTextStyles.bodyMedium,
                    color: AppColors.slate700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _confettiDots() {
    const List<Color> colors = <Color>[
      AppColors.saffron,
      AppColors.primary,
      AppColors.green,
      AppColors.secondary,
    ];
    const List<Offset> positions = <Offset>[
      Offset(-52, -28),
      Offset(48, -32),
      Offset(-40, 34),
      Offset(44, 30),
      Offset(0, -48),
    ];
    return <Widget>[
      for (int i = 0; i < positions.length; i++)
        Positioned(
          left: 48 + positions[i].dx,
          top: 48 + positions[i].dy,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colors[i % colors.length],
              shape: BoxShape.circle,
            ),
          ),
        ),
    ];
  }
}
