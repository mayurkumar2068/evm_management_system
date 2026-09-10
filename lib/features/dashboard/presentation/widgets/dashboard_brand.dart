import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

class DashboardBrand {
  const DashboardBrand._();
  static const Color green = AppColors.primary;
  static const Color greenDark = AppColors.primaryDark;
  static const Color accent = AppColors.green;
  static const Color saffron = AppColors.saffron;
  static const Color ink = AppColors.textPrimary;
  static const Color surface = AppColors.slate50;

  static const LinearGradient welcomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF4B8FE8), Color(0xFF2563EB), Color(0xFF059669)],
    stops: <double>[0.0, 0.48, 1.0],
  );
}

class DashboardGap {
  const DashboardGap._();
  static const double page = 20;
  static const double section = 24;
  static const double headerToContent = 12;
}
