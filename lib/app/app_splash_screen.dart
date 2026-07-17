import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Branded launch splash for the Madhya Pradesh Nirvachan app.
///
/// Pure UI: it shows the state-election emblem, title and tagline over a faint
/// secretariat silhouette + tricolor wave. Navigation away is still driven by
/// the router guard once the session resolves (see `EvmApp`), which now holds
/// this screen for a fixed ~3s before redirecting to onboarding/login/home.
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final double w = c.maxWidth;
          final double h = c.maxHeight;
          final double shortest = math.min(w, h);

          final double logoW = (shortest * 0.42).clamp(130.0, 240.0);
          final double titleSize = (shortest * 0.072).clamp(22.0, 34.0);
          final double taglineSize = (shortest * 0.042).clamp(14.0, 20.0);
          final double hPad = (w * 0.08).clamp(24.0, 72.0);

          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: h * 0.34,
                child: const TricolorWave(),
              ),
              Positioned.fill(
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        const Spacer(flex: 3),
                        ScaleTransition(
                          scale: _emblem,
                          child: FadeTransition(
                            opacity: _fade,
                            child: BrandLogo(width: logoW),
                          ),
                        ),
                        SizedBox(height: AppResponsive.space(26)),
                        FadeTransition(
                          opacity: _fade,
                          child: Column(
                            children: <Widget>[
                              Text(
                                LocaleKeys.splashTitle.tr(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.titleGreen,
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: AppResponsive.space(16)),
                              _divider(),
                              SizedBox(height: AppResponsive.space(22)),
                              Text(
                                LocaleKeys.splashTagline.tr(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.tealLight,
                                  fontSize: taglineSize,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(flex: 4),
                        FadeTransition(opacity: _fade, child: _loader()),
                        SizedBox(height: AppResponsive.space(30)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _divider() {
    Widget bar(Color c) => Container(
      width: 30,
      height: 3,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(2),
      ),
    );
    Widget dot(Color c) => Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        dot(AppColors.saffron),
        const SizedBox(width: 6),
        bar(AppColors.saffron),
        const SizedBox(width: 5),
        bar(const Color(0xFFE2E8F0)),
        const SizedBox(width: 5),
        bar(AppColors.greenExtraLight),
        const SizedBox(width: 6),
        dot(AppColors.greenExtraLight),
      ],
    );
  }

  Widget _loader() {
    return FadeTransition(
      opacity: _loaderFade,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 22,
            height: 2,
            color: AppColors.saffron.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 10),
          Text(
            LocaleKeys.splashLoading.tr(),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 22,
            height: 2,
            color: AppColors.greenExtraLight.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
