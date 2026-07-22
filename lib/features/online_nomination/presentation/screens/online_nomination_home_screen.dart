import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/features/online_nomination/data/models/nomination_draft.dart';
import 'package:evm_management_system/features/online_nomination/presentation/models/nomination_models.dart';
import 'package:evm_management_system/features/online_nomination/presentation/widgets/nomination_start_sheet.dart';
import 'package:evm_management_system/features/online_nomination/presentation/widgets/online_nomination_widgets.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

class OnlineNominationHomeScreen extends StatefulWidget {
  const OnlineNominationHomeScreen({super.key});

  @override
  State<OnlineNominationHomeScreen> createState() =>
      _OnlineNominationHomeScreenState();
}

class _OnlineNominationHomeScreenState
    extends State<OnlineNominationHomeScreen> {
  NominationDraft? _savedDraft;

  @override
  void activate() {
    super.activate();
    _loadSavedDraft();
  }

  @override
  void initState() {
    super.initState();
    _loadSavedDraft();
  }

  Future<void> _loadSavedDraft() async {
    final NominationDraft? draft = await AppServices.nominationDrafts
        .loadActive();
    if (!mounted) {
      return;
    }
    setState(() {
      _savedDraft = draft != null && draft.hasProgress ? draft : null;
    });
  }

  Future<void> _continueDraft() async {
    final NominationDraft? draft = _savedDraft;
    if (draft == null) {
      return;
    }
    await Get.toNamed<void>(
      AppRoute.nominationWorkflow.path,
      arguments: NominationFlowArgs(
        electionType: draft.electionType,
        postType: draft.postType,
        resumeDraft: true,
      ),
    );
    await _loadSavedDraft();
  }

  Future<void> _startFresh() async {
    await AppServices.nominationDrafts.clear();
    await _loadSavedDraft();
    if (!mounted) {
      return;
    }
    await showNominationStartSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    return NominationScreenShell(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: <Widget>[
          OnlineNominationHeader(
            onProfile: () => Get.toNamed<void>(AppRoute.profile.path),
            onNotifications: () =>
                Get.toNamed<void>(AppRoute.notifications.path),
          ),
          Padding(
            padding: AppSpacing.pageH,
            child: Column(
              children: <Widget>[
                const NominationHeroCard(),
                AppSpacing.vGapLg,
                if (_savedDraft != null)
                  NominationResumeDraftCard(
                    draft: _savedDraft!,
                    onContinue: _continueDraft,
                    onStartFresh: _startFresh,
                  ),
                NominationFeatureBullet(
                  icon: Icons.security_rounded,
                  title: LocaleKeys.nominationFeatureSecurityTitle.tr(),
                  subtitle: LocaleKeys.nominationFeatureSecurityDesc.tr(),
                ),
                NominationFeatureBullet(
                  icon: Icons.visibility_rounded,
                  title: LocaleKeys.nominationFeatureTransparencyTitle.tr(),
                  subtitle: LocaleKeys.nominationFeatureTransparencyDesc.tr(),
                ),
                NominationFeatureBullet(
                  icon: Icons.speed_rounded,
                  title: LocaleKeys.nominationFeatureSpeedTitle.tr(),
                  subtitle: LocaleKeys.nominationFeatureSpeedDesc.tr(),
                ),
                AppSpacing.vGapLg,
                NominationGovButton(
                  label: LocaleKeys.nominationActionStart.tr(),
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => showNominationStartSheet(context),
                ),
                AppSpacing.vGapSm,
                NominationGovButton(
                  label: LocaleKeys.nominationTrackStatusCta.tr(),
                  outlined: true,
                  onPressed: () => Get.toNamed<void>(
                    AppRoute.nominationTrackStatus.path,
                    arguments: const NominationFlowArgs(
                      electionType: NominationElectionType.urban,
                      postType: NominationPostType.mahapaur,
                    ),
                  ),
                ),
                AppSpacing.vGapSm,
                NominationGovButton(
                  label: LocaleKeys.commonBack.tr(),
                  icon: Icons.arrow_back,
                  onPressed: () => Get.back<void>(),
                ),
                AppSpacing.vGapMd,
                const NominationInfoNote(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
