import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:evm_management_system/shared/models/device_record.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Master Stock Register — district inventory summary.
class MasterStockRegisterScreen extends StatefulWidget {
  const MasterStockRegisterScreen({super.key});

  @override
  State<MasterStockRegisterScreen> createState() =>
      _MasterStockRegisterScreenState();
}

class _MasterStockRegisterScreenState extends State<MasterStockRegisterScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<DeviceRecord> all = AppServices.deviceRecords.records;
      final DeviceStats cu = AppServices.deviceRecords.statsFor(
        DeviceKind.controlUnit,
      );
      final DeviceStats bu = AppServices.deviceRecords.statsFor(
        DeviceKind.ballotUnit,
      );
      final DeviceStats total = AppServices.deviceRecords.statsFor(null);

      final List<DeviceRecord> recent =
          (_query.isEmpty ? all : AppServices.deviceRecords.search(_query))
              .take(8)
              .toList();

      // Box-wise device counts (skip the placeholder 'Unassigned' bucket),
      // sorted naturally so "Box 2" comes before "Box 10".
      final Map<String, int> boxCounts = <String, int>{};
      for (final DeviceRecord r in all) {
        if (r.box.isEmpty || r.box == 'Unassigned') continue;
        boxCounts.update(r.box, (int v) => v + 1, ifAbsent: () => 1);
      }
      final List<MapEntry<String, int>> boxes = boxCounts.entries.toList()
        ..sort(
          (MapEntry<String, int> a, MapEntry<String, int> b) =>
              _compareBox(a.key, b.key),
        );

      final List<_Category> categories = <_Category>[
        _Category(LocaleKeys.statsControlUnits.tr(), cu, AppColors.primary),
        _Category(LocaleKeys.statsBallotUnits.tr(), bu, AppColors.green),
      ];

      return Container(
        color: AppColors.background,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: <Widget>[
            AppTopBar(
              title: LocaleKeys.regInventory.tr(),
              trailing: const Row(
                children: <Widget>[
                  AppSquareIconButton(icon: Icons.filter_list_rounded),
                  SizedBox(width: 8),
                  AppSquareIconButton(icon: Icons.download_rounded),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                onChanged: (String v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: LocaleKeys.statsSearchInventory.tr(),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.slate400,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: AppRadius.brMd,
                    borderSide: BorderSide(color: AppColors.slate200),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppGradients.header,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      LocaleKeys.statsTotalInventory.tr(),
                      style: const TextStyle(
                        color: Color(0xFF9CB6F5),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        _BannerStat(
                          value: '${total.total}',
                          label: LocaleKeys.statsTotal.tr(),
                        ),
                        _BannerStat(
                          value: '${total.active}',
                          label: LocaleKeys.statsActive.tr(),
                        ),
                        _BannerStat(
                          value: '${total.pending}',
                          label: LocaleKeys.statsPending.tr(),
                        ),
                        _BannerStat(
                          value: '${total.defective}',
                          label: LocaleKeys.statsIssues.tr(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final _Category c in categories)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _CategoryCard(category: c),
              ),
            if (boxes.isNotEmpty) ...<Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: AppSectionHeader(
                  title: LocaleKeys.statsBoxWiseCount.tr(),
                  trailingLabel:
                      '${boxes.length} ${boxes.length == 1 ? 'box' : 'boxes'}',
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _BoxCountGrid(boxes: boxes),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: AppSectionHeader(
                title: _query.isEmpty
                    ? LocaleKeys.regRecentEntries.tr()
                    : LocaleKeys.commonSearch.tr(),
                trailingLabel: '${recent.length} shown',
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
              for (final DeviceRecord d in recent)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _DeviceRow(
                    device: d,
                    onTap: () => Get.toNamed<dynamic>(
                      AppRoute.deviceDetail.path,
                      arguments: d.id,
                    ),
                  ),
                ),
          ],
        ),
      );
    });
  }
}

/// Natural box comparison so "Box 2" sorts before "Box 10": compare by the
/// trailing number when both labels have one, otherwise fall back to plain
/// case-insensitive text.
int _compareBox(String a, String b) {
  final RegExpMatch? na = RegExp(r'(\d+)$').firstMatch(a);
  final RegExpMatch? nb = RegExp(r'(\d+)$').firstMatch(b);
  if (na != null && nb != null) {
    final String pa = a.substring(0, na.start).toLowerCase();
    final String pb = b.substring(0, nb.start).toLowerCase();
    if (pa == pb) {
      return int.parse(na.group(1)!).compareTo(int.parse(nb.group(1)!));
    }
  }
  return a.toLowerCase().compareTo(b.toLowerCase());
}

/// Box-wise count grid. Renders exactly [_perRow] boxes per row; any beyond
/// that wrap onto new rows automatically (item width is derived so 10 always
/// fit across, regardless of how many boxes exist).
class _BoxCountGrid extends StatelessWidget {
  const _BoxCountGrid({required this.boxes});
  final List<MapEntry<String, int>> boxes;

  static const int _perRow = 10;
  static const double _spacing = 6;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double itemWidth =
            (constraints.maxWidth - _spacing * (_perRow - 1)) / _perRow;
        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: <Widget>[
            for (final MapEntry<String, int> e in boxes)
              SizedBox(
                width: itemWidth,
                child: _BoxChip(label: e.key, count: e.value),
              ),
          ],
        );
      },
    );
  }
}

class _BoxChip extends StatelessWidget {
  const _BoxChip({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Box $label • $count device${count == 1 ? '' : 's'}',
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: AppRadius.brSm,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          padding: const EdgeInsets.all(3),
          // Scale the count + label to fit whatever square width 10-per-row
          // produces, so tiny phones never overflow and tablets look crisp.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '$count',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.slate400,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Category {
  const _Category(this.name, this.stats, this.color);
  final String name;
  final DeviceStats stats;
  final Color color;

  int get total => stats.total;
  int get reg => stats.registered;
  int get pending => stats.pending;
  int get transit => stats.inTransit;
  int get defect => stats.defective;
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});
  final _Category category;

  String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );

  @override
  Widget build(BuildContext context) {
    final double pct = category.total == 0 ? 0 : category.reg / category.total;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: category.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(category.name, style: AppTextStyles.titleSmall),
                ],
              ),
              Text(
                _fmt(category.total),
                style: AppTextStyles.titleLarge.copyWith(fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: AppRadius.brPill,
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.slate100,
              valueColor: AlwaysStoppedAnimation<Color>(category.color),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '${(pct * 100).round()}% registered',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.slate400,
                ),
              ),
              Text(
                '${_fmt(category.reg)} / ${_fmt(category.total)}',
                style: AppTextStyles.caption.copyWith(
                  color: category.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _SubStat('Reg.', category.reg, AppColors.success, _fmt),
              const SizedBox(width: 6),
              _SubStat('Pend.', category.pending, AppColors.warning, _fmt),
              const SizedBox(width: 6),
              _SubStat('Transit', category.transit, AppColors.primary, _fmt),
              const SizedBox(width: 6),
              _SubStat('Defect.', category.defect, AppColors.error, _fmt),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubStat extends StatelessWidget {
  const _SubStat(this.label, this.value, this.color, this.fmt);
  final String label;
  final int value;
  final Color color;
  final String Function(int) fmt;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: AppRadius.brSm,
        ),
        child: Column(
          children: <Widget>[
            Text(
              fmt(value),
              style: AppTextStyles.titleSmall.copyWith(
                color: color,
                fontSize: 13,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.slate400,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  const _BannerStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF9CB6F5), fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.device, required this.onTap});
  final DeviceRecord device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = device.kind == DeviceKind.controlUnit
        ? AppColors.primary
        : AppColors.green;
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              device.kind.code,
              style: AppTextStyles.caption.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
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
                      device.id,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.slate700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppStatusPill(status: device.status.key),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${device.barcode} • ${device.box}',
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
