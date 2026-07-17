import 'package:evm_management_system/shared/design_system/tokens/app_colors.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_radius.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_spacing.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Builds the light and dark [ThemeData] entirely from design tokens so the
/// whole app stays visually consistent and themeable from one place.
abstract final class AppTheme {
  static ThemeData get light {
    const ColorScheme scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      outline: AppColors.outline,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _textTheme(AppColors.textPrimary, AppColors.textSecondary),
    );
  }

  static ThemeData get dark {
    const ColorScheme scheme = ColorScheme.dark(
      primary: AppColors.primaryBright,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.secondary,
      surface: AppColors.darkSurface,
      error: AppColors.error,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: _textTheme(
        AppColors.darkTextPrimary,
        AppColors.darkTextSecondary,
      ),
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    final bool isLight = scheme.brightness == Brightness.light;
    final Color fill = isLight
        ? AppColors.surfaceVariant
        : AppColors.darkSurface;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppTextStyles.fontFamily,
      fontFamilyFallback: AppTextStyles.devanagariFontFallback,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleMedium.copyWith(
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fill,
        isDense: true,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.slate500,
        ),
        floatingLabelStyle: AppTextStyles.label.copyWith(
          color: AppColors.greenDark,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.slate400),
        helperStyle: AppTextStyles.caption.copyWith(color: AppColors.slate500),
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
        errorMaxLines: 2,
        prefixIconColor: AppColors.slate500,
        suffixIconColor: AppColors.slate500,
        border: const OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: AppColors.outline),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: AppColors.outline),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: AppColors.greenDark, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          textStyle: AppTextStyles.button,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          textStyle: AppTextStyles.label,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: AppTextStyles.label),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.slate100,
        space: 1,
        thickness: 1,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.brMd,
          side: BorderSide(color: AppColors.outline),
        ),
        textStyle: AppTextStyles.bodyLarge,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.surface),
          elevation: WidgetStateProperty.all(4),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          ),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(
              borderRadius: AppRadius.brMd,
              side: BorderSide(color: AppColors.outline),
            ),
          ),
        ),
        textStyle: AppTextStyles.bodyLarge,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: fill,
          border: const OutlineInputBorder(
            borderRadius: AppRadius.brMd,
            borderSide: BorderSide(color: AppColors.outline),
          ),
        ),
      ),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) => TextTheme(
    displayLarge: AppTextStyles.displayLarge.copyWith(color: primary),
    headlineMedium: AppTextStyles.headlineMedium.copyWith(color: primary),
    titleLarge: AppTextStyles.titleLarge.copyWith(color: primary),
    titleMedium: AppTextStyles.titleMedium.copyWith(color: primary),
    titleSmall: AppTextStyles.titleSmall.copyWith(color: primary),
    bodyLarge: AppTextStyles.bodyLarge.copyWith(color: primary),
    bodyMedium: AppTextStyles.bodyMedium.copyWith(color: secondary),
    labelLarge: AppTextStyles.label.copyWith(color: secondary),
  );
}
