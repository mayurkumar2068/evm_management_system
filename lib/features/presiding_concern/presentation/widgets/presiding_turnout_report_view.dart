import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/time/app_time_zone.dart';
import 'package:evm_management_system/features/presiding_concern/data/config/turnout_slot_registry.dart';
import 'package:evm_management_system/features/presiding_concern/domain/constants/presiding_area_type.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_election_context.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Printable election-day report — Flutter UI (app header/theme) captured to PNG/PDF.
class PresidingTurnoutReportView extends StatelessWidget {
  const PresidingTurnoutReportView({
    required this.session,
    this.electionContext,
    this.poName,
    this.poMobile,
    this.width = 595,
    super.key,
  });

  final PresidingSession session;
  final PresidingElectionContext? electionContext;
  final String? poName;
  final String? poMobile;
  final double width;

  @override
  Widget build(BuildContext context) {
    final String stationName =
        session.pollingStationName.startsWith('presiding.')
        ? session.pollingStationName.tr()
        : session.pollingStationName;
    final String areaLabel = PresidingAreaType.parse(session.areaType).isUrban
        ? LocaleKeys.presidingReportUrban.tr()
        : LocaleKeys.presidingReportRural.tr();
    final String generatedAt = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(AppTimeZone.now());
    final int? totalElectors = electionContext?.totalElectors;
    final TurnoutRecord? live =
        session.turnoutRecords[TurnoutSlotIds.livePollInfo];
    final int liveTotal =
        (live?.male ?? 0) + (live?.female ?? 0) + (live?.thirdGender ?? 0);
    // Mirror dashboard visibility: Live Voting / IPBMS material-tracking
    // steps stay off the printed report too when the PO login flag is off.
    final List<PresidingMilestone> reportMilestones = session.milestones
        .where(
          (PresidingMilestone m) =>
              !(m.id == PresidingMilestoneIds.livePollInfo &&
                  !session.isLivePoll) &&
              !(!session.isIpbms &&
                  PresidingSession.ipbmsMilestoneIds.contains(m.id)),
        )
        .toList(growable: false);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: EdgeInsets.zero,
        viewPadding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
        textScaler: TextScaler.noScaling,
      ),
      child: Container(
        width: width,
        color: AppColors.background,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppGradientHeader(
              title: LocaleKeys.presidingReportTitle.tr(),
              subtitle: LocaleKeys.presidingReportSubtitle.tr(),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              leading: Container(
                width: 38,
                height: 38,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  BrandLogo.asset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.how_to_vote_rounded,
                    color: AppColors.primaryDark,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _InfoCard(
              rows: <_InfoRow>[
                if ((poName ?? '').trim().isNotEmpty)
                  _InfoRow(
                    label: LocaleKeys.presidingReportPoName.tr(),
                    value: poName!.trim(),
                  ),
                if ((poMobile ?? '').trim().isNotEmpty)
                  _InfoRow(
                    label: LocaleKeys.presidingReportPoMobile.tr(),
                    value: poMobile!.trim(),
                  ),
                _InfoRow(
                  label: LocaleKeys.presidingReportStation.tr(),
                  value: '$stationName (${session.pollingStationCode})',
                ),
                _InfoRow(
                  label: LocaleKeys.presidingReportArea.tr(),
                  value: areaLabel,
                ),
                if (totalElectors != null)
                  _InfoRow(
                    label: LocaleKeys.presidingReportElectors.tr(),
                    value: '$totalElectors',
                  ),
                _InfoRow(
                  label: LocaleKeys.presidingReportGenerated.tr(),
                  value: generatedAt,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _MilestoneTable(milestones: reportMilestones),
            const SizedBox(height: 14),
            _SectionTitle(LocaleKeys.presidingReportTurnout.tr()),
            const SizedBox(height: 8),
            _TurnoutTable(session: session, totalElectors: totalElectors),
            if (session.isLivePoll) ...<Widget>[
              const SizedBox(height: 14),
              _LivePollCard(
                title: LocaleKeys.presidingLivePollTitle.tr(),
                live: live,
                liveTotal: liveTotal,
                totalElectors: totalElectors,
              ),
            ],
            const SizedBox(height: 14),
            Text(
              LocaleKeys.presidingReportFooter.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.slate500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.outline),
        borderRadius: AppRadius.brLg,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: rows
            .map(
              (_InfoRow row) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 130,
                      child: Text(
                        row.label,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.slate600,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.titleSmall.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.primaryDeep,
      ),
    );
  }
}

class _MilestoneTable extends StatelessWidget {
  const _MilestoneTable({required this.milestones});

  final List<PresidingMilestone> milestones;

  @override
  Widget build(BuildContext context) {
    return _ReportTable(
      columns: <String>[
        LocaleKeys.presidingReportStep.tr(),
        LocaleKeys.presidingReportStatus.tr(),
        LocaleKeys.presidingReportTime.tr(),
      ],
      flexes: const <int>[4, 2, 2],
      rows: <_ReportTableRow>[
        for (int i = 0; i < milestones.length; i++)
          _ReportTableRow(
            cells: <String>[
              milestones[i].labelKey.tr(),
              milestones[i].isCompleted
                  ? LocaleKeys.presidingReportDone.tr()
                  : LocaleKeys.presidingReportPending.tr(),
              milestones[i].completedAt == null
                  ? '—'
                  : DateFormat('hh:mm a').format(milestones[i].completedAt!),
            ],
            zebra: i.isOdd,
            done: milestones[i].isCompleted,
          ),
      ],
    );
  }
}

class _TurnoutTable extends StatelessWidget {
  const _TurnoutTable({required this.session, required this.totalElectors});

  final PresidingSession session;
  final int? totalElectors;

  @override
  Widget build(BuildContext context) {
    final List<TurnoutSlotConfig> slots = TurnoutSlotRegistry.forAreaType(
      session.areaType,
    );
    final List<_ReportTableRow> rows = <_ReportTableRow>[];

    for (final TurnoutSlotConfig config in slots) {
      final TurnoutRecord? record = session.turnoutRecords[config.slotId];
      if (record == null) continue;

      if (config.queueOnly) {
        rows.add(
          _ReportTableRow(
            cells: <String>[
              config.labelKey.tr(),
              '—',
              '—',
              '—',
              '${record.queueCount ?? 0}',
              '—',
            ],
            zebra: rows.length.isOdd,
          ),
        );
        continue;
      }

      final int male = record.male ?? 0;
      final int female = record.female ?? 0;
      final int other = record.thirdGender ?? 0;
      final int total = male + female + other;
      final String pct = totalElectors != null && totalElectors! > 0
          ? PresidingElectionContext.formatTurnoutPercent(total, totalElectors)
          : '—';
      rows.add(
        _ReportTableRow(
          cells: <String>[
            config.labelKey.tr(),
            '$male',
            '$female',
            '$other',
            '$total',
            pct,
          ],
          zebra: rows.length.isOdd,
        ),
      );
    }

    return _ReportTable(
      columns: <String>[
        LocaleKeys.presidingReportSlot.tr(),
        LocaleKeys.presidingMale.tr(),
        LocaleKeys.presidingFemale.tr(),
        LocaleKeys.presidingThirdGender.tr(),
        LocaleKeys.presidingReportColTotal.tr(),
        '%',
      ],
      flexes: const <int>[3, 2, 2, 2, 2, 1],
      rows: rows,
    );
  }
}

class _LivePollCard extends StatelessWidget {
  const _LivePollCard({
    required this.title,
    required this.live,
    required this.liveTotal,
    required this.totalElectors,
  });

  final String title;
  final TurnoutRecord? live;
  final int liveTotal;
  final int? totalElectors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.55),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
        borderRadius: AppRadius.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDeep,
            ),
          ),
          const SizedBox(height: 8),
          _liveRow(LocaleKeys.presidingMale.tr(), '${live?.male ?? 0}'),
          _liveRow(LocaleKeys.presidingFemale.tr(), '${live?.female ?? 0}'),
          _liveRow(
            LocaleKeys.presidingThirdGender.tr(),
            '${live?.thirdGender ?? 0}',
          ),
          _liveRow(
            LocaleKeys.presidingTotalVotes.tr(),
            '$liveTotal',
            bold: true,
          ),
          if (totalElectors != null && totalElectors! > 0)
            _liveRow(
              LocaleKeys.presidingTotalPercent.tr(),
              PresidingElectionContext.formatTurnoutPercent(
                liveTotal,
                totalElectors,
              ),
              bold: true,
            ),
        ],
      ),
    );
  }

  Widget _liveRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                color: AppColors.slate600,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTableRow {
  const _ReportTableRow({
    required this.cells,
    this.zebra = false,
    this.done = false,
  });

  final List<String> cells;
  final bool zebra;
  final bool done;
}

class _ReportTable extends StatelessWidget {
  const _ReportTable({
    required this.columns,
    required this.flexes,
    required this.rows,
  });

  final List<String> columns;
  final List<int> flexes;
  final List<_ReportTableRow> rows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.outline),
        borderRadius: AppRadius.brSm,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.brSm,
        child: Column(
          children: <Widget>[
            _tableRow(columns, header: true, flexes: flexes),
            for (final _ReportTableRow row in rows)
              _tableRow(
                row.cells,
                flexes: flexes,
                zebra: row.zebra,
                done: row.done,
              ),
          ],
        ),
      ),
    );
  }

  Widget _tableRow(
    List<String> cells, {
    required List<int> flexes,
    bool header = false,
    bool zebra = false,
    bool done = false,
  }) {
    return Container(
      color: header
          ? AppColors.primaryLight
          : zebra
          ? AppColors.slate50
          : AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Row(
        children: List<Widget>.generate(cells.length, (int i) {
          final bool statusCol = !header && done && i == 1;
          return Expanded(
            flex: flexes[i],
            child: Row(
              mainAxisAlignment: i == 0
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: <Widget>[
                if (statusCol)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 12,
                      color: AppColors.success,
                    ),
                  ),
                Flexible(
                  child: Text(
                    cells[i],
                    textAlign: i == 0 ? TextAlign.start : TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: header ? 10 : 10,
                      fontWeight: header || done && i == 1
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: header
                          ? AppColors.primaryDeep
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
