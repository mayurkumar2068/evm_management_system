import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/webview/url/webview_url_utils.dart';
import 'package:evm_management_system/core/utils/date_time_extensions.dart';
import 'package:evm_management_system/core/utils/string_extensions.dart';
import 'package:evm_management_system/features/dashboard/presentation/models/dashboard_models.dart';
import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:evm_management_system/features/web_portal/presentation/screens/web_view_screen.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:evm_management_system/shared/models/activity_event.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Local brand tints for the dashboard.
class DashboardBrand {
  const DashboardBrand._();
  static const Color green = Color(0xFF0F8A5F);
  static const Color greenDark = Color(0xFF0B6B49);
  static const Color saffron = Color(0xFFFF8C00);
  static const Color ink = Color(0xFF0F1E17);
  static const Color surface = Color(0xFFF8FAFC);
}

/// Local spacing constants for the dashboard.
class DashboardGap {
  const DashboardGap._();
  static const double page = 20;
  static const double section = 24;
  static const double headerToContent = 12;
}

// ── Header ──────────────────────────────────────────────────────────────────

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({required this.name, required this.pending, super.key});

  final String name;
  final int pending;

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DashboardGap.page,
        top + 16,
        DashboardGap.page,
        8,
      ),
      child: Row(
        children: <Widget>[
          const BrandLogo(width: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  LocaleKeys.dashboardBrandTitle.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: DashboardBrand.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    height: 1.1,
                  ),
                ),
                Text(
                  LocaleKeys.dashboardBrandSubtitle.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.slate500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _RoundIcon(
            icon: Icons.notifications_none_rounded,
            badge: pending,
            onTap: () => Get.toNamed<dynamic>(AppRoute.notifications.path),
          ),
          const SizedBox(width: 12),
          _Avatar(
            name: name,
            // Profile is a bottom-nav tab, so switch to it with go (not push)
            // to avoid stacking a second copy inside the shell navigator.
            onTap: () => Get.offNamed<dynamic>(AppRoute.profile.path),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.onTap});
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: DashboardBrand.green.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[DashboardBrand.green, DashboardBrand.greenDark],
          ),
        ),
        child: Text(
          name.initials,
          style: AppTextStyles.titleSmall.copyWith(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap, this.badge = 0});

  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.slate100),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08101E17),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 22, color: AppColors.slate700),
          ),
          if (badge > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: DashboardBrand.saffron,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  badge > 9 ? '9+' : '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Welcome card ──────────────────────────────────────────────────────────

class DashboardWelcomeCard extends StatelessWidget {
  const DashboardWelcomeCard({
    required this.name,
    required this.designation,
    required this.district,
    super.key,
  });

  final String name;
  final String designation;
  final String district;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: AppRadius.brXl,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[DashboardBrand.green, DashboardBrand.saffron],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: DashboardBrand.green.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -20,
            bottom: -30,
            child: Icon(
              Icons.account_balance_outlined,
              size: 140,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                LocaleKeys.dashboardGreeting.tr(args: <String>[name]),
                style: AppTextStyles.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                designation,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _Chip(icon: Icons.location_on_outlined, label: district),
                  const _StatusPill(),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: AppRadius.brPill,
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.brPill,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: DashboardBrand.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            LocaleKeys.dashboardStatusActive.tr(),
            style: AppTextStyles.caption.copyWith(
              color: DashboardBrand.greenDark,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick stats ─────────────────────────────────────────────────────────────

class DashboardStatStrip extends StatelessWidget {
  const DashboardStatStrip({required this.stats, super.key});
  final List<DashboardStat> stats;

  static BoxDecoration cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: AppRadius.brLg,
    border: Border.all(color: AppColors.slate100.withValues(alpha: 0.5)),
    boxShadow: const <BoxShadow>[
      BoxShadow(color: Color(0x08101E17), blurRadius: 16, offset: Offset(0, 6)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DashboardGap.page),
        physics: const BouncingScrollPhysics(),
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, int i) => _StatCard(stat: stats[i]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});
  final DashboardStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      padding: const EdgeInsets.all(14),
      decoration: DashboardStatStrip.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.12),
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(stat.icon, size: 20, color: stat.color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                stat.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleLarge.copyWith(
                  color: DashboardBrand.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                stat.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.slate500,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Services grid ─────────────────────────────────────────────────────────

class DashboardServicesGrid extends StatelessWidget {
  const DashboardServicesGrid({required this.services, super.key});
  final List<DashboardService> services;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DashboardGap.page),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 22,
          crossAxisSpacing: 22,
          childAspectRatio: 1.18,
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

    // 1. Check for service login if required
    if (s.requiresServiceLogin) {
      if (session == null) {
        await Get.toNamed<dynamic>(AppRoute.serviceLogin.path, arguments: s.title);
        session = AppServices.serviceAuth.session.value;
        if (session == null) return; // User cancelled or failed login
      }
    }

    // 2. Handle Native Routes
    if (s.routeName != null && s.routeName!.isNotEmpty) {
      await Get.toNamed<dynamic>(s.routeName!);
      return;
    }

    // 3. Handle External Web URLs
    final bool isOnline = await AppServices.connectivity.isOnline;
    if (!isOnline) {
      await Get.toNamed<dynamic>(AppRoute.offlineHub.path);
      return;
    }

    final String token = session?.token ?? '';
    final String url = token.isNotEmpty
        ? appendWebViewSurveyContext(
            s.url,
            token: token,
            userId: session?.userId,
            urbanRural: session?.section,
          )
        : s.url;

    await Get.toNamed<dynamic>(
      AppRoute.webView.path,
      arguments: WebViewArgs(title: s.title, url: url),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onTap});
  final DashboardService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: DashboardStatStrip.cardDecoration().copyWith(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    service.color.withValues(alpha: 0.15),
                    service.color.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: AppRadius.brLg,
                border: Border.all(
                  color: service.color.withValues(alpha: 0.12),
                ),
              ),
              child: Icon(service.icon, size: 28, color: service.color),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  service.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: DashboardBrand.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        service.desc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.slate400,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: service.color.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recent activity ─────────────────────────────────────────────────────────

class DashboardActivityList extends StatelessWidget {
  const DashboardActivityList({required this.events, super.key});
  final List<ActivityEvent> events;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tiles = events.isEmpty
        ? _fallbackTiles()
        : <Widget>[
            for (final ActivityEvent e in events.take(3))
              _ActivityTile(
                icon: _cfg(e.type).icon,
                color: _cfg(e.type).color,
                title: e.title,
                time: e.timestamp.relativeTime,
              ),
          ];
    return Column(children: tiles);
  }

  List<Widget> _fallbackTiles() => <Widget>[
    _ActivityTile(
      icon: Icons.assignment_turned_in_outlined,
      color: DashboardBrand.green,
      title: LocaleKeys.dashboardActInspection.tr(),
      time: LocaleKeys.timeJustNow.tr(),
    ),
    _ActivityTile(
      icon: Icons.verified_outlined,
      color: AppColors.primary,
      title: LocaleKeys.dashboardActExpenditure.tr(),
      time: LocaleKeys.timeHours.tr(args: const <String>['2']),
    ),
    _ActivityTile(
      icon: Icons.location_on_outlined,
      color: DashboardBrand.saffron,
      title: LocaleKeys.dashboardActBooth.tr(),
      time: LocaleKeys.timeYesterday.tr(),
    ),
  ];

  static ({IconData icon, Color color}) _cfg(ActivityType t) => switch (t) {
    ActivityType.registered => (
      icon: Icons.add_circle_outline,
      color: AppColors.primary,
    ),
    ActivityType.scanned => (
      icon: Icons.qr_code_rounded,
      color: DashboardBrand.green,
    ),
    ActivityType.updated => (
      icon: Icons.edit_outlined,
      color: DashboardBrand.saffron,
    ),
    ActivityType.login => (
      icon: Icons.lock_outline_rounded,
      color: AppColors.purple,
    ),
    ActivityType.sync => (icon: Icons.sync_rounded, color: AppColors.teal),
    ActivityType.exported => (
      icon: Icons.download_rounded,
      color: AppColors.slate600,
    ),
  };
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.time,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: DashboardStatStrip.cardDecoration(),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.slate700,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            time,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.slate400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Alert banner ──────────────────────────────────────────────────────────

class DashboardAlertBanner extends StatelessWidget {
  const DashboardAlertBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: AppRadius.brXl,
        boxShadow: [
          BoxShadow(
            color: DashboardBrand.greenDark.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[DashboardBrand.greenDark, DashboardBrand.green],
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: AppRadius.brMd,
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  LocaleKeys.dashboardAlertTitle.tr(),
                  style: AppTextStyles.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LocaleKeys.dashboardAlertSubtitle.tr(),
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────

class DashboardSectionHeader extends StatelessWidget {
  const DashboardSectionHeader({
    required this.title,
    this.onViewAll,
    super.key,
  });

  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DashboardGap.page),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                color: DashboardBrand.ink,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: DashboardBrand.green.withValues(alpha: 0.08),
                  borderRadius: AppRadius.brSm,
                ),
                child: Row(
                  children: <Widget>[
                    Text(
                      LocaleKeys.dashboardViewAll.tr().replaceAll(' →', ''),
                      style: AppTextStyles.caption.copyWith(
                        color: DashboardBrand.green,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: DashboardBrand.green,
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
