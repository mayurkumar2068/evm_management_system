import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/features/online_nomination/data/models/nomination_draft.dart';
import 'package:evm_management_system/features/online_nomination/presentation/models/nomination_form_state.dart';
import 'package:evm_management_system/features/online_nomination/presentation/models/nomination_models.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:evm_management_system/features/online_nomination/presentation/widgets/nomination_theme.dart';

/// Primary action button with theme gradient for nomination flows.
class NominationGovButton extends StatelessWidget {
  const NominationGovButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.outlined = false,
    this.expanded = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      final Widget child = _labelRow(
        AppTextStyles.variant(AppTextStyles.button, color: AppColors.primary),
      );
      final Widget button = OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        ),
        child: child,
      );
      return expanded
          ? SizedBox(width: double.infinity, child: button)
          : button;
    }

    final Widget gradientButton = Opacity(
      opacity: onPressed == null ? 0.65 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.brMd,
          child: Ink(
            height: 52,
            decoration: BoxDecoration(
              gradient: NominationTheme.button,
              borderRadius: AppRadius.brMd,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: _labelRow(
                AppTextStyles.variant(
                  AppTextStyles.button,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return expanded
        ? SizedBox(width: double.infinity, child: gradientButton)
        : gradientButton;
  }

  Widget _labelRow(TextStyle style) {
    final Widget labelWidget = Text(
      label,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );

    if (icon == null) {
      return FittedBox(fit: BoxFit.scaleDown, child: labelWidget);
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 20, color: style.color),
          AppSpacing.gapSm,
          Text(
            label,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

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
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.brLg,
                    boxShadow: const <BoxShadow>[
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

class NominationResumeDraftCard extends StatelessWidget {
  const NominationResumeDraftCard({
    required this.draft,
    required this.onContinue,
    required this.onStartFresh,
    super.key,
  });

  final NominationDraft draft;
  final VoidCallback onContinue;
  final VoidCallback onStartFresh;

  @override
  Widget build(BuildContext context) {
    final String stepLabel = draft.stepLabelKeyFor(draft.currentStep).tr();
    final String postLabel = draft.postType.labelKey.tr();
    final String electionLabel = draft.electionType.labelKey.tr();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.25),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.restore_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              AppSpacing.gapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      LocaleKeys.nominationDraftResumeTitle.tr(),
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.slate900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppSpacing.vGapXs,
                    Text(
                      LocaleKeys.nominationDraftResumeSubtitle.tr(
                        namedArgs: <String, String>{
                          'step': stepLabel,
                          'post': postLabel,
                          'election': electionLabel,
                        },
                      ),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.slate600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,
          NominationGovButton(
            label: LocaleKeys.nominationDraftContinue.tr(),
            icon: Icons.play_arrow_rounded,
            onPressed: onContinue,
          ),
          AppSpacing.vGapSm,
          NominationGovButton(
            label: LocaleKeys.nominationDraftStartFresh.tr(),
            outlined: true,
            onPressed: onStartFresh,
          ),
        ],
      ),
    );
  }
}

class NominationFeatureBullet extends StatelessWidget {
  const NominationFeatureBullet({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          NominationGradientIcon(icon: icon, size: 40, iconSize: 20),
          AppSpacing.gapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTextStyles.variant(
                    AppTextStyles.titleSmall,
                    color: AppColors.slate900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
        ],
      ),
    );
  }
}

class NominationSummaryRow extends StatelessWidget {
  const NominationSummaryRow({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.slate500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.slate800,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class NominationHorizontalStepper extends StatelessWidget {
  const NominationHorizontalStepper({
    required this.steps,
    required this.currentStep,
    super.key,
  });

  final List<NominationStepItem> steps;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < steps.length; i++) ...<Widget>[
            _StepNode(
              index: i,
              label: steps[i].labelKey.tr(),
              isActive: i == currentStep,
              isCompleted: i < currentStep,
            ),
            if (i < steps.length - 1)
              Container(
                width: 24,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: i < currentStep ? AppColors.primary : AppColors.slate200,
              ),
          ],
        ],
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.index,
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  final int index;
  final String label;
  final bool isActive;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final bool isDone = isCompleted;
    final bool isInProgress = isActive && !isCompleted;

    final Decoration nodeDecoration = isDone || isInProgress
        ? NominationTheme.gradientCircle()
        : const BoxDecoration(
            color: AppColors.slate300,
            shape: BoxShape.circle,
          );

    final Color textColor = isActive || isCompleted
        ? AppColors.primary
        : AppColors.slate500;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: nodeDecoration,
          child: isCompleted
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  '${index + 1}',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 72,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.variant(
              AppTextStyles.caption,
              color: textColor,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}

class NominationInfoCard extends StatelessWidget {
  const NominationInfoCard({
    required this.title,
    required this.children,
    this.onEdit,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.slate900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onEdit != null)
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.greenDark,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.edit_outlined, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          LocaleKeys.nominationEdit.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          AppSpacing.vGapSm,
          ...children,
        ],
      ),
    );
  }
}

class NominationUploadCard extends StatelessWidget {
  const NominationUploadCard({
    required this.title,
    required this.state,
    required this.onUpload,
    this.onReplace,
    this.onDelete,
    this.onRetry,
    super.key,
  });

  final String title;
  final NominationDocumentUploadState state;
  final VoidCallback onUpload;
  final VoidCallback? onReplace;
  final VoidCallback? onDelete;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final bool isUploaded =
        state.status == NominationDocumentUploadStatus.uploaded;
    final bool isUploading =
        state.status == NominationDocumentUploadStatus.uploading;
    final bool isError = state.status == NominationDocumentUploadStatus.error;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(
          color: isError ? AppColors.error : AppColors.slate200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                isUploaded
                    ? Icons.check_circle_outline
                    : Icons.description_outlined,
                color: isUploaded ? AppColors.greenDark : AppColors.slate600,
              ),
              AppSpacing.gapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.slate800,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isError && state.errorMessage != null
                          ? state.errorMessage!.tr()
                          : isUploaded && state.fileName != null
                          ? state.fileName!
                          : LocaleKeys.nominationDocumentFileHint.tr(),
                      style: AppTextStyles.caption.copyWith(
                        color: isError ? AppColors.error : AppColors.slate500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isUploading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          if (!isUploading) ...<Widget>[
            AppSpacing.vGapXs,
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _buildActions(
                isUploaded: isUploaded,
                isError: isError,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions({required bool isUploaded, required bool isError}) {
    final ButtonStyle compactStyle = TextButton.styleFrom(
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      visualDensity: VisualDensity.compact,
    );

    if (isError) {
      return TextButton(
        style: compactStyle,
        onPressed: onRetry ?? onUpload,
        child: Text(
          LocaleKeys.nominationActionRetry.tr(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    if (isUploaded) {
      return Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.xs,
        children: <Widget>[
          TextButton(
            style: compactStyle,
            onPressed: onReplace ?? onUpload,
            child: Text(
              LocaleKeys.nominationActionReplace.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.error,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
        ],
      );
    }

    return TextButton(
      style: compactStyle,
      onPressed: onUpload,
      child: Text(
        LocaleKeys.nominationUpload.tr(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.greenDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class NominationSuccessCard extends StatelessWidget {
  const NominationSuccessCard({
    required this.applicationNumber,
    required this.onCopy,
    this.submittedAt,
    super.key,
  });

  final String applicationNumber;
  final VoidCallback onCopy;
  final DateTime? submittedAt;

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
                          decoration: BoxDecoration(
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

class NominationReceiptCard extends StatelessWidget {
  const NominationReceiptCard({
    required this.applicationNumber,
    required this.electionType,
    required this.post,
    required this.submittedAt,
    super.key,
  });

  final String applicationNumber;
  final String electionType;
  final String post;
  final String submittedAt;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: AppRadius.brXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const BrandLogo(width: 40),
              AppSpacing.gapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      LocaleKeys.nominationDigitalReceipt.tr(),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.slate900,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      LocaleKeys.nominationReceiptSubtitle.tr(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 64,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: AppRadius.brSm,
                  border: Border.all(color: AppColors.slate200),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 36,
                  color: AppColors.slate400,
                ),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  children: <Widget>[
                    NominationSummaryRow(
                      label: LocaleKeys.nominationApplicationNumber.tr(),
                      value: applicationNumber,
                    ),
                    NominationSummaryRow(
                      label: LocaleKeys.nominationElectionType.tr(),
                      value: electionType,
                    ),
                    NominationSummaryRow(
                      label: LocaleKeys.nominationPost.tr(),
                      value: post,
                    ),
                    NominationSummaryRow(
                      label: LocaleKeys.nominationStatusSubmitted.tr(),
                      value: submittedAt,
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: AppRadius.brSm,
                border: Border.all(color: AppColors.slate200),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                size: 56,
                color: AppColors.slate700,
              ),
            ),
          ),
          AppSpacing.vGapSm,
          Center(
            child: Text(
              LocaleKeys.nominationStatusSubmitted.tr(),
              style: AppTextStyles.caption.copyWith(color: AppColors.slate500),
            ),
          ),
        ],
      ),
    );
  }
}

class NominationTimelineTile extends StatelessWidget {
  const NominationTimelineTile({
    required this.index,
    required this.label,
    required this.timestamp,
    required this.status,
    required this.isLast,
    this.officer,
    this.remarks,
    super.key,
  });

  final int index;
  final String label;
  final String timestamp;
  final String status;
  final bool isLast;
  final String? officer;
  final String? remarks;

  @override
  Widget build(BuildContext context) {
    final bool isDone = status == LocaleKeys.nominationStatusDone.tr();
    final bool isInProgress =
        status == LocaleKeys.nominationStatusInProgress.tr();

    final Decoration nodeDecoration = isDone
        ? NominationTheme.gradientCircle()
        : BoxDecoration(
            color: isInProgress ? AppColors.warning : AppColors.slate300,
            shape: BoxShape.circle,
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          children: <Widget>[
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: nodeDecoration,
              child: isDone
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text(
                      '${index + 1}',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
            ),
            if (!isLast)
              Container(width: 2, height: 56, color: AppColors.slate200),
          ],
        ),
        AppSpacing.gapSm,
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.brMd,
              border: Border.all(color: AppColors.slate200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        label,
                        style: AppTextStyles.variant(
                          AppTextStyles.bodyMedium,
                          color: AppColors.slate900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _StatusBadge(
                      status: status,
                      isDone: isDone,
                      isInProgress: isInProgress,
                    ),
                  ],
                ),
                AppSpacing.vGapXs,
                Text(
                  timestamp,
                  style: AppTextStyles.variant(
                    AppTextStyles.caption,
                    color: AppColors.slate500,
                  ),
                ),
                if (officer != null) ...<Widget>[
                  AppSpacing.vGapXs,
                  Text(
                    '${LocaleKeys.nominationTimelineOfficer.tr()}: $officer',
                    style: AppTextStyles.variant(
                      AppTextStyles.caption,
                      color: AppColors.slate600,
                    ),
                  ),
                ],
                if (remarks != null) ...<Widget>[
                  AppSpacing.vGapXs,
                  Text(
                    '${LocaleKeys.nominationTimelineRemarks.tr()}: $remarks',
                    style: AppTextStyles.variant(
                      AppTextStyles.caption,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.isDone,
    required this.isInProgress,
  });

  final String status;
  final bool isDone;
  final bool isInProgress;

  @override
  Widget build(BuildContext context) {
    if (isDone) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: NominationTheme.gradientPill(),
        child: Text(
          status,
          style: AppTextStyles.variant(
            AppTextStyles.caption,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isInProgress ? AppColors.warningSurface : AppColors.slate100,
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        status,
        style: AppTextStyles.variant(
          AppTextStyles.caption,
          color: isInProgress ? AppColors.warning : AppColors.slate500,
          fontWeight: FontWeight.w700,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}

/// Formats Aadhaar input as groups of 4 digits.
class AadhaarInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 12) {
      return oldValue;
    }
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final String formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
