import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Returns the localized display label for a supported app [locale].
String languageLabelFor(Locale locale) {
  switch (locale.languageCode) {
    case 'hi':
      return LocaleKeys.settingsHindi.tr();
    case 'en':
      return LocaleKeys.settingsEnglish.tr();
    default:
      return locale.languageCode.toUpperCase();
  }
}

/// Shows a bottom sheet so the user can pick from [context.supportedLocales].
///
/// When [onLocaleSelected] is provided it runs before the sheet closes so the
/// new locale is visible immediately.
///
/// Returns the chosen [Locale], or `null` if the sheet was dismissed.
Future<Locale?> showLanguagePickerSheet(
  BuildContext context, {
  required Locale currentLocale,
  Future<void> Function(Locale locale)? onLocaleSelected,
}) {
  return showModalBottomSheet<Locale>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext ctx) {
      final List<Locale> locales = context.supportedLocales;
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.slate200,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                LocaleKeys.settingsLanguage.tr(),
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 18),
            ...locales.map((Locale locale) {
              final bool selected = locale == currentLocale;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: AppCard(
                  onTap: () async {
                    if (onLocaleSelected != null) {
                      await onLocaleSelected(locale);
                    }
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop(locale);
                    }
                  },
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              languageLabelFor(locale),
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              locale.languageCode.toUpperCase(),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.slate400,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        const Icon(
                          Icons.check_rounded,
                          color: AppColors.green,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}
