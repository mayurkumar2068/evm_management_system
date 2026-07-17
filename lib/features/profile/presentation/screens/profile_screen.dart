import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/settings/app_preferences_actions.dart';
import 'package:evm_management_system/core/utils/string_extensions.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:evm_management_system/shared/models/device_record.dart';
import 'package:evm_management_system/shared/widgets/language_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';

/// Profile — officer identity hero, quick stats and a navigation menu to the
/// settings, audit, sync, search and notification modules.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  List<_MenuItem> _buildMenu() => <_MenuItem>[
    _MenuItem(
      Icons.settings_outlined,
      LocaleKeys.profileSettings.tr(),
      LocaleKeys.profileSettingsSub.tr(),
      AppRoute.settings,
      AppColors.primary,
    ),
    _MenuItem(
      Icons.shield_outlined,
      LocaleKeys.profileAudit.tr(),
      LocaleKeys.profileAuditSub.tr(),
      AppRoute.auditTrail,
      AppColors.purple,
    ),
    _MenuItem(
      Icons.wifi_rounded,
      LocaleKeys.profileSync.tr(),
      LocaleKeys.profileSyncSub.tr(),
      AppRoute.syncManagement,
      AppColors.green,
    ),
    _MenuItem(
      Icons.search_rounded,
      LocaleKeys.profileSearch.tr(),
      LocaleKeys.profileSearchSub.tr(),
      AppRoute.search,
      AppColors.secondary,
    ),
    _MenuItem(
      Icons.notifications_none_rounded,
      LocaleKeys.profileNotifications.tr(),
      LocaleKeys.profileNotificationsSub.tr(),
      AppRoute.notifications,
      AppColors.teal,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = AppServices.auth.authState.value.user;
      final String name = user?.fullName ?? LocaleKeys.dashboardGuest.tr();
      final String officerId = user?.officerId ?? '—';
      final String role = user?.designation ?? LocaleKeys.dashboardRole.tr();
      final String initials = name.initials;

      final List<DeviceRecord> all = AppServices.deviceRecords.records;
      final DeviceStats stats = AppServices.deviceRecords.statsFor(null);
      final DateTime weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final int thisWeek = all
          .where((DeviceRecord r) => r.timestamp.isAfter(weekAgo))
          .length;

      final Locale currentLocale = AppServices.settings.locale.value;
      final ThemeMode currentThemeMode = AppServices.settings.themeMode.value;
      final List<_MenuItem> menu = _buildMenu();

      return Container(
        color: AppColors.background,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: <Widget>[
            _hero(
              name,
              officerId,
              role,
              initials,
              user?.districtCode ?? LocaleKeys.dashboardDistrictUnset.tr(),
            ),
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppCard(
                  child: Row(
                    children: <Widget>[
                      _Stat(
                        value: '${stats.total}',
                        label: LocaleKeys.regInventory.tr(),
                        color: AppColors.primary,
                      ),
                      _Stat(
                        value: '$thisWeek',
                        label: LocaleKeys.profileThisWeek.tr(),
                        color: AppColors.green,
                      ),
                      _Stat(
                        value: '${stats.pending}',
                        label: LocaleKeys.statsPending.tr(),
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: <Widget>[
                  for (final _MenuItem m in menu)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _MenuRow(
                        item: m,
                        onTap: () => Get.toNamed<dynamic>(m.route.path),
                      ),
                    ),
                  const SizedBox(height: 8),
                  _PreferenceRow(
                    title: LocaleKeys.settingsLanguage.tr(),
                    subtitle: languageLabelFor(currentLocale),
                    icon: Icons.language_rounded,
                    onTap: () => _showLanguagePicker(context),
                  ),
                  const SizedBox(height: 8),
                  _PreferenceRow(
                    title: LocaleKeys.settingsTheme.tr(),
                    subtitle: currentThemeMode == ThemeMode.dark
                        ? LocaleKeys.settingsDarkMode.tr()
                        : LocaleKeys.settingsLightMode.tr(),
                    icon: Icons.dark_mode_outlined,
                    trailing: Switch.adaptive(
                      value: currentThemeMode == ThemeMode.dark,
                      onChanged: (_) => toggleAppTheme(),
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withValues(
                        alpha: 0.35,
                      ),
                    ),
                    onTap: () => toggleAppTheme(),
                  ),
                  const SizedBox(height: 4),
                  _ActionRow(
                    icon: Icons.key_rounded,
                    iconBg: AppColors.warningSurface,
                    iconColor: const Color(0xFFF59E0B),
                    title: LocaleKeys.profileChangePassword.tr(),
                    subtitle: LocaleKeys.profileLastChanged.tr(args: ['30']),
                    onTap: () {},
                  ),
                  const SizedBox(height: 8),
                  _SignOutButton(onTap: AppServices.auth.signOut),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _hero(
    String name,
    String officerId,
    String role,
    String initials,
    String location,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 36),
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
      child: Column(
        children: <Widget>[
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFF60A5FA), Color(0xFF3B82F6)],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 3,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: Colors.white,
                    fontSize: 28,
                  ),
                ),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0A4DCC),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: AppTextStyles.titleLarge.copyWith(
              color: Colors.white,
              fontSize: 22,
            ),
          ),
          Text(
            role,
            style: AppTextStyles.caption.copyWith(
              color: const Color(0xFFAFC6FF),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            officerId,
            style: AppTextStyles.caption.copyWith(
              color: const Color(0xFF7E9BE0),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: <Widget>[
              _HeroChip(icon: Icons.location_on_outlined, label: location),
              _HeroChip(
                icon: Icons.bolt_rounded,
                label: LocaleKeys.statsActive.tr(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showLanguagePicker(BuildContext context) async {
    final Locale currentLocale = AppServices.settings.locale.value;
    await showLanguagePickerSheet(
      context,
      currentLocale: currentLocale,
      onLocaleSelected: (Locale locale) =>
          applyAppLocale(context: context, locale: locale),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.icon, this.label, this.sub, this.route, this.color);
  final IconData icon;
  final String label;
  final String sub;
  final AppRoute route;
  final Color color;
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(
              color: color,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.slate400,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: AppRadius.brPill,
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 11, color: const Color(0xFFAFC6FF)),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item, required this.onTap});
  final _MenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.08),
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(item.icon, size: 18, color: item.color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate700,
                  ),
                ),
                Text(
                  item.sub,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.slate400,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppColors.slate300,
          ),
        ],
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.slate100,
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.slate400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate700,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.slate400,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppColors.slate300,
          ),
        ],
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.errorSurface,
      borderRadius: AppRadius.brLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brLg,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brLg,
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  borderRadius: AppRadius.brMd,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 17,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                LocaleKeys.profileSignOut.tr(),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
