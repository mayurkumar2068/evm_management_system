import 'package:flutter/widgets.dart';

/// Single source of truth for device-aware scaling.
///
/// The root widget calls [update] once per frame with the current
/// [MediaQueryData]; design tokens (typography via the app-level `textScaler`
/// and [AppSpacing] gaps) then read [fontScale] / [spaceScale] so the UI stays
/// aligned on small phones, large phones and tablets without per-screen code.
abstract final class AppResponsive {
  /// Reference width the type scale is tuned against. Set a touch above common
  /// phone widths so most phones get a gentle, even reduction (fonts read a
  /// little smaller) while tablets scale up modestly.
  static const double _refWidth = 408;

  static double _fontScale = 1;
  static double _spaceScale = 1;

  /// Multiplier applied to all text (device width + bounded user preference).
  static double get fontScale => _fontScale;

  /// Multiplier applied to spacing gaps so breathing room tracks screen size.
  static double get spaceScale => _spaceScale;

  /// Recomputes the scale factors from the current media query. Safe to call
  /// every build; values are clamped so layouts never blow up or collapse.
  static void update(MediaQueryData mq) {
    // shortestSide keeps landscape/tablet scaling sane (not tied to long edge).
    final double width = mq.size.shortestSide;
    final double device = (width / _refWidth).clamp(0.88, 1.12);

    // Respect the user's system font preference, but keep it bounded so the
    // layout cannot break under very large accessibility settings.
    final double userPref = mq.textScaler.scale(10) / 10;

    _fontScale = (device * userPref).clamp(0.85, 1.28);
    _spaceScale = device.clamp(0.92, 1.15);
  }

  /// Scales a raw spacing value by the current [spaceScale].
  static double space(double value) => value * _spaceScale;
}
