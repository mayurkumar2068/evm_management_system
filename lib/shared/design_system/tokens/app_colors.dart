import 'package:flutter/material.dart';

/// Soft Booth-Survey theme — single source for the whole app.
///
/// Extracted from the staging soft UI: sky blue → mint green, soft surfaces,
/// rounded cards. PO login, survey login, session-expiry login, and Flutter
/// chrome all share these tokens with Angular `survey_web` CSS variables.
abstract final class AppColors {
  // Brand — soft blue / mint (Booth Survey reference).
  static const Color saffron = Color(0xFFF4801F);
  static const Color green = Color(0xFF10B981);
  static const Color titleGreen = Color(0xFF059669);
  static const Color teal = Color(0xFF0D9488);
  static const Color muted = Color(0xFF94A3B8);

  /// Soft sky blue (hero / primary actions).
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color primaryDeep = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFFDBEAFE);
  static const Color primaryBright = Color(0xFF60A5FA);

  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryLight = Color(0xFFD1FAE5);

  static const Color greenLight = Color(0xFF34D399);
  static const Color greenDark = Color(0xFF059669);
  static const Color greenExtraLight = Color(0xFFECFDF5);

  static const Color purple = Color(0xFF6366F1);
  static const Color purpleLight = Color(0xFFEEF2FF);

  /// Survey WebView — same soft primary as the rest of the app.
  static const Color surveyPrimary = Color(0xFF3B82F6);
  static const Color surveyPrimaryDark = Color(0xFF2563EB);
  static const Color tealLight = Color(0xFF14B8A6);

  // Neutrals
  static const Color background = Color(0xFFEEF5FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F7FC);
  static const Color outline = Color(0xFFE2E8F0);

  // Slate scale
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E3A5F);
  static const Color slate900 = Color(0xFF0F2744);

  // Text
  static const Color textPrimary = Color(0xFF0F2744);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF94A3B8);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const Color successSurface = Color(0xFFD1FAE5);
  static const Color warningSurface = Color(0xFFFEF3C7);
  static const Color errorSurface = Color(0xFFFEE2E2);
  static const Color infoSurface = Color(0xFFDBEAFE);

  // Dark theme neutrals
  static const Color darkBackground = Color(0xFF0E1116);
  static const Color darkSurface = Color(0xFF171C24);
  static const Color darkOutline = Color(0xFF2B3340);
  static const Color darkTextPrimary = Color(0xFFE6E9EF);
  static const Color darkTextSecondary = Color(0xFFA7B0BE);

  static const Color cardShadow = Color(0x143B82F6);
}
