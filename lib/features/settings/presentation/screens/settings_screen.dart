import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/offline/web_form_submission.dart';
import 'package:evm_management_system/core/settings/app_preferences_actions.dart';
import 'package:evm_management_system/features/offline/presentation/widgets/offline_status_sheet.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:evm_management_system/shared/widgets/language_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Settings — language, theme, notifications, and offline only.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifs = true;
  int _offlineCount = 0;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadOfflineCounts();
  }

  Future<void> _loadOfflineCounts() async {
    final List<WebFormSubmission> all =
        await AppServices.webSubmissionRepository.all();
    if (!mounted) return;
    int pending = 0;
    for (final WebFormSubmission s in all) {
      if (s.status == WebSubmissionStatus.pending ||
          s.status == WebSubmissionStatus.syncing ||
          s.status == WebSubmissionStatus.failed) {
        pending++;
      }
    }
    setState(() {
      _offlineCount = all.length;
      _pendingCount = pending;
    });
  }

  Future<void> _pickLanguage() async {
    final Locale currentLocale = AppServices.settings.locale.value;
    await showLanguagePickerSheet(
      context,
      currentLocale: currentLocale,
      onLocaleSelected: (Locale locale) =>
          applyAppLocale(context: context, locale: locale),
    );
  }

  void _toggleTheme() => toggleAppTheme();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final Locale currentLocale = AppServices.settings.locale.value;
      final ThemeMode themeMode = AppServices.settings.themeMode.value;
      final bool isDark = themeMode == ThemeMode.dark;
      final String offlineSub = _pendingCount > 0
          ? LocaleKeys.settingsRecordsStored.tr(
              args: <String>['$_offlineCount'],
            )
          : LocaleKeys.settingsRecordsStored.tr(
              args: <String>['$_offlineCount'],
            );

      final List<_Section> sections = <_Section>[
        _Section(LocaleKeys.settingsAppearance.tr(), <_Item>[
          _Item(
            Icons.dark_mode_outlined,
            LocaleKeys.settingsDarkMode.tr(),
            isDark
                ? LocaleKeys.settingsDarkMode.tr()
                : LocaleKeys.settingsLightMode.tr(),
            value: isDark,
            onChanged: (_) => _toggleTheme(),
          ),
          _Item(
            Icons.language_rounded,
            LocaleKeys.settingsLanguage.tr(),
            languageLabelFor(currentLocale),
            onTap: _pickLanguage,
          ),
        ]),
        _Section(LocaleKeys.profileNotifications.tr(), <_Item>[
          _Item(
            Icons.notifications_none_rounded,
            LocaleKeys.settingsPushAlerts.tr(),
            LocaleKeys.settingsPushAlertsSub.tr(),
            value: _notifs,
            onChanged: (bool v) => setState(() => _notifs = v),
          ),
        ]),
        _Section(LocaleKeys.settingsDataSync.tr(), <_Item>[
          _Item(
            Icons.cloud_off_outlined,
            LocaleKeys.settingsOfflineStorage.tr(),
            offlineSub,
            onTap: () => showOfflineStatusSheet(context),
          ),
        ]),
      ];

      return ColoredBox(
        color: context.appBackground,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: <Widget>[
            AppTopBar(
              title: LocaleKeys.profileSettings.tr(),
              onBack: Get.key.currentState?.canPop() == true
                  ? () => Get.back<void>()
                  : null,
            ),
            for (final _Section s in sections)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        s.title.toUpperCase(),
                        style: AppTextStyles.overline.copyWith(
                          color: context.appMuted,
                          fontSize: 10,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    AppCard(
                      padding: EdgeInsets.zero,
                      border: Border.all(color: context.appOutline),
                      child: Column(
                        children: <Widget>[
                          for (int i = 0; i < s.items.length; i++)
                            _SettingTile(
                              item: s.items[i],
                              showDivider: i < s.items.length - 1,
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
    });
  }
}

class _Section {
  const _Section(this.title, this.items);
  final String title;
  final List<_Item> items;
}

class _Item {
  const _Item(
    this.icon,
    this.label,
    this.sub, {
    this.value,
    this.onChanged,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String sub;
  final bool? value;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onTap;

  bool get isToggle => value != null;
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.item, required this.showDivider});
  final _Item item;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.isToggle
            ? (item.onChanged == null
                  ? null
                  : () => item.onChanged!(!item.value!))
            : item.onTap,
        child: Container(
          decoration: BoxDecoration(
            border: showDivider
                ? Border(bottom: BorderSide(color: context.appDivider))
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.appChip,
                  borderRadius: AppRadius.brSm,
                ),
                child: Icon(item.icon, size: 16, color: context.appMuted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.appOnSurface,
                      ),
                    ),
                    Text(
                      item.sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: context.appMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.isToggle)
                Switch.adaptive(
                  value: item.value!,
                  onChanged: item.onChanged,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: context.appMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
