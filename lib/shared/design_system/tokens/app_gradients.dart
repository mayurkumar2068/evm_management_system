import 'package:evm_management_system/shared/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';

abstract final class AppGradients {
  static const LinearGradient header = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF60A5FA), Color(0xFF3B82F6), Color(0xFF34D399)],
    stops: <double>[0.0, 0.45, 1.0],
  );

  static const LinearGradient primaryButton = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[AppColors.primary, AppColors.green],
  );

  static const LinearGradient nominationButton = primaryButton;

  static const LinearGradient survey = primaryButton;

  static const LinearGradient green = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[AppColors.greenDark, AppColors.green],
  );

  static const LinearGradient nomination = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[AppColors.primaryDark, AppColors.primary, AppColors.green],
    stops: <double>[0.0, 0.45, 1.0],
  );

  static const LinearGradient saffron = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFB45309), AppColors.saffron],
  );

  static LinearGradient accent(Color color) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[color, color.withValues(alpha: 0.8)],
  );
}
