import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/utils/string_extensions.dart';
import 'package:evm_management_system/features/dashboard/presentation/widgets/dashboard_brand.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: context.appOutline),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const BrandLogo(width: 44),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  LocaleKeys.dashboardBrandTitle.tr(),
                  maxLines: 2,
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.appOnSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'हर वोट कीमती • हर निकाय महत्वपूर्ण',
                  maxLines: 2,
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: context.isAppDark
                        ? context.appMuted
                        : const Color(0xFF1A3A6B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _RoundIcon(
            icon: Icons.notifications_none_rounded,
            badge: pending,
            onTap: () => Get.toNamed<dynamic>(AppRoute.notifications.path),
          ),
          const SizedBox(width: 8),
          _Avatar(
            name: name,
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
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[AppColors.primary, AppColors.green],
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: context.appOutline),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08101E17),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 22, color: context.appOnSurface),
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
                  border: Border.all(
                    color: context.isAppDark
                        ? context.appSurface
                        : Colors.white,
                    width: 2,
                  ),
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
