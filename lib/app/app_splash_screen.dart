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
    duration: const Duration(milliseconds: 1000),
  )..forward();

  late final AnimationController _dots = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  late final Animation<double> _emblem = CurvedAnimation(
    parent: _enter,
    curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _enter,
    curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _enter.dispose();
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      AppServices.settings.themeMode.value;
      final bool isDark = context.isAppDark;
      final Color bg = context.appBackground;
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

              final double logoW = (shortest * 0.48).clamp(200.0, 280.0);
              final double hPad = (w * 0.08).clamp(24.0, 72.0);

              return Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          bg,
                          AppColors.primary.withValues(
                            alpha: isDark ? 0.12 : 0.04,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Soft corner accents — kept small so they never cover the loader.
                  Positioned(
                    top: -40,
                    right: -36,
                    child: _GlowBlob(
                      size: 140,
                      color: AppColors.primary.withValues(
                        alpha: isDark ? 0.14 : 0.10,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: h * 0.28,
                    left: -48,
                    child: _GlowBlob(
                      size: 120,
                      color: AppColors.green.withValues(
                        alpha: isDark ? 0.10 : 0.07,
                      ),
                    ),
                  ),
                  SafeArea(
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
                                width: logoW,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: logoPlate,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: isDark ? 0.16 : 0.08,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: BrandLogo(
                                  width: logoW - 24,
                                  height: (logoW - 24) * 1.15,
                                  cropCaption: false,
                                  borderRadius: 10,
                                  backgroundColor: Colors.transparent,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: AppResponsive.space(28)),
                          FadeTransition(
                            opacity: _fade,
                            child: _divider(isDark: isDark),
                          ),
                          const Spacer(flex: 4),
                          // Compact bottom loader — never stretches full screen.
                          FadeTransition(
                            opacity: _fade,
                            child: _SplashLoader(
                              controller: _dots,
                              muted: muted,
                              isDark: isDark,
                            ),
                          ),
                          SizedBox(height: AppResponsive.space(28)),
                        ],
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

  Widget _divider({required bool isDark}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _dividerLine(isDark: isDark),
        const SizedBox(width: 8),
        Icon(
          Icons.diamond_rounded,
          size: 10,
          color: AppColors.primary.withValues(alpha: isDark ? 0.8 : 0.9),
        ),
        const SizedBox(width: 8),
        _dividerLine(isDark: isDark),
      ],
    );
  }

  Widget _dividerLine({required bool isDark}) {
    return Container(
      width: 34,
      height: 2,
      decoration: BoxDecoration(
        borderRadius: AppRadius.brPill,
        gradient: LinearGradient(
          colors: <Color>[
            AppColors.primary.withValues(alpha: isDark ? 0.72 : 0.88),
            AppColors.green.withValues(alpha: isDark ? 0.72 : 0.88),
          ],
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

/// Three bouncing dots + label — sized to content, not the viewport.
class _SplashLoader extends StatelessWidget {
  const _SplashLoader({
    required this.controller,
    required this.muted,
    required this.isDark,
  });

  final AnimationController controller;
  final Color muted;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _BounceDot(
              controller: controller,
              delay: 0.0,
              color: AppColors.primary.withValues(alpha: isDark ? 0.75 : 0.9),
              size: 8,
            ),
            const SizedBox(width: 10),
            _BounceDot(
              controller: controller,
              delay: 0.18,
              color: AppColors.primaryDark.withValues(alpha: isDark ? 0.8 : 1),
              size: 10,
            ),
            const SizedBox(width: 10),
            _BounceDot(
              controller: controller,
              delay: 0.36,
              color: AppColors.green.withValues(alpha: isDark ? 0.75 : 0.9),
              size: 8,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          LocaleKeys.splashLoading.tr(),
          style: TextStyle(
            color: muted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BounceDot extends StatelessWidget {
  const _BounceDot({
    required this.controller,
    required this.delay,
    required this.color,
    required this.size,
  });

  final AnimationController controller;
  final double delay;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final double t = (controller.value + delay) % 1.0;
        final double bounce = math.sin(t * math.pi);
        return Transform.translate(
          offset: Offset(0, -4 * bounce),
          child: Opacity(opacity: 0.45 + (0.55 * bounce), child: child),
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
