import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/utils/app_locale_holder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

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

  await Get.updateLocale(locale);
}

Future<void> toggleAppTheme() async {
  final bool isDark = AppServices.settings.themeMode.value == ThemeMode.dark;
  await AppServices.settings.setThemeMode(
    isDark ? ThemeMode.light : ThemeMode.dark,
  );
}
