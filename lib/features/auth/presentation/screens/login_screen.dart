import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/features/auth/presentation/states/auth_state.dart';
import 'package:evm_management_system/features/service_auth/presentation/widgets/service_auth_chrome.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

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
        backgroundColor: context.appBackground,
        body: Stack(
          children: <Widget>[
            const ServiceAuthBackdrop(leftOrbTop: 140),
            SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, top + 12, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    ServiceAuthHero(
                      title: LocaleKeys.dashboardBrandTitle.tr(),
                      showBottomOrb: false,
                      compactTitle: true,
                    ),
                    const SizedBox(height: 20),
                    ServiceAuthFormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            LocaleKeys.authGatewayWelcome.tr(),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.titleLarge.copyWith(
                              color: context.appOnSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _NavTile(
                            icon: AppIcons.dashboard,
                            color: AppColors.primary,
                            title: LocaleKeys.menuDashboard.tr(),
                            enabled: !loading,
                            onTap: () => _enter(AppRoute.dashboard),
                          ),
                          const SizedBox(height: 10),
                          _NavTile(
                            icon: AppIcons.profile,
                            color: AppColors.primaryDark,
                            title: LocaleKeys.profileTitle.tr(),
                            enabled: !loading,
                            onTap: () => _enter(AppRoute.profile),
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
    });
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: context.appChip,
        borderRadius: AppRadius.brLg,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppRadius.brLg,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brLg,
              border: Border.all(color: context.appOutline),
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
                  child: Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.appOnSurface,
                    ),
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
