import 'package:flutter/material.dart';

/// MP SEC soft theme — mirrors Booth Survey blue → mint reference.
abstract final class MpSecTokens {
  static const double cardRadius = 20;
  static const double touchTarget = 48;
  static const double sectionSpacing = 20;

  static const Color softBlue = Color(0xFF3B82F6);
  static const Color softBlueLight = Color(0xFFDBEAFE);
  static const Color softBlueDark = Color(0xFF2563EB);
  static const Color mint = Color(0xFF10B981);
  static const Color mintLight = Color(0xFFECFDF5);
  static const Color purpleAccent = Color(0xFF6366F1);
  static const Color purpleSurface = Color(0xFFEEF2FF);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF60A5FA), Color(0xFF3B82F6), Color(0xFF34D399)],
    stops: <double>[0.0, 0.5, 1.0],
  );

  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFFEEF5FC), Color(0xFFF8FAFC)],
  );

  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[Color(0xFF3B82F6), Color(0xFF10B981)],
  );

  static List<BoxShadow> cardShadow(BuildContext context) => <BoxShadow>[
    BoxShadow(
      color: softBlue.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
