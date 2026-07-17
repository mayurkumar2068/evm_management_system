import 'package:evm_management_system/shared/design_system/responsive/app_responsive.dart';
import 'package:flutter/widgets.dart';

/// Consistent 4-pt based spacing scale. UI uses these instead of magic numbers.
///
/// The raw `double` steps are fixed design constants; the `gap*` / `page`
/// helpers are device-aware (see [AppResponsive]) so breathing room grows on
/// large screens and tightens on small ones while staying perfectly aligned.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Fixed card padding (used as a `const` constructor default).
  static const EdgeInsets card = EdgeInsets.all(lg);

  /// Responsive page paddings — scale gently with the device.
  static EdgeInsets get pageH =>
      EdgeInsets.symmetric(horizontal: AppResponsive.space(lg));
  static EdgeInsets get page => EdgeInsets.all(AppResponsive.space(lg));

  static SizedBox get gapXs =>
      SizedBox(height: AppResponsive.space(xs), width: AppResponsive.space(xs));
  static SizedBox get gapSm =>
      SizedBox(height: AppResponsive.space(sm), width: AppResponsive.space(sm));
  static SizedBox get gapMd =>
      SizedBox(height: AppResponsive.space(md), width: AppResponsive.space(md));
  static SizedBox get gapLg =>
      SizedBox(height: AppResponsive.space(lg), width: AppResponsive.space(lg));
  static SizedBox get gapXl =>
      SizedBox(height: AppResponsive.space(xl), width: AppResponsive.space(xl));

  static SizedBox get vGapXs => SizedBox(height: AppResponsive.space(xs));
  static SizedBox get vGapSm => SizedBox(height: AppResponsive.space(sm));
  static SizedBox get vGapMd => SizedBox(height: AppResponsive.space(md));
  static SizedBox get vGapLg => SizedBox(height: AppResponsive.space(lg));
  static SizedBox get vGapXl => SizedBox(height: AppResponsive.space(xl));
}
