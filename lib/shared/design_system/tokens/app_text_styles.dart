import 'package:evm_management_system/shared/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  static const String fontFamily = 'NotoSansDevanagari';

  static const String devanagariFontFamily = 'NotoSansDevanagari';

  static const List<String> devanagariFontFallback = <String>[
    devanagariFontFamily,
  ];

  static TextStyle withDevanagariFallback(TextStyle style) =>
      style.copyWith(fontFamilyFallback: devanagariFontFallback);

  static TextStyle variant(
    TextStyle base, {
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
    double? height,
    double? letterSpacing,
  }) => withDevanagariFallback(
    base.copyWith(
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
      height: height,
      letterSpacing: letterSpacing,
    ),
  );

  static TextStyle _poppins({
    required double fontSize,
    required FontWeight fontWeight,
    double? height,
    double? letterSpacing,
    Color color = AppColors.textPrimary,
  }) => withDevanagariFallback(
    TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    ),
  );

  static TextStyle get displayLarge =>
      _poppins(fontSize: 32, fontWeight: FontWeight.w700, height: 1.15);

  static TextStyle get headlineMedium =>
      _poppins(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25);

  static TextStyle get titleLarge =>
      _poppins(fontSize: 20, fontWeight: FontWeight.w700);

  static TextStyle get titleMedium =>
      _poppins(fontSize: 16, fontWeight: FontWeight.w600);

  static TextStyle get titleSmall =>
      _poppins(fontSize: 14, fontWeight: FontWeight.w600);

  static TextStyle get bodyLarge =>
      _poppins(fontSize: 15, fontWeight: FontWeight.w400, height: 1.45);

  static TextStyle get bodyMedium => _poppins(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  static TextStyle get label => _poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static TextStyle get button =>
      _poppins(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2);

  static TextStyle get caption => _poppins(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle get overline => _poppins(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: AppColors.textSecondary,
  );
}
