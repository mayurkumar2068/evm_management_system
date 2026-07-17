import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/storage/secure_storage_service.dart';
import 'package:evm_management_system/features/onboarding/presentation/widgets/language_selection_sheet.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// First-run onboarding carousel. Completing or skipping it persists the
/// "seen" flag, after which the router guard routes to login.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.tag,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.accent,
  });

  final String tag;
  final String title;
  final String description;
  final IconData icon;
  final LinearGradient gradient;
  final Color accent;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  late final List<_OnboardingSlide> _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      tag: LocaleKeys.onboardingSecurityTag.tr(),
      title: LocaleKeys.onboardingSecurityTitle.tr(),
      description: LocaleKeys.onboardingSecurityDesc.tr(),
      icon: Icons.shield_outlined,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFF0A2E8A), AppColors.primary],
      ),
      accent: AppColors.primary,
    ),
    _OnboardingSlide(
      tag: LocaleKeys.onboardingProductivityTag.tr(),
      title: LocaleKeys.onboardingProductivityTitle.tr(),
      description: LocaleKeys.onboardingProductivityDesc.tr(),
      icon: Icons.qr_code_2_outlined,
      gradient: AppGradients.green,
      accent: AppColors.green,
    ),
    _OnboardingSlide(
      tag: LocaleKeys.onboardingAnalyticsTag.tr(),
      title: LocaleKeys.onboardingAnalyticsTitle.tr(),
      description: LocaleKeys.onboardingAnalyticsDesc.tr(),
      icon: Icons.insights_outlined,
      gradient: AppGradients.saffron,
      accent: AppColors.secondary,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Final onboarding step: collect the preferred language, then enter the app
  /// without a login. The guest session moves the router to the dashboard.
  Future<void> _complete() async {
    await showLanguageSelectionSheet(context);
    if (!mounted) return;
    // Persist "seen" first (no router side effect) so the next launch skips
    // onboarding even though we authenticate as a guest below.
    await AppServices.secureStorage.write(
      SecureStorageKeys.onboardingSeen,
      'true',
    );
    AppServices.onboarding.seen = true;
    if (!mounted) return;
    await AppServices.auth.continueAsGuest();
  }

  void _next() {
    if (_index < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final _OnboardingSlide slide = _slides[_index];
    final bool isLast = _index == _slides.length - 1;
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: <Widget>[
          // Shared brand footer — same tricolor wave used on the splash.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height * 0.20,
            child: const TricolorWave(),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  // Reused brand emblem, top-right like the official mark.
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Row(
                      children: <Widget>[Spacer(), BrandLogo(width: 54)],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _slides.length,
                      onPageChanged: (int i) => setState(() => _index = i),
                      itemBuilder: (_, int i) => _SlideArt(slide: _slides[i]),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      for (int i = 0; i < _slides.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _index ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _index
                                ? slide.accent
                                : AppColors.slate200,
                            borderRadius: AppRadius.brPill,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      children: <Widget>[
                        if (!isLast) ...<Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _complete,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(54),
                                backgroundColor: Colors.white,
                                side: const BorderSide(
                                  color: AppColors.slate200,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppRadius.brMd,
                                ),
                                foregroundColor: AppColors.slate500,
                              ),
                              child: Text(LocaleKeys.commonSkip.tr()),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          flex: 2,
                          child: AppGradientButton(
                            label: isLast
                                ? LocaleKeys.commonGetStarted.tr()
                                : LocaleKeys.commonContinue.tr(),
                            icon: Icons.arrow_forward_rounded,
                            gradient: AppGradients.green,
                            onPressed: _next,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideArt extends StatelessWidget {
  const _SlideArt({required this.slide});

  static const Color _titleGreen = Color(0xFF1B7A3C);

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Soft accent disc with the slide icon (white-theme version of the
          // old gradient hero art).
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              color: slide.accent.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 54, color: slide.accent),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: slide.accent.withValues(alpha: 0.1),
              borderRadius: AppRadius.brPill,
            ),
            child: Text(
              slide.tag.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                color: slide.accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium.copyWith(color: _titleGreen),
          ),
          const SizedBox(height: 12),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.slate500,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
