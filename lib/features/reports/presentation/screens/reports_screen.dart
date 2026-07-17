import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:evm_management_system/shared/models/device_record.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Analytics & Reports — period selector, KPIs and charts.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static final List<String> _periods = <String>[
    LocaleKeys.auditToday.tr(),
    LocaleKeys.profileThisWeek.tr(),
    'Month',
    'Quarter',
  ];
  static const List<int> _periodDays = <int>[1, 7, 30, 90];
  int _period = 1;

  static const List<String> _dayNames = <String>[
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', //
  ];

  List<String> get _last7DayLabels {
    final DateTime now = DateTime.now();
    return <String>[
      for (int i = 6; i >= 0; i--)
        _dayNames[now.subtract(Duration(days: i)).weekday - 1],
    ];
  }

  List<double> _dailySeries(List<DeviceRecord> all, DeviceKind kind) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final List<double> counts = List<double>.filled(7, 0);
    for (final DeviceRecord r in all) {
      if (r.kind != kind) continue;
      final int diff = today
          .difference(
            DateTime(r.timestamp.year, r.timestamp.month, r.timestamp.day),
          )
          .inDays;
      if (diff >= 0 && diff < 7) counts[6 - diff] += 1;
    }
    return counts;
  }

  /// Total registrations per week for the last 6 weeks (oldest → newest).
  List<double> _weeklyTotals(List<DeviceRecord> all) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final List<double> counts = List<double>.filled(6, 0);
    for (final DeviceRecord r in all) {
      final int days = today
          .difference(
            DateTime(r.timestamp.year, r.timestamp.month, r.timestamp.day),
          )
          .inDays;
      if (days < 0) continue;
      final int week = days ~/ 7;
      if (week < 6) counts[5 - week] += 1;
    }
    return counts;
  }

  int _periodCount(List<DeviceRecord> all) {
    final DateTime from = DateTime.now().subtract(
      Duration(days: _periodDays[_period]),
    );
    return all.where((DeviceRecord r) => r.timestamp.isAfter(from)).length;
  }

  Map<String, int> _districtCounts(List<DeviceRecord> all) {
    final Map<String, int> map = <String, int>{};
    for (final DeviceRecord r in all) {
      map[r.district] = (map[r.district] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<DeviceRecord> all = AppServices.deviceRecords.records;
      final DeviceStats stats = AppServices.deviceRecords.statsFor(null);

      return Container(
        color: AppColors.background,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: <Widget>[
            AppTopBar(
              title: LocaleKeys.reportsTitle.tr(),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  gradient: AppGradients.primaryButton,
                  borderRadius: AppRadius.brSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.download_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      LocaleKeys.commonExport.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.brMd,
                  border: Border.all(color: AppColors.slate100),
                ),
                child: Row(
                  children: <Widget>[
                    for (int i = 0; i < _periods.length; i++)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _period = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _period == i
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: AppRadius.brSm,
                            ),
                            child: Text(
                              _periods[i],
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _period == i
                                    ? Colors.white
                                    : AppColors.slate400,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  _Kpi(
                    value: '${stats.total}',
                    label: LocaleKeys.statsTotal.tr(),
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _Kpi(
                    value: '${_periodCount(all)}',
                    label: 'This ${_periods[_period]}',
                    color: AppColors.green,
                  ),
                  const SizedBox(width: 8),
                  _Kpi(
                    value: '${stats.pending}',
                    label: LocaleKeys.statsPending.tr(),
                    color: AppColors.warning,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (all.isEmpty)
              _empty()
            else ...<Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        LocaleKeys.dashboardWeeklyRegistrations.tr(),
                        style: AppTextStyles.titleSmall,
                      ),
                      Text(
                        LocaleKeys.reportsLast7Days.tr(),
                        style: const TextStyle(
                          color: AppColors.slate400,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(height: 160, child: _dailyBars(all)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        LocaleKeys.reportsWeeklyTrend.tr(),
                        style: AppTextStyles.titleSmall,
                      ),
                      Text(
                        LocaleKeys.reportsLast6Weeks.tr(),
                        style: const TextStyle(
                          color: AppColors.slate400,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(height: 120, child: _weeklyLine(all)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: _statusCard(stats)),
                    const SizedBox(width: 12),
                    Expanded(child: _districtCard(all)),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.bar_chart_rounded,
            size: 48,
            color: AppColors.slate300,
          ),
          const SizedBox(height: 12),
          Text(
            LocaleKeys.reportsEmpty.tr(),
            style: const TextStyle(
              color: AppColors.slate500,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            LocaleKeys.reportsEmptySub.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.slate400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _dailyBars(List<DeviceRecord> all) {
    final List<double> cu = _dailySeries(all, DeviceKind.controlUnit);
    final List<double> bu = _dailySeries(all, DeviceKind.ballotUnit);
    final List<String> labels = _last7DayLabels;
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (double v, TitleMeta meta) {
                final int i = v.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[i],
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.slate400,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: <BarChartGroupData>[
          for (int i = 0; i < labels.length; i++)
            BarChartGroupData(
              x: i,
              barRods: <BarChartRodData>[
                BarChartRodData(
                  toY: cu[i],
                  color: AppColors.primary,
                  width: 7,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                BarChartRodData(
                  toY: bu[i],
                  color: AppColors.green,
                  width: 7,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _weeklyLine(List<DeviceRecord> all) {
    final List<double> weekly = _weeklyTotals(all);
    const List<String> weeks = <String>['W1', 'W2', 'W3', 'W4', 'W5', 'W6'];
    return LineChart(
      LineChartData(
        minY: 0,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (double v, TitleMeta meta) {
                final int i = v.toInt();
                if (i < 0 || i >= weeks.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    weeks[i],
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.slate400,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            spots: <FlSpot>[
              for (int i = 0; i < weekly.length; i++)
                FlSpot(i.toDouble(), weekly[i]),
            ],
            isCurved: true,
            color: AppColors.secondary,
            barWidth: 2.5,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(DeviceStats stats) {
    final List<(String, int, Color)> status = <(String, int, Color)>[
      (LocaleKeys.statsRegistered.tr(), stats.registered, AppColors.primary),
      (LocaleKeys.statsPending.tr(), stats.pending, AppColors.warning),
      (LocaleKeys.statsInTransit.tr(), stats.inTransit, AppColors.secondary),
      (LocaleKeys.statsDefective.tr(), stats.defective, AppColors.error),
    ];
    final int total = stats.total;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            LocaleKeys.reportsDeviceStatus.tr(),
            style: AppTextStyles.titleSmall.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: total == 0
                ? Center(
                    child: Text(
                      LocaleKeys.commonNoData.tr(),
                      style: const TextStyle(
                        color: AppColors.slate300,
                        fontSize: 11,
                      ),
                    ),
                  )
                : PieChart(
                    PieChartData(
                      centerSpaceRadius: 26,
                      sectionsSpace: 3,
                      sections: <PieChartSectionData>[
                        for (final (String, int, Color) e in status)
                          if (e.$2 > 0)
                            PieChartSectionData(
                              value: e.$2.toDouble(),
                              color: e.$3,
                              radius: 18,
                              showTitle: false,
                            ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          for (final (String, int, Color) e in status)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: e.$3,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      e.$1,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.slate500,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  Text(
                    total == 0 ? '0%' : '${(e.$2 * 100 / total).round()}%',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.slate600,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _districtCard(List<DeviceRecord> all) {
    final Map<String, int> counts = _districtCounts(all);
    final List<MapEntry<String, int>> entries = counts.entries.toList()
      ..sort(
        (MapEntry<String, int> a, MapEntry<String, int> b) =>
            b.value.compareTo(a.value),
      );
    final List<MapEntry<String, int>> top = entries.take(6).toList();
    final int max = top.isEmpty ? 1 : top.first.value;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            LocaleKeys.reportsByDistrict.tr(),
            style: AppTextStyles.titleSmall.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 12),
          if (top.isEmpty)
            Text(
              LocaleKeys.commonNoData.tr(),
              style: const TextStyle(color: AppColors.slate300, fontSize: 9),
            )
          else
            for (final MapEntry<String, int> d in top)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            d.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.slate500,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        Text(
                          '${d.value}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.slate600,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: AppRadius.brPill,
                      child: LinearProgressIndicator(
                        value: d.value / max,
                        minHeight: 5,
                        backgroundColor: AppColors.slate100,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
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

class _Kpi extends StatelessWidget {
  const _Kpi({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: <Widget>[
            Text(
              value,
              style: AppTextStyles.titleLarge.copyWith(
                color: color,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
