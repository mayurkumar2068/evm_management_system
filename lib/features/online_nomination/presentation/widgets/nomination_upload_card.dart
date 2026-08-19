import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/features/online_nomination/presentation/models/nomination_form_state.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

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
              child: _buildActions(isUploaded: isUploaded, isError: isError),
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
