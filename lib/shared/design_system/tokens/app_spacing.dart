import 'package:evm_management_system/shared/design_system/responsive/app_responsive.dart';
import 'package:flutter/widgets.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  static const EdgeInsets card = EdgeInsets.all(lg);

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

  static SizedBox get vGapXs => SizedBox(height: AppResponsive.space(xs));
  static SizedBox get vGapSm => SizedBox(height: AppResponsive.space(sm));
  static SizedBox get vGapMd => SizedBox(height: AppResponsive.space(md));
  static SizedBox get vGapLg => SizedBox(height: AppResponsive.space(lg));
}
