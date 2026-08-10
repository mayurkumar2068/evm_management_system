import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/constants/feature_flags.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/design_system/mpsec/mpsec_design_system.dart';
import 'package:evm_management_system/features/dashboard/presentation/utils/dashboard_webview_launcher.dart';
import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Profile Sign In → pick a login-required service (skips gateway guest step).
Future<void> showProfileLoginRequiredSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    builder: (BuildContext ctx) {
      final double bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(top: 22),
              child: _ProfileLoginSheet(),
            ),
            Positioned(
              top: 0,
              right: 12,
              child: _CloseButton(onTap: () => Navigator.pop(ctx)),
            ),
          ],
        ),
      );
    },
  );
}

class _LoginServiceOption {
  const _LoginServiceOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.kind,
    required this.tabLabel,
    this.routeName,
    this.url,
    this.openAsExternalPortal = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final ServiceLoginKind kind;

  /// Dashboard tab name shown as the card tag (e.g. निर्वाचन संबंधी सेवाएँ).
  final String tabLabel;
  final String? routeName;
  final String? url;
  final bool openAsExternalPortal;
}

class _ProfileLoginSheet extends StatelessWidget {
  const _ProfileLoginSheet();

  List<_LoginServiceOption> get _options {
    final String electionTab = LocaleKeys.dashboardAboutElections.tr();
    final List<_LoginServiceOption> items = <_LoginServiceOption>[
      _LoginServiceOption(
        title: LocaleKeys.serviceBoothTitle.tr(),
        subtitle: LocaleKeys.profileLoginPickBoothSub.tr(),
        icon: Icons.location_on_outlined,
        color: AppColors.primaryBright,
        kind: ServiceLoginKind.survey,
        tabLabel: electionTab,
        url: AppServices.config.surveyWebBaseUrl,
      ),
      _LoginServiceOption(
        title: LocaleKeys.servicePresidingTitle.tr(),
        subtitle: LocaleKeys.servicePresidingDesc.tr(),
        icon: Icons.how_to_vote_rounded,
        color: MpSecTokens.softBlueDark,
        kind: ServiceLoginKind.presiding,
        tabLabel: electionTab,
        routeName: AppRoute.presidingDashboard.path,
      ),
    ];
    if (!kHideExpenditureAccount) {
      items.insert(
        1,
        _LoginServiceOption(
          title: LocaleKeys.serviceExpenditureTitle.tr(),
          subtitle: LocaleKeys.profileLoginPickExpenditureSub.tr(),
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.saffron,
          kind: ServiceLoginKind.survey,
          tabLabel: electionTab,
          url: AppServices.config.candidateExpenditureUrl,
          openAsExternalPortal: true,
        ),
      );
    }
    return items;
  }

  Future<void> _open(_LoginServiceOption option) async {
    Get.back<void>();
    await Get.toNamed<dynamic>(
      AppRoute.serviceLogin.path,
      arguments: option.title,
    );
    final ServiceSession? session = AppServices.serviceAuth.session.value;
    if (session == null) return;
    if (session.kind != option.kind) return;

    if (option.routeName != null && option.routeName!.isNotEmpty) {
      if (option.routeName == AppRoute.presidingDashboard.path) {
        await Get.toNamed<dynamic>(AppRoute.presidingPoDetails.path);
        return;
      }
      await Get.toNamed<dynamic>(option.routeName!);
      return;
    }

    final String? baseUrl = option.url?.trim();
    if (baseUrl == null || baseUrl.isEmpty) return;

    final bool isOnline = await AppServices.connectivity.isOnline;
    if (!isOnline) {
      await Get.toNamed<dynamic>(
        AppRoute.offlineHub.path,
        arguments: option.title,
      );
      return;
    }

    final String url = DashboardWebViewLauncher.launchUrl(
      baseUrl: baseUrl,
      session: session,
      passSessionContext: !option.openAsExternalPortal,
      openAsExternalPortal: option.openAsExternalPortal,
    );
    await Get.toNamed<dynamic>(
      AppRoute.webView.path,
      arguments: DashboardWebViewLauncher.args(
        title: option.title,
        url: url,
        openAsExternalPortal: option.openAsExternalPortal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_LoginServiceOption> options = _options;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Colors.white.withValues(alpha: 0.96),
                const Color(0xFFEFF6FF).withValues(alpha: 0.94),
                const Color(0xFFECFDF5).withValues(alpha: 0.92),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.85),
                width: 1.4,
              ),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: AppGradients.primaryButton,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      LocaleKeys.profileLoginPickTitle.tr(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      LocaleKeys.profileLoginPickSubtitle.tr(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.slate500,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (int i = 0; i < options.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(height: 10),
                      _LoginServiceCard(
                        option: options[i],
                        onTap: () => _open(options[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginServiceCard extends StatelessWidget {
  const _LoginServiceCard({
    required this.option,
    required this.onTap,
  });

  final _LoginServiceOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.appOutline),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: option.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(option.icon, color: option.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            option.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: context.appOnSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.28),
                              ),
                            ),
                            child: Text(
                              option.tabLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (option.subtitle.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        option.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: context.appMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: option.color.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.slate200),
          ),
          child: const Icon(
            Icons.close_rounded,
            size: 20,
            color: AppColors.slate700,
          ),
        ),
      ),
    );
  }
}
