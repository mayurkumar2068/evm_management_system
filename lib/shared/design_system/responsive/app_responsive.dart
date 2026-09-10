import 'package:flutter/widgets.dart';

abstract final class AppResponsive {
  static const double _refWidth = 408;

  static double _fontScale = 1;
  static double _spaceScale = 1;

  static double get fontScale => _fontScale;

  static double get spaceScale => _spaceScale;

  static void update(MediaQueryData mq) {
    final double width = mq.size.shortestSide;
    final double device = (width / _refWidth).clamp(0.88, 1.12);

    final double userPref = mq.textScaler.scale(10) / 10;

    _fontScale = (device * userPref).clamp(0.85, 1.28);
    _spaceScale = device.clamp(0.92, 1.15);
  }

  static double space(double value) => value * _spaceScale;
}
