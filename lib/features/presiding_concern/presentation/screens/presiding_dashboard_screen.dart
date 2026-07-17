import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/design_system/mpsec/mpsec_design_system.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:evm_management_system/features/presiding_concern/di/presiding_concern_module.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_action_outcome.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_milestone_section.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_session_scaffold.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
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

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.session});

  final PresidingSession session;

  @override
  Widget build(BuildContext context) {
    final String stationLabel =
        session.pollingStationName.startsWith('presiding.')
        ? session.pollingStationName.tr()
        : session.pollingStationName;

    final Map<String, List<PresidingMilestone>> grouped =
        <String, List<PresidingMilestone>>{};
    for (final PresidingMilestone milestone in session.milestones) {
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
      children: <Widget>[
        AppGradientHeader(
          title: LocaleKeys.presidingOfficerTitle.tr(),
          subtitle: LocaleKeys.presidingPollingStation.tr(
            args: <String>[session.pollingStationCode, stationLabel],
          ),
          bottom: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              LocaleKeys.presidingEnterInfo.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.slate100,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(
                  bottom: MpSecTokens.sectionSpacing,
                ),
                child: AppGradientButton(
                  icon: Icons.how_to_vote_rounded,
                  label: LocaleKeys.commonContinue.tr(),
                  onPressed: () =>
                      Get.toNamed<void>(AppRoute.presidingLivePoll.path),
                ),
              ),
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
                      onMilestoneTap: (PresidingMilestone milestone) async {
                        // Navigate to specific turnout entry screen based on milestone
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

                        if (milestone.isCompleted) return;

                        final PresidingDashboardController controller =
                            Get.find<PresidingDashboardController>();
                        final PresidingActionOutcome outcome = await controller
                            .completeMilestone(milestone.id);
                        if (!context.mounted) return;
                        if (outcome.alreadyRegistered) {
                          final String message =
                              outcome.message?.isNotEmpty ?? false
                              ? outcome.message!
                              : LocaleKeys.presidingAlreadyRegistered.tr();
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(message)));
                        }
                      },
                    ),
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
