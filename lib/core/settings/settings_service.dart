import 'package:evm_management_system/core/storage/secure_storage_service.dart';
import 'package:flutter/material.dart';

/// Persistent app preference storage used by theme and locale providers.
final class AppSettingsService {
  const AppSettingsService(this._storage);

  static const String localeKey = 'evm.locale';
  static const String themeModeKey = 'evm.theme_mode';

  final SecureStorageService _storage;

  Future<Locale?> loadLocale() async {
    try {
      final String? raw = await _storage.read(localeKey);
      if (raw == null || raw.isEmpty) return null;
      final List<String> parts = raw.split(RegExp('[-_]'));
      final String languageCode = parts.first;
      if (languageCode.isEmpty) return null;
      final String? countryCode = parts.length > 1 ? parts[1] : null;
      return Locale(languageCode, countryCode);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLocale(Locale locale) async {
    await _storage.write(localeKey, _encodeLocale(locale));
  }

  Future<ThemeMode> loadThemeMode() async {
    try {
      final String? raw = await _storage.read(themeModeKey);
      return _themeModeFromString(raw) ?? ThemeMode.light;
    } catch (_) {
      return ThemeMode.light;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _storage.write(themeModeKey, _themeModeToString(mode));
  }

  static String _encodeLocale(Locale locale) {
    return locale.countryCode == null || locale.countryCode!.isEmpty
        ? locale.languageCode
        : '${locale.languageCode}_${locale.countryCode}';
  }

  static ThemeMode? _themeModeFromString(String? value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return null;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    return mode == ThemeMode.dark ? 'dark' : 'light';
  }
}
