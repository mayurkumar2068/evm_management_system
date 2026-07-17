import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_gender_avatar.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';

/// Presiding-officer UI tokens built on top of the shared design system.
abstract final class PresidingUiTokens {
  static const Color actionGreen = AppColors.greenDark;
  static const Color liveAccent = AppColors.error;
  static const Color cardGreenSurface = AppColors.greenExtraLight;
  static const Color cardGreenBorder = Color(0xFFC8E6C9);
  static const Color finishButtonSurface = Color(0xFFFFF9E6);
  static const Color queueAccent = AppColors.saffron;

  static Color genderColor(PresidingGenderType type) {
    return switch (type) {
      PresidingGenderType.male => AppColors.green,
      PresidingGenderType.female => const Color(0xFFDB2777),
      PresidingGenderType.other => AppColors.purple,
    };
  }
}
