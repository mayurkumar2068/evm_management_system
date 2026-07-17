import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/utils/date_time_extensions.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:evm_management_system/shared/models/activity_event.dart';
import 'package:evm_management_system/shared/models/device_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;

/// Shared device-registration screen body used by both the Control Unit and
/// Ballot Unit features.
class DeviceRegistrationView extends StatefulWidget {
  const DeviceRegistrationView({required this.kind, super.key});

  final DeviceKind kind;

  @override
  State<DeviceRegistrationView> createState() => _DeviceRegistrationViewState();
}

class _DeviceRegistrationViewState extends State<DeviceRegistrationView> {
  final TextEditingController _barcode = TextEditingController();
  final TextEditingController _box = TextEditingController();
  String _manufacturer = 'BEL';
  bool _autoSave = false;

  DeviceKind get _kind => widget.kind;
  bool get _isCu => widget.kind == DeviceKind.controlUnit;
  Color get _accent => _isCu ? AppColors.primary : AppColors.green;
  String get _title =>
      _isCu ? LocaleKeys.regControlUnit.tr() : LocaleKeys.regBallotUnit.tr();

  String get _officer =>
      AppServices.auth.authState.value.user?.fullName ??
      LocaleKeys.dashboardGuest.tr();
  String get _district =>
      AppServices.auth.authState.value.user?.districtCode ??
      LocaleKeys.dashboardDistrictUnset.tr();

  @override
  void dispose() {
    _barcode.dispose();
    _box.dispose();
    super.dispose();
  }

  Future<void> _openScanner() async {
    final Object? result = await Get.toNamed<Object?>(AppRoute.scanner.path);
    if (!mounted || result is! String || result.isEmpty) return;
    final String code = result.toUpperCase();
    setState(() {
      _barcode.text = result;
    });
    AppServices.activityLog.log(
      type: ActivityType.scanned,
      title: LocaleKeys.scannerScanning.tr(),
      deviceId: result,
      officer: _officer,
    );
    final bool looksLikeId = RegExp(r'^(CU|BU)-').hasMatch(code);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _accent,
        content: Text(
          looksLikeId
              ? 'Scanned $result' // Logic-dependent, could be improved if needed
              : 'Barcode $result captured',
        ),
      ),
    );
  }

  void _save({required bool stay}) {
    final String barcode = _barcode.text.trim();
    if (barcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          content: Text(LocaleKeys.scannerAlignPrompt.tr()),
        ),
      );
      return;
    }
    final DeviceRecord record = AppServices.deviceRecords.register(
      kind: _kind,
      barcode: barcode,
      box: _box.text,
      manufacturer: _manufacturer,
      district: _district,
      officer: _officer,
    );
    AppServices.activityLog.log(
      type: ActivityType.registered,
      title: LocaleKeys.regSaveDevice.tr(),
      deviceId: record.id,
      officer: _officer,
    );
    _barcode.clear();
    _box.clear();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
        content: Text('${record.id} registered (${record.status.key})'),
      ),
    );
    if (!stay && (Get.key.currentState?.canPop() ?? false)) Get.back<dynamic>();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final double top = MediaQuery.of(context).padding.top;
      final List<DeviceRecord> recent = AppServices.deviceRecords.records
          .where((DeviceRecord r) {
            return r.kind == _kind;
          })
          .take(5)
          .toList();
      final String nextId = AppServices.deviceRecords.previewNextId(_kind);
      final DeviceStats stats = AppServices.deviceRecords.statsFor(_kind);

      return Scaffold(
        backgroundColor: AppColors.background,
        body: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: <Widget>[
            Container(
              padding: EdgeInsets.fromLTRB(16, top + 12, 16, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    _isCu ? AppColors.primaryDeep : AppColors.greenDark,
                    _accent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      AppCircleBackButton(
                        light: true,
                        onTap: () => Get.key.currentState?.canPop() == true
                            ? Get.back<dynamic>()
                            : Get.offAllNamed<dynamic>(AppRoute.dashboard.path),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              LocaleKeys.regRegisterCu.tr(args: [_title]),
                              style: AppTextStyles.titleLarge.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              LocaleKeys.regScannerSub.tr(),
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: AppRadius.brSm,
                        ),
                        child: Text(
                          '${LocaleKeys.statsActive.tr()}: ${stats.total}',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _openScanner,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: AppRadius.brMd,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Colors.white12,
                              borderRadius: AppRadius.brSm,
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  LocaleKeys.regOpenScanner.tr(),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  LocaleKeys.regScannerSub.tr(),
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white.withValues(alpha: 0.55),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 22,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _accent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '1',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            LocaleKeys.regInformation.tr(),
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _IdField(
                        label: LocaleKeys.regDeviceId.tr(),
                        value: nextId,
                        accent: _accent,
                      ),
                      const SizedBox(height: 14),
                      _Field(
                        label: LocaleKeys.regBarcodeNum.tr(),
                        hint: LocaleKeys.regBarcodeHint.tr(),
                        icon: Icons.qr_code_rounded,
                        controller: _barcode,
                        keyboardType: TextInputType.number,
                        trailing: IconButton(
                          icon: Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 20,
                            color: _accent,
                          ),
                          onPressed: _openScanner,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _Field(
                        label: LocaleKeys.regBoxNum.tr(),
                        hint: LocaleKeys.regBoxHint.tr(),
                        icon: Icons.inbox_outlined,
                        controller: _box,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        LocaleKeys.regManufacturer.tr(),
                        style: AppTextStyles.overline.copyWith(
                          color: AppColors.slate500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          for (final String m in <String>['BEL', 'ECIL'])
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: m == 'BEL' ? 8 : 0,
                                ),
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _manufacturer = m),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _manufacturer == m
                                          ? _accent.withValues(alpha: 0.1)
                                          : AppColors.surface,
                                      borderRadius: AppRadius.brMd,
                                      border: Border.all(
                                        color: _manufacturer == m
                                            ? _accent
                                            : AppColors.slate200,
                                      ),
                                    ),
                                    child: Text(
                                      m,
                                      style: AppTextStyles.titleSmall.copyWith(
                                        color: _manufacturer == m
                                            ? _accent
                                            : AppColors.slate500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            LocaleKeys.regAutoSave.tr(),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.slate500,
                            ),
                          ),
                          Switch.adaptive(
                            value: _autoSave,
                            onChanged: (bool v) =>
                                setState(() => _autoSave = v),
                            activeThumbColor: _accent,
                            activeTrackColor: _accent.withValues(alpha: 0.35),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _save(stay: true),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                side: const BorderSide(
                                  color: AppColors.slate200,
                                ),
                                foregroundColor: AppColors.slate600,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppRadius.brMd,
                                ),
                              ),
                              child: Text(LocaleKeys.regSaveNew.tr()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: AppGradientButton(
                              label: LocaleKeys.regSaveDevice.tr(),
                              gradient: AppGradients.accent(_accent),
                              onPressed: () => _save(stay: _autoSave),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: AppSectionHeader(
                title: LocaleKeys.regRecentEntries.tr(),
                trailing: Text(
                  '${recent.length} shown',
                  style: AppTextStyles.caption.copyWith(
                    color: _accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (recent.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: AppCard(
                  child: Center(
                    child: Text(
                      LocaleKeys.regNoEntries.tr(),
                      style: const TextStyle(
                        color: AppColors.slate400,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              )
            else
              for (final DeviceRecord e in recent)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: AppCard(
                    padding: const EdgeInsets.all(12),
                    onTap: () => Get.toNamed<dynamic>(
                      AppRoute.deviceDetail.path,
                      arguments: e.id,
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: _accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Text(
                                    e.id,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.slate700,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AppStatusPill(status: e.status.key),
                                ],
                              ),
                              Text(
                                '${e.barcode} • ${e.box}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.slate400,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          e.timestamp.relativeTime,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.slate400,
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

class _IdField extends StatelessWidget {
  const _IdField({
    required this.label,
    required this.value,
    required this.accent,
  });
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: AppTextStyles.overline.copyWith(color: AppColors.slate500),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.06),
            borderRadius: AppRadius.brMd,
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.badge_outlined, size: 18, color: accent),
              const SizedBox(width: 10),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                LocaleKeys.appSystem.tr().toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  color: accent.withValues(alpha: 0.6),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.keyboardType,
    this.trailing,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: AppTextStyles.overline.copyWith(color: AppColors.slate500),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: keyboardType == TextInputType.number
              ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
              : null,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.slate700),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: AppColors.slate400),
            suffixIcon: trailing,
            filled: true,
            fillColor: AppColors.slate50,
            enabledBorder: const OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: AppColors.slate200),
            ),
          ),
        ),
      ],
    );
  }
}
