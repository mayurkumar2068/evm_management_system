import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/utils/app_locale_holder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Applies a locale immediately across EasyLocalization and persisted settings.
Future<void> applyAppLocale({
  required BuildContext context,
  required Locale locale,
}) async {
  final Locale current = AppServices.settings.locale.value;
  if (locale == current && context.locale == locale) return;

  AppLocaleHolder.code = locale.languageCode;
  if (context.mounted && context.locale != locale) {
    await context.setLocale(locale);
  }
  await AppServices.settings.setLocale(locale);
  // Force GetX material app + cached `.tr()` labels to rebuild immediately.
  await Get.updateLocale(locale);
}

/// Toggles between light and dark theme and persists the choice.
Future<void> toggleAppTheme() async {
  final bool isDark = AppServices.settings.themeMode.value == ThemeMode.dark;
  await AppServices.settings.setThemeMode(
    isDark ? ThemeMode.light : ThemeMode.dark,
  );
}
