import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

class PresidingSaveStatusBadge extends StatelessWidget {
  const PresidingSaveStatusBadge({
    required this.isSaved,
    required this.savedTime,
    this.isReadOnly = false,
    super.key,
  });

  final bool isSaved;
  final bool isReadOnly;
  final String savedTime;

  @override
  Widget build(BuildContext context) {
    if (!isSaved && !isReadOnly) {
      return const SizedBox.shrink();
    }

    return Row(
      children: <Widget>[
        Icon(
          isReadOnly ? Icons.lock_rounded : Icons.check_circle_rounded,
          size: 16,
          color: isReadOnly ? AppColors.slate500 : AppColors.success,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            isReadOnly
                ? LocaleKeys.presidingAlreadyRegistered.tr()
                : LocaleKeys.presidingSavedAt.tr(args: <String>[savedTime]),
            maxLines: 2,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: isSaved ? AppColors.success : AppColors.slate500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
