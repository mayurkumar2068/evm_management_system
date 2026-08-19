import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/features/dashboard/presentation/models/dashboard_models.dart';
import 'package:evm_management_system/features/dashboard/presentation/utils/dashboard_webview_launcher.dart';
import 'package:evm_management_system/features/dashboard/presentation/widgets/dashboard_brand.dart';
import 'package:evm_management_system/features/dashboard/presentation/widgets/dashboard_stat_strip.dart';
import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardServicesGrid extends StatelessWidget {
  const DashboardServicesGrid({required this.services, super.key});
  final List<DashboardService> services;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    const double spacing = 12;
    final double tileWidth =
        (screenWidth - (DashboardGap.page * 2) - spacing) / 2;
    final bool hasDesc = services.any(
      (DashboardService s) => s.desc.trim().isNotEmpty,
    );
    final double tileHeight = (hasDesc ? tileWidth * 0.95 : tileWidth * 0.68)
        .clamp(92.0, hasDesc ? 156.0 : 112.0);
    final double aspectRatio = tileWidth / tileHeight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DashboardGap.page),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: aspectRatio,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final s = services[index];
          return _ServiceCard(
            service: s,
            onTap: () => _openService(context, s),
          );
        },
      ),
    );
  }

  Future<void> _openService(BuildContext context, DashboardService s) async {
    ServiceSession? session = AppServices.serviceAuth.session.value;

    if (s.requiresServiceLogin) {
      final bool kindMismatch = s.requiredLoginKind != null &&
          session != null &&
          session.kind != s.requiredLoginKind;
      final bool needsLogin =
          s.forceFreshLogin || session == null || kindMismatch;
      if (needsLogin) {
        await Get.toNamed<dynamic>(
          AppRoute.serviceLogin.path,
          arguments: s.title,
        );
        session = AppServices.serviceAuth.session.value;
        if (session == null) return;
        if (s.requiredLoginKind != null &&
            session.kind != s.requiredLoginKind) {
          return;
        }
      }
    }

    if (s.routeName != null && s.routeName!.isNotEmpty) {
      if (s.routeName == AppRoute.presidingDashboard.path) {
        await Get.toNamed<dynamic>(AppRoute.presidingPoDetails.path);
        return;
      }
      await Get.toNamed<dynamic>(s.routeName!);
      return;
    }

    final bool isOnline = await AppServices.connectivity.isOnline;
    if (!isOnline) {
      await Get.toNamed<dynamic>(AppRoute.offlineHub.path, arguments: s.title);
      return;
    }

    final String url = DashboardWebViewLauncher.launchUrl(
      baseUrl: s.url,
      session: session,
      passSessionContext: s.passSessionContext,
      openAsExternalPortal: s.openAsExternalPortal,
    );

    await Get.toNamed<dynamic>(
      AppRoute.webView.path,
      arguments: DashboardWebViewLauncher.args(
        title: s.title,
        url: url,
        openAsExternalPortal: s.openAsExternalPortal,
        showLogoutButton: s.requiresServiceLogin,
      ),
    );
  }
}

/// Classic service tile — white card, tinted icon, title (+ optional desc).
class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onTap});

  final DashboardService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool hasDesc = service.desc.trim().isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: DashboardStatStrip.cardDecoration(
          context,
        ).copyWith(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    service.color.withValues(alpha: 0.16),
                    service.color.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: AppRadius.brMd,
                border: Border.all(
                  color: service.color.withValues(alpha: 0.12),
                ),
              ),
              child: Icon(service.icon, size: 22, color: service.color),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    service.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: context.appOnSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),
                ),
                if (!hasDesc) ...<Widget>[],
              ],
            ),
            if (hasDesc) ...<Widget>[
              const SizedBox(height: 2),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      service.desc,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: context.appMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
