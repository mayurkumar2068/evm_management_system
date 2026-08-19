import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_gender_avatar.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Reusable column showing a gender avatar, localised label, and an
/// integer count — used across live-poll stat cards and turnout entry fields.
class PresidingGenderStatColumn extends StatelessWidget {
  const PresidingGenderStatColumn({
    required this.genderType,
    this.avatarSize = 36,
    this.labelFontSize,
    this.labelMaxLines = 1,
    super.key,
  });

  final PresidingGenderType genderType;

  /// Diameter passed to [PresidingGenderAvatar]. Defaults to 36 (turnout card).
  final double avatarSize;

  /// Override for the label font size. When null the widget uses
  /// [AppTextStyles.caption] at its default size.
  final double? labelFontSize;

  final int labelMaxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        PresidingGenderAvatar(type: genderType, size: avatarSize),
        const SizedBox(height: 4),
        Text(
          PresidingGenderAssets.labelKeyFor(genderType).tr(),
          textAlign: TextAlign.center,
          maxLines: labelMaxLines,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: labelFontSize,
          ),
        ),
      ],
    );
  }
}
