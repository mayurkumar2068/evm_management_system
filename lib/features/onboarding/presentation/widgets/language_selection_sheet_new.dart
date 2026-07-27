import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Opens the brand language picker (built on the reusable [AppSelectionSheet])
/// and applies the chosen locale via easy_localization, which also persists it.
///
/// Only the languages that ship with translations are selectable; the rest are
/// listed with a "Soon" badge so the catalogue matches the official brand
/// identity without ever switching to an untranslated locale.
///
/// Returns the chosen [Locale], or `null` if the sheet was dismissed.
Future<Locale?> showLanguageSelectionSheet(BuildContext context) async {
  final String? code = await AppSelectionSheet.show<String>(
    context,
    title: LocaleKeys.onboardingLanguageTitle.tr(),
    subtitle: LocaleKeys.onboardingLanguageSubtitle.tr(),
    headerIcon: Icons.language_rounded,
    confirmLabel: LocaleKeys.onboardingLanguageContinue.tr(),
    initialValue: 'hi',
    isDismissible: false,
    options: <AppSelectionOption<String>>[
      AppSelectionOption<String>(
        value: 'hi',
        title: LocaleKeys.onboardingLanguageHindi.tr(),
        subtitle: LocaleKeys.onboardingLanguageHindi.tr(),
        leadingText: 'अ',
      ),
      AppSelectionOption<String>(
        value: 'en',
        title: LocaleKeys.onboardingLanguageEnglish.tr(),
        subtitle: LocaleKeys.onboardingLanguageEnglish.tr(),
        leadingText: 'A',
      ),
      AppSelectionOption<String>(
        value: 'mr',
        title: 'मराठी',
        subtitle: 'Marathi',
        leadingText: 'म',
        enabled: false,
        badge: LocaleKeys.onboardingLanguageSoon.tr(),
      ),
      AppSelectionOption<String>(
        value: 'gu',
        title: 'ગુજરાતી',
        subtitle: 'Gujarati',
        leadingText: 'અ',
        enabled: false,
        badge: LocaleKeys.onboardingLanguageSoon.tr(),
      ),
      AppSelectionOption<String>(
        value: 'bn',
        title: 'বাংলা',
        subtitle: 'Bangla',
        leadingText: 'ব',
        enabled: false,
        badge: LocaleKeys.onboardingLanguageSoon.tr(),
      ),
      AppSelectionOption<String>(
        value: 'ta',
        title: 'தமிழ்',
        subtitle: 'Tamil',
        leadingText: 'த',
        enabled: false,
        badge: LocaleKeys.onboardingLanguageSoon.tr(),
      ),
    ],
  );

  if (code == null) return null;
  final Locale locale = Locale(code);
  if (context.mounted && code != context.locale.languageCode) {
    await context.setLocale(locale);
  }
  return locale;
}
