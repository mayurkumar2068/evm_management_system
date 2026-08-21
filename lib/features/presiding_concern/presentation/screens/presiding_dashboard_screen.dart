import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/design_system/mpsec/mpsec_design_system.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/presiding_election_context_store.dart';
import 'package:evm_management_system/features/presiding_concern/di/presiding_concern_module.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_action_outcome.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_election_context.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/controllers/presiding_party_controller.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/services/presiding_turnout_report_pdf_service.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_elector_header_strip.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_po_screen_header.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_milestone_section.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_party_details_sheet.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_party_mandatory_banner.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_session_scaffold.dart';
import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_theme_button.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Presiding-officer election-day milestone dashboard.
class PresidingDashboardScreen extends StatelessWidget {
  const PresidingDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PresidingSessionScaffold(
      builder: (BuildContext context, PresidingSession session) {
        return _DashboardBody(session: session);
      },
    );
  }
}

class _DashboardBody extends StatefulWidget {
  const _DashboardBody({required this.session});

  final PresidingSession session;

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  PresidingPartyController get _partyCtrl =>
      Get.find<PresidingPartyController>();
  bool _partyPromptShown = false;
  PresidingElectionContext? _electionContext;

  @override
  void initState() {
    super.initState();
    final ServiceSession? session = AppServices.serviceAuth.session.value;
    if (session != null) {
      PresidingElectionContextStore.warmFromServiceSession(session);
    }
    _electionContext = PresidingElectorHeaderStrip.resolveContext(null);
    unawaited(_loadElectionContext());
    unawaited(_bootstrapPartyGate());
  }

  Future<void> _loadElectionContext() async {
    try {
      final PresidingElectionContextStore store = PresidingElectionContextStore(
        AppServices.secureStorage,
      );
      final PresidingElectionContext? ctx = await store.read();
      if (!mounted) return;
      setState(
        () => _electionContext = PresidingElectorHeaderStrip.resolveContext(
          PresidingElectionContextStore.preferWithElectors(
            ctx,
            PresidingElectionContextStore.memoryCache,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _electionContext = PresidingElectionContextStore.memoryCache,
      );
    }
  }

  Future<void> _bootstrapPartyGate() async {
    await _partyCtrl.reload();
    if (!mounted) return;
    await _promptPartyIfRequired(auto: true);
  }

  Future<void> _openPartySheet() async {
    await showPresidingPartyDetailsSheet(
      context,
      onCompleted: () => unawaited(_partyCtrl.reload()),
    );
  }

  Future<bool> _promptPartyIfRequired({bool auto = false}) async {
    if (_partyCtrl.isComplete.value) return true;
    if (auto && _partyPromptShown) return false;
    if (auto) _partyPromptShown = true;

    await AppDialog.alert(
      context,
      title: LocaleKeys.presidingPartyMandatoryTitle.tr(),
      message: LocaleKeys.presidingPartyRequiredMessage.tr(),
      actionLabel: LocaleKeys.presidingPartyFillNow.tr(),
    );
    if (!mounted) return false;
    await _openPartySheet();
    return _partyCtrl.isComplete.value;
  }

  /// IPBMS material-tracking is opt-in — when the officer doesn't do it,
  /// treat पोल-एंड (auto-derived from 2-2 hourly finish) as the "done" mark
  /// instead of the hidden निर्वाचन सामग्री सौंपी गई step.
  bool get _canGenerateReport => widget.session.milestones.any(
        (PresidingMilestone m) =>
            m.id ==
                (widget.session.isIpbms
                    ? PresidingMilestoneIds.materialHandedOver
                    : PresidingMilestoneIds.pollEnd) &&
            m.isCompleted,
      );

  Future<void> _generateReport() async {
    if (!_canGenerateReport) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.presidingGenerateReportLocked.tr())),
      );
      return;
    }
    final PresidingElectionContextStore store = PresidingElectionContextStore(
      AppServices.secureStorage,
    );
    final PresidingElectionContext? stored = await store.read();
    final PresidingElectionContext? electionContext =
        PresidingElectorHeaderStrip.resolveContext(stored);
    if (!mounted) return;
    await PresidingTurnoutReportPdfService.openReport(
      session: widget.session,
      electionContext: electionContext,
    );
  }

  Future<void> _onRefresh(BuildContext context) async {
    final PresidingDashboardController controller =
        Get.find<PresidingDashboardController>();
    final bool ok = await controller.syncNow();
    await _loadElectionContext();
    if (!context.mounted) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (!controller.isOnline.value) {
      messenger.showSnackBar(
        SnackBar(content: Text(LocaleKeys.presidingSyncOffline.tr())),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? LocaleKeys.presidingSyncSuccess.tr()
              : LocaleKeys.presidingSyncFailed.tr(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final PresidingDashboardController controller =
        Get.find<PresidingDashboardController>();
    final String stationLabel =
        widget.session.pollingStationName.startsWith('presiding.')
        ? widget.session.pollingStationName.tr()
        : widget.session.pollingStationName;

    final Map<String, List<PresidingMilestone>> grouped =
        <String, List<PresidingMilestone>>{};
    for (final PresidingMilestone milestone in widget.session.milestones) {
      // मतदान समाप्त is submitted via 2–2 hourly finish — hide from section 4.
      if (milestone.id == PresidingMilestoneIds.pollEnd) continue;
      // Live Voting is opt-in per booth/officer (PO login `IsLivePoll` flag).
      if (milestone.id == PresidingMilestoneIds.livePollInfo &&
          !widget.session.isLivePoll) {
        continue;
      }
      // IPBMS material-tracking steps are opt-in too (PO login `IsIPBMS`
      // flag) — when disabled, the flow starts from "मतदान केंद्र पहुंचे".
      if (!widget.session.isIpbms &&
          PresidingSession.ipbmsMilestoneIds.contains(milestone.id)) {
        continue;
      }
      grouped.putIfAbsent(milestone.sectionId, () => <PresidingMilestone>[]);
      grouped[milestone.sectionId]!.add(milestone);
    }

    final List<_SectionMeta> sections = <_SectionMeta>[
      _SectionMeta(
        1,
        PresidingSectionIds.arrival,
        LocaleKeys.presidingSectionArrival.tr(),
      ),
      _SectionMeta(
        2,
        PresidingSectionIds.prePoll,
        LocaleKeys.presidingSectionPrePoll.tr(),
      ),
      _SectionMeta(
        3,
        PresidingSectionIds.duringPoll,
        LocaleKeys.presidingSectionDuringPoll.tr(),
      ),
      _SectionMeta(
        4,
        PresidingSectionIds.postPoll,
        LocaleKeys.presidingSectionPostPoll.tr(),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PresidingPoScreenHeader(
          title: LocaleKeys.presidingOfficerTitle.tr(),
          subtitle: LocaleKeys.presidingPollingStation.tr(
            args: <String>[
              widget.session.pollingStationCode,
              stationLabel,
            ],
          ),
          electionContext: _electionContext,
          leading: AppCircleBackButton(onTap: () => Get.back<void>()),
          trailing: Obx(() {
            final bool syncing = controller.isSyncing.value;
            final bool online = controller.isOnline.value;
            return IconButton(
              tooltip: LocaleKeys.presidingSyncRefresh.tr(),
              onPressed: syncing ? null : () => _onRefresh(context),
              icon: syncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      online ? Icons.sync_rounded : Icons.cloud_off_rounded,
                      color: Colors.white,
                    ),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  LocaleKeys.presidingEnterInfo.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.slate700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Obx(() {
                final bool online = controller.isOnline.value;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: online
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    online
                        ? LocaleKeys.presidingOnline.tr()
                        : LocaleKeys.presidingOffline.tr(),
                    style: AppTextStyles.caption.copyWith(
                      color: online
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFE65100),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Obx(() {
            return PresidingPartyMandatoryBanner(
              onTap: _openPartySheet,
              isComplete: _partyCtrl.isComplete.value,
            );
          }),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: <Widget>[
              for (final _SectionMeta section in sections)
                if ((grouped[section.id] ?? <PresidingMilestone>[]).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: MpSecTokens.sectionSpacing,
                    ),
                    child: PresidingMilestoneSectionCard(
                      index: section.index,
                      title: section.title,
                      milestones: grouped[section.id]!,
                      // Booth map / "देखें" only when PO login `IsIPBMS` is true.
                      boothMapStationName:
                          section.index == 1 && widget.session.isIpbms
                          ? stationLabel
                          : null,
                      isMilestoneEnabled: (PresidingMilestone milestone) =>
                          widget.session.isMilestoneActionEnabled(milestone.id),
                      onMilestoneTap: (PresidingMilestone milestone) async {
                        if (milestone.isCompleted) return;

                        if (!_partyCtrl.isComplete.value) {
                          await _promptPartyIfRequired();
                          return;
                        }

                        final String? blockKey =
                            widget.session.milestoneActionBlockKey(milestone.id);
                        if (blockKey != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(blockKey.tr())),
                          );
                          return;
                        }

                        if (milestone.id ==
                            PresidingMilestoneIds.livePollInfo) {
                          await Get.toNamed<void>(
                            AppRoute.presidingLivePoll.path,
                          );
                          return;
                        }

                        if (milestone.opensTurnout) {
                          await Get.toNamed<void>(
                            AppRoute.presidingTurnout.path,
                          );
                          return;
                        }

                        final PresidingActionOutcome outcome = await controller
                            .completeMilestone(milestone.id);
                        if (!context.mounted) return;
                        final String? msg = outcome.message;
                        if (msg == LocaleKeys.presidingPollStartBefore7Am ||
                            msg == LocaleKeys.presidingReachStationFirst) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg!.tr())),
                          );
                          return;
                        }
                        if (outcome.alreadyRegistered) {
                          final String text = msg?.isNotEmpty ?? false
                              ? msg!
                              : LocaleKeys.presidingAlreadyRegistered.tr();
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(text)));
                        }
                      },
                    ),
                  ),
              const SizedBox(height: 4),
              PresidingThemeButton(
                label: LocaleKeys.presidingGenerateReport.tr(),
                icon: Icons.picture_as_pdf_outlined,
                onPressed: _canGenerateReport ? _generateReport : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionMeta {
  const _SectionMeta(this.index, this.id, this.title);
  final int index;
  final String id;
  final String title;
}
