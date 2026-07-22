import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/offline/web_form_submission.dart';
import 'package:evm_management_system/features/reports/presentation/models/survey_report_analytics.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Survey analytics — boxed KPIs/charts + district / PS / urban-rural detail list.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const List<int> _periodDays = <int>[1, 7, 30, 90];
  int _period = 1;
  bool _loading = true;
  List<WebFormSubmission> _all = const <WebFormSubmission>[];
  final Set<String> _expandedDistricts = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<WebFormSubmission> all =
        await AppServices.webSubmissionRepository.all();
    if (!mounted) return;
    setState(() {
      _all = all;
      _loading = false;
    });
  }

  List<String> get _periodLabels => <String>[
    LocaleKeys.auditToday.tr(),
    LocaleKeys.profileThisWeek.tr(),
    LocaleKeys.reportsMonth.tr(),
    LocaleKeys.reportsQuarter.tr(),
  ];

  List<String> get _dayNames => <String>[
    LocaleKeys.reportsDayMon.tr(),
    LocaleKeys.reportsDayTue.tr(),
    LocaleKeys.reportsDayWed.tr(),
    LocaleKeys.reportsDayThu.tr(),
    LocaleKeys.reportsDayFri.tr(),
    LocaleKeys.reportsDaySat.tr(),
    LocaleKeys.reportsDaySun.tr(),
  ];

  DateTime get _periodStart =>
      DateTime.now().subtract(Duration(days: _periodDays[_period]));

  List<WebFormSubmission> _inPeriod(List<WebFormSubmission> all) {
    final DateTime from = _periodStart;
    return all
        .where((WebFormSubmission s) => !s.createdAt.isBefore(from))
        .toList(growable: false);
  }

  List<String> get _last7DayLabels {
    final DateTime now = DateTime.now();
    final List<String> names = _dayNames;
    return <String>[
      for (int i = 6; i >= 0; i--)
        names[now.subtract(Duration(days: i)).weekday - 1],
    ];
  }

  List<double> _dailySeries(List<WebFormSubmission> records) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final List<double> counts = List<double>.filled(7, 0);
    for (final WebFormSubmission s in records) {
      final int diff = today
          .difference(
            DateTime(s.createdAt.year, s.createdAt.month, s.createdAt.day),
          )
          .inDays;
      if (diff >= 0 && diff < 7) counts[6 - diff] += 1;
    }
    return counts;
  }

  List<double> _weeklyTotals(List<WebFormSubmission> records) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final List<double> counts = List<double>.filled(6, 0);
    for (final WebFormSubmission s in records) {
      final int days = today
          .difference(
            DateTime(s.createdAt.year, s.createdAt.month, s.createdAt.day),
          )
          .inDays;
      if (days < 0) continue;
      final int week = days ~/ 7;
      if (week < 6) counts[5 - week] += 1;
    }
    return counts;
  }

  ({int synced, int pending, int failed}) _statusCounts(
    List<WebFormSubmission> records,
  ) {
    int synced = 0, pending = 0, failed = 0;
    for (final WebFormSubmission s in records) {
      switch (s.status) {
        case WebSubmissionStatus.synced:
          synced++;
        case WebSubmissionStatus.pending:
        case WebSubmissionStatus.syncing:
          pending++;
        case WebSubmissionStatus.failed:
          failed++;
      }
    }
    return (synced: synced, pending: pending, failed: failed);
  }

  Future<void> _exportCsv(List<WebFormSubmission> records) async {
    if (records.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.reportsExportEmpty.tr())),
      );
      return;
    }

    final StringBuffer csv = StringBuffer()
      ..writeln(
        'clientId,formType,status,district,booth,areaType,createdAt,syncedAt,referenceId',
      );
    for (final WebFormSubmission s in records) {
      final SurveyLocationFacts loc =
          SurveyReportAnalytics.fromPayload(s.payload);
      csv.writeln(
        [
          _csv(s.clientId),
          _csv(s.formType),
          _csv(s.status.name),
          _csv(loc.districtLabel),
          _csv(loc.boothLabel),
          _csv(loc.areaType),
          _csv(s.createdAt.toIso8601String()),
          _csv(s.syncedAt?.toIso8601String() ?? ''),
          _csv(s.referenceId ?? ''),
        ].join(','),
      );
    }

    await SharePlus.instance.share(
      ShareParams(
        text: csv.toString(),
        subject: LocaleKeys.reportsTitle.tr(),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(LocaleKeys.reportsExportOk.tr())),
    );
  }

  static String _csv(String value) {
    final String escaped = value.replaceAll('"', '""');
    if (escaped.contains(',') ||
        escaped.contains('"') ||
        escaped.contains('\n')) {
      return '"$escaped"';
    }
    return escaped;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ColoredBox(
        color: context.appBackground,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final List<WebFormSubmission> periodRecords = _inPeriod(_all);
    final ({int synced, int pending, int failed}) allStatus =
        _statusCounts(_all);
    final ({int synced, int pending, int failed}) periodStatus =
        _statusCounts(periodRecords);
    final ({int urban, int rural, int unknown}) area =
        SurveyReportAnalytics.areaTotals(periodRecords);
    final List<DistrictSurveyAgg> districts =
        SurveyReportAnalytics.byDistrict(periodRecords);
    final List<String> periods = _periodLabels;
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final int todayCount = _all
        .where(
          (WebFormSubmission s) =>
              DateTime(s.createdAt.year, s.createdAt.month, s.createdAt.day) ==
              today,
        )
        .length;

    return ColoredBox(
      color: context.appBackground,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: <Widget>[
            AppTopBar(
              title: LocaleKeys.reportsTitle.tr(),
              trailing: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _exportCsv(periodRecords),
                  borderRadius: AppRadius.brSm,
                  child: Ink(
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
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: AppRadius.brMd,
                  border: Border.all(color: context.appOutline),
                ),
                child: Row(
                  children: <Widget>[
                    for (int i = 0; i < periods.length; i++)
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
                              periods[i],
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _period == i
                                    ? Colors.white
                                    : context.appMuted,
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
                    value: '${_all.length}',
                    label: LocaleKeys.dashboardStatSurveysTotal.tr(),
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _Kpi(
                    value: '$todayCount',
                    label: LocaleKeys.dashboardStatSurveysToday.tr(),
                    color: AppColors.green,
                  ),
                  const SizedBox(width: 8),
                  _Kpi(
                    value: '${allStatus.synced}',
                    label: LocaleKeys.dashboardStatSurveysSynced.tr(),
                    color: AppColors.teal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  _Kpi(
                    value: '${periodRecords.length}',
                    label: LocaleKeys.reportsThisPeriod.tr(
                      args: <String>[periods[_period]],
                    ),
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  _Kpi(
                    value: '${area.urban}',
                    label: LocaleKeys.reportsUrban.tr(),
                    color: AppColors.primaryBright,
                  ),
                  const SizedBox(width: 8),
                  _Kpi(
                    value: '${area.rural}',
                    label: LocaleKeys.reportsRural.tr(),
                    color: AppColors.warning,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_all.isEmpty)
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
                      SizedBox(height: 160, child: _dailyBars(periodRecords)),
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
                      SizedBox(height: 120, child: _weeklyLine(periodRecords)),
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
                    Expanded(child: _statusCard(periodStatus)),
                    const SizedBox(width: 12),
                    Expanded(child: _areaCard(area)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  LocaleKeys.reportsDetailTitle.tr(),
                  style: AppTextStyles.titleSmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  LocaleKeys.reportsDetailSub.tr(),
                  style: const TextStyle(color: AppColors.slate400, fontSize: 11),
                ),
              ),
              if (districts.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    LocaleKeys.commonNoData.tr(),
                    style: const TextStyle(color: AppColors.slate400),
                  ),
                )
              else
                for (final DistrictSurveyAgg d in districts)
                  _DistrictDetailCard(
                    agg: d,
                    expanded: _expandedDistricts.contains(d.key),
                    onToggle: () => setState(() {
                      if (_expandedDistricts.contains(d.key)) {
                        _expandedDistricts.remove(d.key);
                      } else {
                        _expandedDistricts.add(d.key);
                      }
                    }),
                  ),
            ],
          ],
        ),
      ),
    );
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

  Widget _dailyBars(List<WebFormSubmission> records) {
    final List<double> counts = _dailySeries(records);
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
                  toY: counts[i],
                  color: AppColors.primary,
                  width: 12,
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

  Widget _weeklyLine(List<WebFormSubmission> records) {
    final List<double> weekly = _weeklyTotals(records);
    final List<String> weeks = <String>[
      for (int i = 1; i <= 6; i++)
        LocaleKeys.reportsWeekLabel.tr(args: <String>['$i']),
    ];
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

  Widget _statusCard(({int synced, int pending, int failed}) stats) {
    final List<(String, int, Color)> status = <(String, int, Color)>[
      (
        LocaleKeys.dashboardStatSurveysSynced.tr(),
        stats.synced,
        AppColors.primary,
      ),
      (
        LocaleKeys.dashboardStatSurveysPending.tr(),
        stats.pending,
        AppColors.warning,
      ),
      (LocaleKeys.statsFailed.tr(), stats.failed, AppColors.error),
    ];
    final int total = stats.synced + stats.pending + stats.failed;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            LocaleKeys.reportsSurveyStatus.tr(),
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
            _legendRow(e.$1, e.$2, e.$3, total),
        ],
      ),
    );
  }

  Widget _areaCard(({int urban, int rural, int unknown}) area) {
    final List<(String, int, Color)> rows = <(String, int, Color)>[
      (LocaleKeys.reportsUrban.tr(), area.urban, AppColors.primaryBright),
      (LocaleKeys.reportsRural.tr(), area.rural, AppColors.warning),
      if (area.unknown > 0)
        (LocaleKeys.reportsUnknownArea.tr(), area.unknown, AppColors.slate400),
    ];
    final int total = area.urban + area.rural + area.unknown;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            LocaleKeys.reportsByAreaType.tr(),
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
                        for (final (String, int, Color) e in rows)
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
          for (final (String, int, Color) e in rows)
            _legendRow(e.$1, e.$2, e.$3, total),
        ],
      ),
    );
  }

  Widget _legendRow(String label, int count, Color color, int total) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.slate500,
                fontSize: 9,
              ),
            ),
          ),
          Text(
            total == 0
                ? '0 (0%)'
                : '$count (${(count * 100 / total).round()}%)',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.slate600,
              fontWeight: FontWeight.w700,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _DistrictDetailCard extends StatelessWidget {
  const _DistrictDetailCard({
    required this.agg,
    required this.expanded,
    required this.onToggle,
  });

  final DistrictSurveyAgg agg;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final List<PollingStationAgg> stations = agg.stations.values.toList()
      ..sort((PollingStationAgg a, PollingStationAgg b) =>
          b.count.compareTo(a.count));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: onToggle,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          agg.label,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          LocaleKeys.reportsDistrictMeta.tr(
                            args: <String>[
                              '${agg.stationCount}',
                              '${agg.total}',
                            ],
                          ),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.slate400,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _MiniChip(
                    label: LocaleKeys.reportsUrban.tr(),
                    value: '${agg.urban}',
                    color: AppColors.primaryBright,
                  ),
                  const SizedBox(width: 6),
                  _MiniChip(
                    label: LocaleKeys.reportsRural.tr(),
                    value: '${agg.rural}',
                    color: AppColors.warning,
                  ),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.slate400,
                  ),
                ],
              ),
            ),
            if (expanded) ...<Widget>[
              const Divider(height: 1, color: AppColors.slate100),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    LocaleKeys.reportsPollingStations.tr(),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              for (final PollingStationAgg s in stations)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        s.areaType == 'rural'
                            ? Icons.agriculture_outlined
                            : Icons.location_city_outlined,
                        size: 16,
                        color: s.areaType == 'rural'
                            ? AppColors.warning
                            : AppColors.primaryBright,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              s.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate700,
                              ),
                            ),
                            Text(
                              s.areaType == 'rural'
                                  ? LocaleKeys.reportsRural.tr()
                                  : s.areaType == 'urban'
                                      ? LocaleKeys.reportsUrban.tr()
                                      : LocaleKeys.reportsUnknownArea.tr(),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.slate400,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        LocaleKeys.reportsSurveyCount.tr(
                          args: <String>['${s.count}'],
                        ),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.slate600,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.brSm,
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w600,
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
              maxLines: 2,
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
