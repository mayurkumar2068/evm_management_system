import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/features/online_nomination/presentation/models/nomination_models.dart';
import 'package:evm_management_system/features/online_nomination/presentation/widgets/online_nomination_widgets.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Start flow: Login / Registration → (animated) Urban / Panchayat.
Future<void> showNominationStartSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    clipBehavior: Clip.antiAlias,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext ctx) => const _NominationStartSheet(),
  );
}

enum _NominationSheetStep { auth, electionType }

class _NominationStartSheet extends StatefulWidget {
  const _NominationStartSheet();

  @override
  State<_NominationStartSheet> createState() => _NominationStartSheetState();
}

class _NominationStartSheetState extends State<_NominationStartSheet> {
  _NominationSheetStep _step = _NominationSheetStep.auth;

  void _goToElectionType() {
    setState(() => _step = _NominationSheetStep.electionType);
  }

  void _goToAuth() {
    setState(() => _step = _NominationSheetStep.auth);
  }

  void _openLogin() {
    Navigator.pop(context);
    Get.toNamed<void>(
      AppRoute.nominationTrackStatus.path,
      arguments: const NominationFlowArgs(
        electionType: NominationElectionType.urban,
        postType: NominationPostType.mahapaur,
      ),
    );
  }

  void _openUrban() {
    Navigator.pop(context);
    Get.toNamed<void>(AppRoute.urbanNominationSelection.path);
  }

  void _openPanchayat() {
    Navigator.pop(context);
    Get.toNamed<void>(AppRoute.panchayatNominationSelection.path);
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bool isAuth = _step == _NominationSheetStep.auth;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg + bottomInset,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: context.appDivider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              AppSpacing.vGapMd,
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final Animation<Offset> slide = Tween<Offset>(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<_NominationSheetStep>(_step),
                  child: isAuth ? _buildAuthStep() : _buildElectionTypeStep(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthStep() {
    return Column(
      key: const ValueKey<String>('auth'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          LocaleKeys.nominationEntryTitle.tr(),
          style: AppTextStyles.variant(
            AppTextStyles.titleMedium,
            fontWeight: FontWeight.w700,
            color: context.appOnSurface,
          ),
        ),
        AppSpacing.vGapXs,
        Text(
          LocaleKeys.nominationEntrySubtitle.tr(),
          style: AppTextStyles.variant(
            AppTextStyles.bodyMedium,
            color: context.appMuted,
          ),
        ),
        AppSpacing.vGapMd,
        NominationLargeOptionCard(
          featured: true,
          title: LocaleKeys.nominationEntryLoginTitle.tr(),
          subtitle: LocaleKeys.nominationEntryLoginSubtitle.tr(),
          icon: Icons.login_rounded,
          onTap: _openLogin,
        ),
        AppSpacing.vGapMd,
        NominationLargeOptionCard(
          featured: true,
          title: LocaleKeys.nominationEntryRegisterTitle.tr(),
          subtitle: LocaleKeys.nominationEntryRegisterSubtitle.tr(),
          icon: Icons.app_registration_rounded,
          onTap: _goToElectionType,
        ),
        AppSpacing.vGapSm,
      ],
    );
  }

  Widget _buildElectionTypeStep() {
    return Column(
      key: const ValueKey<String>('election'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Material(
              color: context.appChip,
              borderRadius: AppRadius.brMd,
              child: InkWell(
                onTap: _goToAuth,
                borderRadius: AppRadius.brMd,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: context.appOnSurface,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    LocaleKeys.nominationWelcomeTitle.tr(),
                    style: AppTextStyles.variant(
                      AppTextStyles.titleMedium,
                      fontWeight: FontWeight.w700,
                      color: context.appOnSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    LocaleKeys.nominationUrbanSelectSubtitle.tr(),
                    style: AppTextStyles.variant(
                      AppTextStyles.bodyMedium,
                      color: context.appMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        AppSpacing.vGapMd,
        NominationLargeOptionCard(
          featured: true,
          title: LocaleKeys.nominationUrbanTitle.tr(),
          subtitle: LocaleKeys.nominationUrbanSubtitle.tr(),
          icon: Icons.location_city_outlined,
          onTap: _openUrban,
        ),
        AppSpacing.vGapMd,
        NominationLargeOptionCard(
          featured: true,
          title: LocaleKeys.nominationPanchayatTitle.tr(),
          subtitle: LocaleKeys.nominationPanchayatSubtitle.tr(),
          icon: Icons.account_balance_outlined,
          onTap: _openPanchayat,
        ),
        AppSpacing.vGapSm,
      ],
    );
  }
}
