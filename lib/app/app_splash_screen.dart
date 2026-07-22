import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;

/// Soft blue→mint launch splash — respects light / dark theme.
class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({super.key});

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  late final Animation<double> _emblem = CurvedAnimation(
    parent: _enter,
    curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _enter,
    curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
  );
  late final Animation<double> _loaderFade = Tween<double>(
    begin: 0.35,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

  @override
  void dispose() {
    _enter.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Rebuild when theme toggles during splash.
      AppServices.settings.themeMode.value;
      final bool isDark = context.isAppDark;
      final Color bg = context.appBackground;
      final Color onBg = context.appOnSurface;
      final Color muted = context.appMuted;
      final Color logoPlate = context.appSurface;

      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: bg,
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final double w = c.maxWidth;
              final double h = c.maxHeight;
              final double shortest = math.min(w, h);

              final double logoW = (shortest * 0.18).clamp(100.0, 100.0);
              final double titleSize = (shortest * 0.068).clamp(22.0, 32.0);
              final double taglineSize = (shortest * 0.04).clamp(13.0, 18.0);
              final double hPad = (w * 0.08).clamp(24.0, 72.0);

              return Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Positioned(
                    top: -90,
                    right: -70,
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(
                          alpha: isDark ? 0.16 : 0.12,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: h * 0.12,
                    left: -80,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.green.withValues(
                          alpha: isDark ? 0.14 : 0.10,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 28 + MediaQuery.of(context).padding.bottom,
                    child: Container(
                      height: 8,
                      decoration: const BoxDecoration(
                        borderRadius: AppRadius.brPill,
                        gradient: AppGradients.primaryButton,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: Column(
                          children: <Widget>[
                            const Spacer(flex: 3),
                            ScaleTransition(
                              scale: _emblem,
                              child: FadeTransition(
                                opacity: _fade,
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: logoPlate,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: context.appOutline,
                                    ),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: isDark ? 0.28 : 0.14,
                                        ),
                                        blurRadius: 28,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: BrandLogo(width: logoW),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: AppResponsive.space(28)),
                            FadeTransition(
                              opacity: _fade,
                              child: Column(
                                children: <Widget>[
                                  Text(
                                    LocaleKeys.splashTitle.tr(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: onBg,
                                      fontSize: titleSize,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                      height: 1.2,
                                    ),
                                  ),
                                  SizedBox(height: AppResponsive.space(14)),
                                  _divider(),
                                  SizedBox(height: AppResponsive.space(18)),
                                  Text(
                                    LocaleKeys.splashTagline.tr(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: taglineSize,
                                      height: 1.45,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(flex: 4),
                            FadeTransition(
                              opacity: _fade,
                              child: _loader(muted: muted),
                            ),
                            SizedBox(height: AppResponsive.space(36)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    });
  }

  Widget _divider() {
    return Container(
      width: 72,
      height: 4,
      decoration: const BoxDecoration(
        borderRadius: AppRadius.brPill,
        gradient: AppGradients.primaryButton,
      ),
    );
  }

  Widget _loader({required Color muted}) {
    return FadeTransition(
      opacity: _loaderFade,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 22,
            height: 2.5,
            decoration: BoxDecoration(
              borderRadius: AppRadius.brPill,
              color: AppColors.primary.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            LocaleKeys.splashLoading.tr(),
            style: TextStyle(
              color: muted,
              fontSize: 12,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 22,
            height: 2.5,
            decoration: BoxDecoration(
              borderRadius: AppRadius.brPill,
              color: AppColors.green.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
