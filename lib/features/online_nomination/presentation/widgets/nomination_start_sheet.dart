import 'dart:ui';

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
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.22),
    builder: (BuildContext ctx) {
      final double bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 24, 10, 8),
              child: _NominationStartSheet(),
            ),
            Positioned(
              top: 0,
              right: 18,
              child: _GlassCloseButton(onTap: () => Navigator.pop(ctx)),
            ),
          ],
        ),
      );
    },
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
    final bool isAuth = _step == _NominationSheetStep.auth;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: Colors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Colors.white.withValues(alpha: 0.92),
                  const Color(0xFFEFF6FF).withValues(alpha: 0.88),
                  const Color(0xFFECFDF5).withValues(alpha: 0.84),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.75),
                width: 1.4,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            colors: <Color>[
                              AppColors.primary.withValues(alpha: 0.55),
                              AppColors.green.withValues(alpha: 0.55),
                            ],
                          ),
                        ),
                      ),
                    ),
                    AppSpacing.vGapMd,
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        final Animation<Offset> slide = Tween<Offset>(
                          begin: const Offset(0.08, 0),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: slide,
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<_NominationSheetStep>(_step),
                        child: isAuth
                            ? _buildAuthStep()
                            : _buildElectionTypeStep(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
            fontWeight: FontWeight.w600,
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
              color: Colors.white.withValues(alpha: 0.75),
              elevation: 2,
              shadowColor: AppColors.primary.withValues(alpha: 0.12),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _goToAuth,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  alignment: Alignment.center,
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
                      fontWeight: FontWeight.w600,
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

class _GlassCloseButton extends StatelessWidget {
  const _GlassCloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.95),
                    const Color(0xFFDBEAFE).withValues(alpha: 0.85),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                  width: 1.4,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.close_rounded,
                size: 20,
                color: AppColors.slate700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
