import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:evm_management_system/core/network/connectivity_service.dart';
import 'package:evm_management_system/features/presiding_concern/data/constants/po_election_api_fields.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/presiding_election_context_store.dart';
import 'package:evm_management_system/features/presiding_concern/di/presiding_concern_module.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_election_context.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';
import 'package:evm_management_system/features/presiding_concern/domain/turnout_count_validator.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/theme/presiding_ui_tokens.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/utils/turnout_validation_message.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_po_screen_header.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_gender_avatar.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_gender_stat_column.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_info_card.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_session_scaffold.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_step_button.dart';
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
        // Live Voting is opt-in per booth/officer (PO login `IsLivePoll`
        // flag) — guard the route itself, not just the dashboard tile.
        if (!session.isLivePoll) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Get.currentRoute == AppRoute.presidingLivePoll.path) {
              Get.back<void>();
            }
          });
          return const SizedBox.shrink();
        }
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
  /// Quiet period after last +/- before syncing final counts to server.
  static const Duration _syncDebounce = Duration(milliseconds: 1500);

  bool _syncing = false;
  bool _localDirty = false;
  Timer? _debounceTimer;
  int _liveMale = 0;
  int _liveFemale = 0;
  int _liveOther = 0;
  DateTime? _lastUpdate;
  bool _pendingSync = false;
  bool _isOnline = true;
  StreamSubscription<bool>? _connectivitySub;
  int? _maleElectors;
  int? _femaleElectors;
  int? _otherElectors;
  int? _totalElectors;
  PresidingElectionContext? _electionContext;

  @override
  void initState() {
    super.initState();
    _electionContext = PresidingElectionContextStore.memoryCache;
    _syncFromSession();
    unawaited(_loadElectors());
    unawaited(_initConnectivity());
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _connectivitySub?.cancel();
    // Flush pending counts without setState — the element is already defunct
    // here, so `mounted` is still true but markNeedsBuild asserts.
    if (_localDirty && !_isReadOnly) {
      unawaited(_flushToServerOnDispose());
    }
    super.dispose();
  }

  Future<void> _flushToServerOnDispose() async {
    try {
      await Get.find<PresidingTurnoutController>().saveTurnout(
        slotId: TurnoutSlotIds.livePollInfo,
        male: _liveMale,
        female: _liveFemale,
        thirdGender: _liveOther,
      );
    } catch (e, st) {
      AppLogger.e(
        '[LivePoll] flush on dispose failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _initConnectivity() async {
    final ConnectivityService connectivity = AppServices.connectivity;
    final bool online = await connectivity.isOnline;
    if (mounted) setState(() => _isOnline = online);
    _connectivitySub = connectivity.onStatusChange.listen((bool online) {
      if (mounted) setState(() => _isOnline = online);
    });
  }

  @override
  void didUpdateWidget(covariant _LivePollBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Don't overwrite optimistic local counts while user is tapping / syncing.
    if (oldWidget.session != widget.session &&
        !_localDirty &&
        !_syncing &&
        !(_debounceTimer?.isActive ?? false)) {
      _syncFromSession();
    }
  }

  Future<void> _loadElectors() async {
    try {
      final PresidingElectionContextStore store = PresidingElectionContextStore(
        AppServices.secureStorage,
      );
      final PresidingElectionContext? ctx = await store.read();
      if (!mounted || ctx == null) return;
      setState(() {
        _electionContext = ctx;
        _maleElectors = ctx.maleElectors;
        _femaleElectors = ctx.femaleElectors;
        _otherElectors = ctx.otherElectors;
        _totalElectors = ctx.totalElectors;
      });
    } catch (_) {}
  }

  void _syncFromSession() {
    final TurnoutRecord? record =
        widget.session.turnoutRecords[TurnoutSlotIds.livePollInfo];
    _liveMale = record?.male ?? 0;
    _liveFemale = record?.female ?? 0;
    _liveOther = record?.thirdGender ?? 0;
    _lastUpdate = record?.savedAt;
    _pendingSync = record?.pendingSync ?? false;
  }

  bool get _isReadOnly {
    if (widget.session.turnoutRecords[TurnoutSlotIds.livePollInfo]?.isLocked ??
        false) {
      return true;
    }
    return widget.session.milestones.any(
      (PresidingMilestone m) =>
          (m.id == PresidingMilestoneIds.twoHourlyInfo ||
              m.id == PresidingMilestoneIds.livePollInfo) &&
          m.isCompleted,
    );
  }

  void _adjust({required String field, required int delta}) {
    if (_isReadOnly) return;
    final String button = delta > 0 ? '+1' : '-1';

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
    if (nextMale > TurnoutCountValidator.maxEnterableCount ||
        nextFemale > TurnoutCountValidator.maxEnterableCount ||
        nextOther > TurnoutCountValidator.maxEnterableCount) {
      return;
    }

    final TurnoutCountValidationResult validation =
        TurnoutCountValidator.validate(
      male: nextMale,
      female: nextFemale,
      other: nextOther,
      bounds: TurnoutCountValidator.boundsFor(
        session: widget.session,
        slotId: TurnoutSlotIds.livePollInfo,
        maxMale: _maleElectors,
        maxFemale: _femaleElectors,
        maxOther: _otherElectors,
      ),
    );
    if (!validation.isOk) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatTurnoutValidationMessage(validation))),
        );
      }
      return;
    }

    setState(() {
      _liveMale = nextMale;
      _liveFemale = nextFemale;
      _liveOther = nextOther;
      _localDirty = true;
      _pendingSync = true;
    });

    AppLogger.i(
      '[LivePoll] button click | $button | field=$field | '
      'local male=$_liveMale female=$_liveFemale other=$_liveOther | '
      'API debounce=${_syncDebounce.inMilliseconds}ms',
    );

    _scheduleServerSync();
  }

  void _scheduleServerSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_syncDebounce, () {
      unawaited(_flushToServer());
    });
    AppLogger.d(
      '[LivePoll] API scheduled in ${_syncDebounce.inMilliseconds}ms '
      '(resets on each +/- click)',
    );
  }

  Future<void> _flushToServer({bool force = false}) async {
    if (_isReadOnly) return;
    if (!_localDirty && !force) return;
    if (_syncing) {
      // In-flight request — retry after current call with latest counts.
      _scheduleServerSync();
      return;
    }

    final int male = _liveMale;
    final int female = _liveFemale;
    final int other = _liveOther;

    if (mounted) setState(() => _syncing = true);

    final Stopwatch sw = Stopwatch()..start();
    AppLogger.i(
      '[LivePoll] API call START | saveTurnout (debounced) | '
      'male=$male female=$female other=$other | '
      'startedAt=${DateTime.now().toIso8601String()}',
    );

    try {
      final PresidingSession saved =
          await Get.find<PresidingTurnoutController>().saveTurnout(
        slotId: TurnoutSlotIds.livePollInfo,
        male: male,
        female: female,
        thirdGender: other,
      );
      sw.stop();
      final TurnoutRecord? record =
          saved.turnoutRecords[TurnoutSlotIds.livePollInfo];
      AppLogger.i(
        '[LivePoll] API call SUCCESS | saveTurnout | '
        'elapsedMs=${sw.elapsedMilliseconds}ms '
        '(${(sw.elapsedMilliseconds / 1000).toStringAsFixed(2)}s) | '
        'pendingSync=${record?.pendingSync} | '
        'serverSavedAt=${record?.savedAt?.toIso8601String()} | '
        'finishedAt=${DateTime.now().toIso8601String()}',
      );

      if (!mounted) return;

      final bool countsChangedSinceFlush =
          _liveMale != male || _liveFemale != female || _liveOther != other;

      setState(() {
        _syncing = false;
        _lastUpdate = record?.savedAt ?? DateTime.now();
        if (!countsChangedSinceFlush) {
          _localDirty = false;
          _pendingSync = record?.pendingSync ?? false;
        } else {
          _pendingSync = true;
        }
      });

      if (countsChangedSinceFlush) {
        AppLogger.i(
          '[LivePoll] local counts changed during API — scheduling another sync',
        );
        _scheduleServerSync();
      }
    } on TurnoutCountValidationException catch (e) {
      sw.stop();
      if (mounted) {
        setState(() {
          _syncing = false;
          _localDirty = false;
          _pendingSync = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatTurnoutValidationMessage(e.result))),
        );
      }
    } catch (e, st) {
      sw.stop();
      AppLogger.e(
        '[LivePoll] API call FAILED | saveTurnout | '
        'elapsedMs=${sw.elapsedMilliseconds}ms '
        '(${(sw.elapsedMilliseconds / 1000).toStringAsFixed(2)}s) | '
        'error=$e',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        setState(() {
          _syncing = false;
          _pendingSync = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleKeys.commonSomethingWentWrong.tr()),
          ),
        );
      }
    }
  }

  String _formatTurnoutPercent(int votes, int? electors) {
    return PresidingElectionContext.formatTurnoutPercent(votes, electors);
  }

  @override
  Widget build(BuildContext context) {
    final String stationLabel =
        widget.session.pollingStationName.startsWith('presiding.')
        ? widget.session.pollingStationName.tr()
        : widget.session.pollingStationName;
    final int total = _liveMale + _liveFemale + _liveOther;
    final String totalPercent = _formatTurnoutPercent(total, _totalElectors);
    final bool showOnline = _isOnline && !_pendingSync && !_localDirty;
    final bool readOnly = _isReadOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PresidingPoScreenHeader(
          leading: AppCircleBackButton(onTap: () => Get.back<void>()),
          title: LocaleKeys.presidingLivePollTitle.tr(),
          subtitle: LocaleKeys.presidingPollingStation.tr(
            args: <String>[
              widget.session.pollingStationCode,
              stationLabel,
            ],
          ),
          electionContext: _electionContext,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: <Widget>[
              _StationInfoCard(
                stationCode: widget.session.pollingStationCode,
                stationName: stationLabel,
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  LocaleKeys.presidingLatestTurnoutStatus.tr(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: _LivePollStatCard(
                      genderType: PresidingGenderType.male,
                      count: _liveMale,
                      percent: _formatTurnoutPercent(
                        _liveMale,
                        _maleElectors,
                      ),
                      busy: false,
                      onAdd: readOnly
                          ? null
                          : () => _adjust(
                              field: PoElectionRequestFields.male,
                              delta: 1,
                            ),
                      onSubtract: readOnly || _liveMale <= 0
                          ? null
                          : () => _adjust(
                              field: PoElectionRequestFields.male,
                              delta: -1,
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LivePollStatCard(
                      genderType: PresidingGenderType.female,
                      count: _liveFemale,
                      percent: _formatTurnoutPercent(
                        _liveFemale,
                        _femaleElectors,
                      ),
                      busy: false,
                      onAdd: readOnly
                          ? null
                          : () => _adjust(
                              field: PoElectionRequestFields.female,
                              delta: 1,
                            ),
                      onSubtract: readOnly || _liveFemale <= 0
                          ? null
                          : () => _adjust(
                              field: PoElectionRequestFields.female,
                              delta: -1,
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LivePollStatCard(
                      genderType: PresidingGenderType.other,
                      count: _liveOther,
                      percent: _formatTurnoutPercent(
                        _liveOther,
                        _otherElectors,
                      ),
                      busy: false,
                      onAdd: readOnly
                          ? null
                          : () => _adjust(
                              field: PoElectionRequestFields.other,
                              delta: 1,
                            ),
                      onSubtract: readOnly || _liveOther <= 0
                          ? null
                          : () => _adjust(
                              field: PoElectionRequestFields.other,
                              delta: -1,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _LivePollSummaryCard(total: total, totalPercent: totalPercent),
              const SizedBox(height: 18),
              _InfoNoteCard(
                lastUpdate: _lastUpdate,
                isOnline: showOnline,
              ),
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
  });

  final String stationCode;
  final String stationName;

  @override
  Widget build(BuildContext context) {
    return PresidingInfoCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: PresidingUiTokens.actionGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
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
          PresidingGenderStatColumn(
            genderType: genderType,
            avatarSize: 56,
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
              PresidingStepButton(
                icon: Icons.remove_rounded,
                color: accentColor,
                size: 30,
                enabled: !busy && onSubtract != null,
                onPressed: onSubtract ?? () {},
              ),
              const SizedBox(width: 8),
              PresidingStepButton(
                icon: Icons.add_rounded,
                color: accentColor,
                size: 30,
                enabled: !busy && onAdd != null,
                onPressed: onAdd ?? () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LivePollSummaryCard extends StatelessWidget {
  const _LivePollSummaryCard({
    required this.total,
    required this.totalPercent,
  });
  final int total;
  final String totalPercent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _SummaryMetricTile(
            icon: Icons.how_to_vote_rounded,
            label: LocaleKeys.presidingTotalVotes.tr(),
            value: '$total',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryMetricTile(
            icon: Icons.percent_rounded,
            label: LocaleKeys.presidingTotalPercent.tr(),
            value: totalPercent,
          ),
        ),
      ],
    );
  }
}

class _SummaryMetricTile extends StatelessWidget {
  const _SummaryMetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return PresidingInfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: PresidingUiTokens.actionGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: PresidingUiTokens.actionGreen,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoNoteCard extends StatelessWidget {
  const _InfoNoteCard({
    required this.lastUpdate,
    required this.isOnline,
  });

  final DateTime? lastUpdate;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final DateTime? localUpdate = lastUpdate?.toLocal();
    final String dateText = localUpdate != null
        ? DateFormat('dd MMM yyyy').format(localUpdate)
        : '—';
    final String timeText = localUpdate != null
        ? DateFormat('hh:mm a').format(localUpdate)
        : '—';
    final Color statusColor = isOnline
        ? PresidingUiTokens.actionGreen
        : AppColors.warning;
    final String statusLabel = isOnline
        ? LocaleKeys.offlineHubOnline.tr()
        : LocaleKeys.offlineHubOffline.tr();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: PresidingUiTokens.cardGreenSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PresidingUiTokens.cardGreenBorder),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              children: <Widget>[
                Container(
                  width: 88,
                  height: 88,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: PresidingUiTokens.actionGreen.withValues(
                        alpha: 0.35,
                      ),
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          dateText,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.slate600,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeText,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.slate800,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  LocaleKeys.presidingServerUpdateTime.tr(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.slate600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: <Widget>[
                Container(
                  width: 88,
                  height: 88,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withValues(alpha: 0.12),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.45),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  LocaleKeys.presidingServerConnection.tr(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.slate600,
                    fontWeight: FontWeight.w700,
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
