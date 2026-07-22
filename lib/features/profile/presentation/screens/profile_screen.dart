import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/constants/feature_flags.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/settings/app_preferences_actions.dart';
import 'package:evm_management_system/core/utils/string_extensions.dart';
import 'package:evm_management_system/features/auth/domain/entities/auth_user.dart';
import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:evm_management_system/features/offline/presentation/widgets/offline_status_sheet.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:evm_management_system/shared/models/device_record.dart';
import 'package:evm_management_system/shared/widgets/language_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Officer profile — real session data + language / theme / services.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Touch reactive deps so language / theme / sessions rebuild immediately.
      AppServices.settings.locale.value;
      final ThemeMode currentThemeMode = AppServices.settings.themeMode.value;
      final AuthUser? authUser = AppServices.auth.authState.value.user;
      final ServiceSession? session = AppServices.serviceAuth.session.value;
      final _ProfileViewData data = _ProfileViewData.from(
        authUser: authUser,
        session: session,
      );

      final Locale currentLocale = AppServices.settings.locale.value;
      final double top = MediaQuery.of(context).padding.top;

      return ColoredBox(
        color: context.appBackground,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, top + 12, 20, 120),
          children: <Widget>[
            _OfficerHero(
              name: data.name,
              role: data.role,
              officerId: data.primaryId,
              initials: data.name.initials,
              location: data.location,
              isActive: session != null && !session.isExpired,
            ),
            if (data.detailRows.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              _SectionLabel(LocaleKeys.profileDetails.tr()),
              const SizedBox(height: 10),
              _GroupCard(
                children: <Widget>[
                  for (int i = 0; i < data.detailRows.length; i++) ...<Widget>[
                    if (i > 0) const _RowDivider(),
                    _DetailRow(
                      label: data.detailRows[i].label,
                      value: data.detailRows[i].value,
                    ),
                  ],
                ],
              ),
            ],
            if (!kHideEvmScanning) ...<Widget>[
              const SizedBox(height: 16),
              _InventoryStats(),
            ],
            const SizedBox(height: 22),
            _SectionLabel(LocaleKeys.profileAccount.tr()),
            const SizedBox(height: 10),
            _GroupCard(
              children: <Widget>[
                _RowTile(
                  icon: Icons.language_rounded,
                  color: AppColors.primary,
                  title: LocaleKeys.settingsLanguage.tr(),
                  subtitle: languageLabelFor(currentLocale),
                  onTap: () => _showLanguagePicker(context),
                ),
                const _RowDivider(),
                _RowTile(
                  icon: Icons.dark_mode_outlined,
                  color: AppColors.primaryDark,
                  title: LocaleKeys.settingsTheme.tr(),
                  subtitle: currentThemeMode == ThemeMode.dark
                      ? LocaleKeys.settingsDarkMode.tr()
                      : LocaleKeys.settingsLightMode.tr(),
                  trailing: Switch.adaptive(
                    value: currentThemeMode == ThemeMode.dark,
                    onChanged: (_) => toggleAppTheme(),
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
                  ),
                  onTap: () => toggleAppTheme(),
                ),
                const _RowDivider(),
                _RowTile(
                  icon: Icons.notifications_none_rounded,
                  color: AppColors.teal,
                  title: LocaleKeys.profileNotifications.tr(),
                  subtitle: LocaleKeys.profileNotificationsSub.tr(),
                  onTap: () =>
                      Get.toNamed<dynamic>(AppRoute.notifications.path),
                ),
                const _RowDivider(),
                _RowTile(
                  icon: Icons.cloud_off_outlined,
                  color: AppColors.green,
                  title: LocaleKeys.settingsOfflineStorage.tr(),
                  subtitle: LocaleKeys.profileSyncSub.tr(),
                  onTap: () => showOfflineStatusSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _SignOutButton(onTap: () => _confirmSignOut(context)),
          ],
        ),
      );
    });
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final bool confirmed = await AppDialog.confirm(
      context,
      title: LocaleKeys.profileSignOutTitle.tr(),
      message: LocaleKeys.profileSignOutMessage.tr(),
      confirmLabel: LocaleKeys.profileSignOut.tr(),
      cancelLabel: LocaleKeys.commonCancel.tr(),
      destructive: true,
    );
    if (!confirmed) return;
    await AppServices.auth.signOut();
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

class _ProfileViewData {
  const _ProfileViewData({
    required this.name,
    required this.role,
    required this.primaryId,
    required this.location,
    required this.detailRows,
  });

  factory _ProfileViewData.from({
    required AuthUser? authUser,
    required ServiceSession? session,
  }) {
    final bool hasSessionName =
        session != null && session.name.trim().isNotEmpty;
    final bool isGuest = authUser?.isGuest == true && !hasSessionName;

    final String name = hasSessionName
        ? session.name.trim()
        : (isGuest
              ? LocaleKeys.dashboardGuest.tr()
              : (authUser?.fullName.trim().isNotEmpty == true
                    ? authUser!.fullName.trim()
                    : LocaleKeys.dashboardGuest.tr()));

    final String role = () {
      if (session?.section != null && session!.section!.trim().isNotEmpty) {
        return session.section!.trim();
      }
      if (isGuest) return LocaleKeys.dashboardRole.tr();
      if (authUser?.designation != null &&
          authUser!.designation!.trim().isNotEmpty) {
        return authUser.designation!.trim();
      }
      return LocaleKeys.dashboardRole.tr();
    }();

    final String primaryId = () {
      if (isGuest) return '—';
      if (authUser?.officerId.trim().isNotEmpty == true) {
        return authUser!.officerId.trim();
      }
      if (session?.userId.trim().isNotEmpty == true) {
        return session!.userId.trim();
      }
      return '—';
    }();

    final String location = () {
      final String? districtName = session?.districtName?.trim();
      if (districtName != null && districtName.isNotEmpty) return districtName;
      final String? districtId = session?.districtId?.trim();
      if (districtId != null && districtId.isNotEmpty) return districtId;
      if (isGuest) return LocaleKeys.dashboardDistrictUnset.tr();
      final String? authDistrict = authUser?.districtCode?.trim();
      if (authDistrict != null && authDistrict.isNotEmpty) return authDistrict;
      return LocaleKeys.dashboardDistrictUnset.tr();
    }();

    final List<_DetailItem> rows = <_DetailItem>[];

    void add(String label, String? value) {
      final String? trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) return;
      rows.add(_DetailItem(label: label, value: trimmed));
    }

    if (!isGuest) {
      add(LocaleKeys.profileOfficerId.tr(), authUser?.officerId);
    }
    if (session?.userId != authUser?.officerId) {
      add(LocaleKeys.profileUserId.tr(), session?.userId);
    }
    if (!isGuest) {
      add(LocaleKeys.profileEmail.tr(), authUser?.email);
    }
    add(LocaleKeys.profileSection.tr(), session?.section);

    final String? district = _firstNonEmpty(<String?>[
      session?.districtName,
      session?.districtId,
      if (!isGuest) authUser?.districtCode,
    ]);
    add(LocaleKeys.profileDistrict.tr(), district);

    add(LocaleKeys.profileBody.tr(), session?.bodyName);
    if (!isGuest) {
      add(LocaleKeys.profileState.tr(), authUser?.stateCode);
    }

    final String pollingStation = <String?>[
      authUser?.pollingStationCode,
      authUser?.pollingStationName,
      authUser?.psId,
    ]
        .whereType<String>()
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toSet()
        .join(' · ');
    if (!isGuest) {
      add(
        LocaleKeys.profilePollingStation.tr(),
        pollingStation.isEmpty ? null : pollingStation,
      );
    }

    final List<_DetailItem> unique = <_DetailItem>[];
    for (final _DetailItem row in rows) {
      if (unique.any(
        (_DetailItem e) => e.label == row.label && e.value == row.value,
      )) {
        continue;
      }
      unique.add(row);
    }

    return _ProfileViewData(
      name: name,
      role: role,
      primaryId: primaryId,
      location: location,
      detailRows: unique,
    );
  }

  final String name;
  final String role;
  final String primaryId;
  final String location;
  final List<_DetailItem> detailRows;

  static String? _firstNonEmpty(List<String?> values) {
    for (final String? value in values) {
      final String? trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}

class _DetailItem {
  const _DetailItem({required this.label, required this.value});
  final String label;
  final String value;
}

class _OfficerHero extends StatelessWidget {
  const _OfficerHero({
    required this.name,
    required this.role,
    required this.officerId,
    required this.initials,
    required this.location,
    required this.isActive,
  });

  final String name;
  final String role;
  final String officerId;
  final String initials;
  final String location;
  final bool isActive;

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
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -36,
            top: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -48,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadius.brLg,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          borderRadius: AppRadius.brMd,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[AppColors.primary, AppColors.green],
                          ),
                        ),
                        child: Text(
                          initials,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    if (isActive)
                      Positioned(
                        right: -3,
                        bottom: -3,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        officerId,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: <Widget>[
                          _HeroChip(
                            icon: Icons.location_on_outlined,
                            label: location,
                          ),
                          _HeroChip(
                            icon: Icons.bolt_rounded,
                            label: isActive
                                ? LocaleKeys.profileActiveSession.tr()
                                : LocaleKeys.statsActive.tr(),
                          ),
                        ],
                      ),
                    ],
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

class _InventoryStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<DeviceRecord> all = AppServices.deviceRecords.records;
      final DeviceStats stats = AppServices.deviceRecords.statsFor(null);
      final DateTime weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final int thisWeek = all
          .where((DeviceRecord r) => r.timestamp.isAfter(weekAgo))
          .length;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: AppRadius.brXl,
          border: Border.all(color: context.appOutline),
        ),
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
      );
    });
  }
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
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: context.appMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: AppRadius.brPill,
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 3,
          height: 14,
          decoration: const BoxDecoration(
            borderRadius: AppRadius.brPill,
            gradient: AppGradients.primaryButton,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: context.appMutedStrong,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: context.appOutline),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 68,
      endIndent: 16,
      color: context.appDivider,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: context.appMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: context.appOnSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brXl,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.brMd,
                ),
                child: Icon(icon, size: 18, color: color),
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
                        color: context.appOnSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: context.appMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: context.appMuted,
                ),
            ],
          ),
        ),
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
      color: AppColors.errorSurface.withValues(
        alpha: context.isAppDark ? 0.2 : 1,
      ),
      borderRadius: AppRadius.brXl,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brXl,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brXl,
            border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.logout_rounded,
                size: 18,
                color: AppColors.error,
              ),
              const SizedBox(width: 10),
              Text(
                LocaleKeys.profileSignOut.tr(),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
