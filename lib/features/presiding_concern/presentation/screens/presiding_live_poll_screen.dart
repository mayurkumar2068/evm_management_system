import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/features/presiding_concern/data/constants/po_election_api_fields.dart';
import 'package:evm_management_system/features/presiding_concern/di/presiding_concern_module.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/theme/presiding_ui_tokens.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_gender_avatar.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_session_scaffold.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

class PresidingLivePollScreen extends StatelessWidget {
  const PresidingLivePollScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PresidingSessionScaffold(
      builder: (BuildContext context, PresidingSession session) {
        return _LivePollBody(session: session);
      },
    );
  }
}

class _LivePollBody extends StatefulWidget {
  const _LivePollBody({required this.session});
  final PresidingSession session;

  @override
  State<_LivePollBody> createState() => _LivePollBodyState();
}

class _LivePollBodyState extends State<_LivePollBody> {
  bool _busy = false;
  int _liveMale = 0;
  int _liveFemale = 0;
  int _liveOther = 0;
  DateTime? _lastUpdate;

  @override
  void initState() {
    super.initState();
    _syncFromSession();
  }

  @override
  void didUpdateWidget(covariant _LivePollBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      _syncFromSession();
    }
  }

  void _syncFromSession() {
    final TurnoutRecord? record =
        widget.session.turnoutRecords[TurnoutSlotIds.livePollInfo];
    _liveMale = record?.male ?? 0;
    _liveFemale = record?.female ?? 0;
    _liveOther = record?.thirdGender ?? 0;
    _lastUpdate = record?.savedAt;
  }

  Future<void> _adjust({required String field, required int delta}) async {
    if (_busy) return;

    final int prevMale = _liveMale;
    final int prevFemale = _liveFemale;
    final int prevOther = _liveOther;

    final int nextMale = field == PoElectionRequestFields.male
        ? _liveMale + delta
        : _liveMale;
    final int nextFemale = field == PoElectionRequestFields.female
        ? _liveFemale + delta
        : _liveFemale;
    final int nextOther = field == PoElectionRequestFields.other
        ? _liveOther + delta
        : _liveOther;

    if (nextMale < 0 || nextFemale < 0 || nextOther < 0) return;

    setState(() {
      _busy = true;
      _liveMale = nextMale;
      _liveFemale = nextFemale;
      _liveOther = nextOther;
    });

    try {
      await Get.find<PresidingTurnoutController>().saveTurnout(
        slotId: TurnoutSlotIds.livePollInfo,
        male: nextMale,
        female: nextFemale,
        thirdGender: nextOther,
      );
      if (mounted) {
        setState(() => _lastUpdate = DateTime.now());
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _liveMale = prevMale;
          _liveFemale = prevFemale;
          _liveOther = prevOther;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocaleKeys.presidingNotSaved.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatSharePercent(int count, int total) {
    if (total <= 0 || count <= 0) return '0%';
    return LocaleKeys.presidingTurnoutSharePercent.tr(
      args: <String>['${(count / total * 100).toStringAsFixed(2)}%'],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String stationLabel =
        widget.session.pollingStationName.startsWith('presiding.')
        ? widget.session.pollingStationName.tr()
        : widget.session.pollingStationName;
    final int total = _liveMale + _liveFemale + _liveOther;
    final String lastUpdateLabel = _lastUpdate != null
        ? DateFormat('hh:mm a').format(_lastUpdate!)
        : LocaleKeys.presidingNotSaved.tr();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppGradientHeader(
          leading: AppCircleBackButton(onTap: () => Get.back<void>()),
          title: LocaleKeys.presidingLivePollTitle.tr(),
          subtitle: LocaleKeys.presidingLivePollSubtitle.tr(),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.fiber_manual_record_rounded,
                  color: PresidingUiTokens.liveAccent,
                  size: 10,
                ),
                const SizedBox(width: 6),
                Text(
                  LocaleKeys.presidingLiveBadge.tr(),
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.sensors_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: <Widget>[
              _StationInfoCard(
                stationCode: widget.session.pollingStationCode,
                stationName: stationLabel,
                lastUpdate: lastUpdateLabel,
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: PresidingUiTokens.actionGreen.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.bar_chart_rounded,
                      color: PresidingUiTokens.actionGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    LocaleKeys.presidingLatestTurnoutStatus.tr(),
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: _LivePollStatCard(
                      genderType: PresidingGenderType.male,
                      count: _liveMale,
                      percent: _formatSharePercent(_liveMale, total),
                      busy: _busy,
                      onAdd: () => _adjust(
                        field: PoElectionRequestFields.male,
                        delta: 1,
                      ),
                      onSubtract: _liveMale > 0
                          ? () => _adjust(
                              field: PoElectionRequestFields.male,
                              delta: -1,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LivePollStatCard(
                      genderType: PresidingGenderType.female,
                      count: _liveFemale,
                      percent: _formatSharePercent(_liveFemale, total),
                      busy: _busy,
                      onAdd: () => _adjust(
                        field: PoElectionRequestFields.female,
                        delta: 1,
                      ),
                      onSubtract: _liveFemale > 0
                          ? () => _adjust(
                              field: PoElectionRequestFields.female,
                              delta: -1,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LivePollStatCard(
                      genderType: PresidingGenderType.other,
                      count: _liveOther,
                      percent: _formatSharePercent(_liveOther, total),
                      busy: _busy,
                      onAdd: () => _adjust(
                        field: PoElectionRequestFields.other,
                        delta: 1,
                      ),
                      onSubtract: _liveOther > 0
                          ? () => _adjust(
                              field: PoElectionRequestFields.other,
                              delta: -1,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _LivePollSummaryCard(total: total),
              const SizedBox(height: 18),
              const _InfoNoteCard(),
            ],
          ),
        ),
      ],
    );
  }
}

class _StationInfoCard extends StatelessWidget {
  const _StationInfoCard({
    required this.stationCode,
    required this.stationName,
    required this.lastUpdate,
  });

  final String stationCode;
  final String stationName;
  final String lastUpdate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PresidingUiTokens.cardGreenSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PresidingUiTokens.cardGreenBorder),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: PresidingUiTokens.actionGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: PresidingUiTokens.actionGreen,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  LocaleKeys.presidingPollingStationNumber.tr(
                    args: <String>[stationCode],
                  ),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stationName,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.slate600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                LocaleKeys.presidingLastUpdate.tr(),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.slate500,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.access_time_rounded,
                    color: AppColors.slate500,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    lastUpdate,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.slate700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LivePollStatCard extends StatelessWidget {
  const _LivePollStatCard({
    required this.genderType,
    required this.count,
    required this.percent,
    required this.busy,
    this.onAdd,
    this.onSubtract,
  });

  final PresidingGenderType genderType;
  final int count;
  final String percent;
  final bool busy;
  final VoidCallback? onAdd;
  final VoidCallback? onSubtract;

  @override
  Widget build(BuildContext context) {
    final Color accentColor = PresidingGenderAssets.colorFor(genderType);
    final String label = PresidingGenderAssets.labelKeyFor(genderType).tr();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          PresidingGenderAvatar(type: genderType, size: 56),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            percent,
            style: AppTextStyles.caption.copyWith(
              color: accentColor.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _LiveStepButton(
                icon: Icons.remove_rounded,
                color: accentColor,
                onTap: busy ? null : onSubtract,
              ),
              const SizedBox(width: 8),
              _LiveStepButton(
                icon: Icons.add_rounded,
                color: accentColor,
                onTap: busy ? null : onAdd,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            LocaleKeys.presidingIncreaseByOne.tr(),
            style: AppTextStyles.caption.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveStepButton extends StatelessWidget {
  const _LiveStepButton({required this.icon, required this.color, this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? color.withValues(alpha: 0.35) : color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _LivePollSummaryCard extends StatelessWidget {
  const _LivePollSummaryCard({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PresidingUiTokens.cardGreenSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PresidingUiTokens.cardGreenBorder),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: PresidingUiTokens.actionGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.how_to_vote_rounded,
              color: PresidingUiTokens.actionGreen,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  LocaleKeys.presidingTotalVotes.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$total',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 32,
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

class _InfoNoteCard extends StatelessWidget {
  const _InfoNoteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PresidingUiTokens.cardGreenSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PresidingUiTokens.cardGreenBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            size: 20,
            color: PresidingUiTokens.actionGreen,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              LocaleKeys.presidingLivePollNote.tr(),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.slate600,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
