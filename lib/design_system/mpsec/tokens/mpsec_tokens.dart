import 'package:flutter/material.dart';

/// MP SEC enterprise palette — soft blue, purple accent, government-grade UI.
abstract final class MpSecTokens {
  static const double cardRadius = 24;
  static const double touchTarget = 48;
  static const double sectionSpacing = 20;

  static const Color softBlue = Color(0xFF4A90E2);
  static const Color softBlueLight = Color(0xFFE8F2FC);
  static const Color softBlueDark = Color(0xFF2563EB);
  static const Color purpleAccent = Color(0xFF7C3AED);
  static const Color purpleSurface = Color(0xFFF3F0FF);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF4A90E2), Color(0xFF7CB9F5)],
  );

  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFFEEF5FC), Color(0xFFF8FAFC)],
  );

  static List<BoxShadow> cardShadow(BuildContext context) => <BoxShadow>[
    BoxShadow(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
