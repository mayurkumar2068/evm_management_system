import 'package:evm_management_system/shared/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';

/// Theme-aware color helpers so screens pick light/dark surfaces from context
/// instead of hardcoding light-only [AppColors] neutrals.
extension AppThemeColors on BuildContext {
  bool get isAppDark => Theme.of(this).brightness == Brightness.dark;

  Color get appBackground => Theme.of(this).scaffoldBackgroundColor;

  Color get appSurface => Theme.of(this).colorScheme.surface;

  Color get appOnSurface => Theme.of(this).colorScheme.onSurface;

  Color get appOutline =>
      isAppDark ? AppColors.darkOutline : AppColors.outline;

  Color get appMuted =>
      isAppDark ? AppColors.darkTextSecondary : AppColors.slate500;

  Color get appMutedStrong =>
      isAppDark ? AppColors.darkTextSecondary : AppColors.slate600;

  Color get appChip => isAppDark ? AppColors.darkOutline : AppColors.slate50;

  Color get appDivider =>
      isAppDark ? AppColors.darkOutline : AppColors.slate100;

  Color get appNavBar =>
      isAppDark ? AppColors.darkSurface : Colors.white.withValues(alpha: 0.97);

  Color get appNavBorder =>
      isAppDark ? AppColors.darkOutline : AppColors.slate100;
}
