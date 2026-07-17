import 'package:evm_management_system/shared/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';

/// Reusable gradients used by headers, hero cards and primary buttons so the
/// signature EVM look stays consistent and is defined in exactly one place.
abstract final class AppGradients {
  /// Deep navy → blue header used on top app sections.
  static const LinearGradient header = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      AppColors.primaryDeep,
      AppColors.primaryDark,
      AppColors.primary,
    ],
  );

  /// Full brand sweep navy → blue → green, used on splash / login headers.
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      AppColors.primaryDeep,
      AppColors.primaryDark,
      AppColors.primary,
      AppColors.green,
    ],
    stops: <double>[0.0, 0.35, 0.7, 1.0],
  );

  /// Primary CTA button gradient.
  static const LinearGradient primaryButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[AppColors.primary, AppColors.primaryBright],
  );

  /// Green sweep (ballot unit / success contexts).
  static const LinearGradient green = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[AppColors.greenDark, AppColors.green],
  );

  /// Online nomination module — brand theme gradient (navy → blue → green).
  static const LinearGradient nomination = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      AppColors.primaryDeep,
      AppColors.primary,
      AppColors.greenDark,
      AppColors.green,
    ],
    stops: <double>[0.0, 0.35, 0.7, 1.0],
  );

  /// Compact CTA gradient for nomination buttons.
  static const LinearGradient nominationButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[AppColors.primary, AppColors.green],
  );

  /// Survey WebView chrome — matches Angular survey hero (`#806ef4` → `#6352d2`).
  static const LinearGradient survey = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF806EF4), Color(0xFF6352D2)],
  );

  /// Saffron sweep (analytics / warning contexts).
  static const LinearGradient saffron = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFB45309), AppColors.secondary],
  );

  /// Builds a soft two-stop gradient from a single accent color.
  static LinearGradient accent(Color color) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[color, color.withValues(alpha: 0.8)],
  );
}
