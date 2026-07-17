import 'package:flutter/material.dart';

/// The single source of truth for color. UI never uses raw `Color(...)` or
/// `Colors.*`; it references these tokens (or the [ColorScheme]) instead.
///
/// Palette mirrors the official EVM Management System design system
/// (primary blue #0A4DCC, saffron accent, ECI green).
abstract final class AppColors {
  // Brand — Election Commission of India palette.

  static const Color saffron = Color(0xFFF4801F);
  static const Color green = Color(0xFF1E8E3E);
  static const Color titleGreen = Color(0xFF1B7A3C);
  static const Color teal = Color(0xFF15706A);
  static const Color muted = Color(0xFF94A3B8);

  static const Color primary = Color(0xFF0A4DCC);
  static const Color primaryDark = Color(0xFF0836A0);
  static const Color primaryDeep = Color(0xFF071E6B);
  static const Color primaryLight = Color(0xFFEEF3FF);
  static const Color primaryBright = Color(0xFF1565E8);

  static const Color secondary = Color(0xFFFF9933);
  static const Color secondaryLight = Color(0xFFFFF3E0);

  static const Color greenLight = Color(0xFF0BA360);
  static const Color greenDark = Color(0xFF067A48);
  static const Color greenExtraLight = Color(0xFFE6F7EE);

  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleLight = Color(0xFFF3F0FF);

  /// Survey micro-app (Angular WebView) — matches `--ec-primary` in survey_web.
  static const Color surveyPrimary = Color(0xFF7167E8);
  static const Color surveyPrimaryDark = Color(0xFF5B52CF);
  static const Color tealLight = Color(0xFF0891B2);

  // Neutrals
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F4F8);
  static const Color outline = Color(0xFFE2E8F0);

  // Slate scale (mirrors Tailwind slate used in the design).
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // Text
  static const Color textPrimary = Color(0xFF0D1B2E);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF94A3B8);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF1565C0);

  // Soft status surfaces (pill backgrounds).
  static const Color successSurface = Color(0xFFDCFCE7);
  static const Color warningSurface = Color(0xFFFEF3C7);
  static const Color errorSurface = Color(0xFFFEE2E2);
  static const Color infoSurface = Color(0xFFDBEAFE);

  // Dark theme neutrals
  static const Color darkBackground = Color(0xFF0E1116);
  static const Color darkSurface = Color(0xFF171C24);
  static const Color darkOutline = Color(0xFF2B3340);
  static const Color darkTextPrimary = Color(0xFFE6E9EF);
  static const Color darkTextSecondary = Color(0xFFA7B0BE);

  /// Soft shadow used by elevated cards across the app.
  static const Color cardShadow = Color(0x120A4DCC);
}
