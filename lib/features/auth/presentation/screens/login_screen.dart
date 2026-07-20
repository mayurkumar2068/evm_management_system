import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/constants/feature_flags.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/features/auth/presentation/states/auth_state.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// App entry after onboarding / session expiry — splash-style gateway.
///
/// No credential fields. Officer continues as guest into Dashboard / Reports /
/// Profile. Pooling Survey and पीठासीन still use [ServiceLoginScreen].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final Worker _authWorker;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _authWorker = ever<AuthState>(AppServices.auth.authState, (
      AuthState state,
    ) {
      if (state.status == AuthStatus.unauthenticated && state.failure != null) {
        AppSnackbar.error(context, state.failure!.localizationKey.tr());
      }
    });
  }

  @override
  void dispose() {
    _authWorker.dispose();
    super.dispose();
  }

  Future<void> _enter(AppRoute destination) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AppServices.auth.continueAsGuest();
      if (!mounted) return;
      await Get.offAllNamed<dynamic>(destination.path);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final AuthState state = AppServices.auth.authState.value;
      final bool loading = _busy || state.isBusy;
      final double top = MediaQuery.of(context).padding.top;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: <Widget>[
            const _SoftBackdrop(),
            SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, top + 12, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const _SoftLoginHero(),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadius.brXl,
                        border: Border.all(color: AppColors.outline),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'स्वागत है',
                            style: AppTextStyles.titleLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'सेवा चुनें और आगे बढ़ें',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.slate500,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _NavTile(
                            icon: AppIcons.dashboard,
                            color: AppColors.primary,
                            title: LocaleKeys.menuDashboard.tr(),
                            subtitle: 'मुख्य सेवाएँ और सर्वे',
                            enabled: !loading,
                            onTap: () => _enter(AppRoute.dashboard),
                          ),
                          const SizedBox(height: 10),
                          _NavTile(
                            icon: AppIcons.reports,
                            color: AppColors.green,
                            title: LocaleKeys.regReports.tr(),
                            subtitle: 'रिपोर्ट और सारांश',
                            enabled: !loading,
                            onTap: () => _enter(AppRoute.reports),
                          ),
                          const SizedBox(height: 10),
                          _NavTile(
                            icon: AppIcons.profile,
                            color: AppColors.primaryDark,
                            title: LocaleKeys.profileTitle.tr(),
                            subtitle: 'खाता और सेटिंग्स',
                            enabled: !loading,
                            onTap: () => _enter(AppRoute.profile),
                          ),
                          if (!kHideEvmScanning) ...<Widget>[
                            const SizedBox(height: 10),
                            _NavTile(
                              icon: AppIcons.stockRegister,
                              color: AppColors.teal,
                              title: LocaleKeys.regInventory.tr(),
                              subtitle: 'ईवीएम सूची',
                              enabled: !loading,
                              onTap: () => _enter(AppRoute.masterStockRegister),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 54,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: AppGradients.primaryButton,
                                borderRadius: AppRadius.brPill,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.28,
                                    ),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Material(
                                type: MaterialType.transparency,
                                child: InkWell(
                                  onTap: loading
                                      ? null
                                      : () => _enter(AppRoute.dashboard),
                                  borderRadius: AppRadius.brPill,
                                  child: Center(
                                    child: loading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              Text(
                                                LocaleKeys.commonGetStarted
                                                    .tr(),
                                                style: AppTextStyles.titleSmall
                                                    .copyWith(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.arrow_forward_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      LocaleKeys.appCopyright.tr(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.slate400,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: AppColors.slate50,
        borderRadius: AppRadius.brLg,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppRadius.brLg,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brLg,
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: AppRadius.brMd,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.slate500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: color.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftBackdrop extends StatelessWidget {
  const _SoftBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            top: 140,
            left: -90,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.green.withValues(alpha: 0.08),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftLoginHero extends StatelessWidget {
  const _SoftLoginHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppGradients.header,
        borderRadius: AppRadius.brXl,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -40,
            top: -50,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const ClipOval(
                        child: BrandLogo(width: 40),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            LocaleKeys.splashTitle.tr(),
                            style: AppTextStyles.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            LocaleKeys.dashboardBrandSubtitle.tr(),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _TrustBadge(
                      label: LocaleKeys.authTrustNic.tr(),
                      color: Colors.white,
                    ),
                    _TrustBadge(
                      label: LocaleKeys.authTrustGovt.tr(),
                      color: Colors.white,
                    ),
                    _TrustBadge(
                      label: LocaleKeys.authTrustEncrypted.tr(),
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: AppRadius.brPill,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
