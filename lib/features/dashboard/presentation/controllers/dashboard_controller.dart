import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/offline/web_form_submission.dart';
import 'package:evm_management_system/design_system/mpsec/mpsec_design_system.dart';
import 'package:evm_management_system/features/dashboard/presentation/models/dashboard_models.dart';
import 'package:evm_management_system/features/auth/domain/entities/auth_user.dart';
import 'package:evm_management_system/features/auth/presentation/controllers/auth_controller.dart';
import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:evm_management_system/shared/models/activity_event.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

class DashboardState {
  const DashboardState({
    required this.userName,
    required this.designation,
    required this.district,
    required this.pendingCount,
    required this.stats,
    required this.services,
    required this.activity,
  });

  final String userName;
  final String designation;
  final String district;

  /// Pending survey syncs / alerts badge count.
  final int pendingCount;
  final List<DashboardStat> stats;
  final List<DashboardService> services;
  final List<ActivityEvent> activity;
}

/// Builds dashboard view-model from session + local survey submissions.
class DashboardController extends GetxController {
  final Rx<DashboardState> state = const DashboardState(
    userName: '',
    designation: '',
    district: '',
    pendingCount: 0,
    stats: <DashboardStat>[],
    services: <DashboardService>[],
    activity: <ActivityEvent>[],
  ).obs;

  int _rebuildToken = 0;
  StreamSubscription<int>? _submissionWatch;

  @override
  void onInit() {
    super.onInit();
    ever(AppServices.activityLog.events, (_) => _rebuild());
    ever(AppServices.serviceAuth.session, (_) => _rebuild());
    if (Get.isRegistered<AuthController>()) {
      ever(AppServices.auth.authState, (_) => _rebuild());
    }
    ever(AppServices.settings.locale, (_) => _rebuild());
    _submissionWatch = AppServices.webSubmissionRepository
        .watchPendingCount()
        .listen((_) => _rebuild());
  }

  @override
  void onClose() {
    _submissionWatch?.cancel();
    super.onClose();
  }

  /// Rebuilds dashboard labels after EasyLocalization is available.
  void rebuildDashboard() => _rebuild();

  void _rebuild() {
    final int token = ++_rebuildToken;
    unawaited(_rebuildAsync(token));
  }

  Future<void> _rebuildAsync(int token) async {
    final String surveyWebUrl = AppServices.config.surveyWebBaseUrl;
    final String voterSearchUrl = AppServices.config.voterSearchEngineUrl;
    final String expenditureUrl = AppServices.config.candidateExpenditureUrl;
    final ServiceSession? session = AppServices.serviceAuth.session.value;

    final AuthUser? authUser = Get.isRegistered<AuthController>()
        ? AppServices.auth.authState.value.user
        : null;
    final bool isGuestAuth =
        authUser?.isGuest == true &&
        (session == null || session.name.trim().isEmpty);
    final String name = () {
      if (session != null && session.name.trim().isNotEmpty) {
        return session.name.trim();
      }
      if (isGuestAuth) return LocaleKeys.dashboardGuest.tr();
      if (authUser != null && authUser.fullName.trim().isNotEmpty) {
        return authUser.fullName.trim();
      }
      return LocaleKeys.dashboardGuest.tr();
    }();
    final String designation = () {
      if (session?.section != null && session!.section!.trim().isNotEmpty) {
        return session.section!.trim();
      }
      if (isGuestAuth) return LocaleKeys.dashboardRole.tr();
      if (authUser?.designation != null &&
          authUser!.designation!.trim().isNotEmpty) {
        return authUser.designation!.trim();
      }
      return LocaleKeys.dashboardRole.tr();
    }();
    final String district = () {
      if (session?.districtName != null &&
          session!.districtName!.trim().isNotEmpty) {
        return session.districtName!.trim();
      }
      if (session?.districtId != null &&
          session!.districtId!.trim().isNotEmpty) {
        return session.districtId!.trim();
      }
      if (isGuestAuth) return LocaleKeys.dashboardDistrictUnset.tr();
      if (authUser?.districtCode != null &&
          authUser!.districtCode!.trim().isNotEmpty) {
        return authUser.districtCode!.trim();
      }
      return LocaleKeys.dashboardDistrictUnset.tr();
    }();

    final List<WebFormSubmission> submissions =
        await AppServices.webSubmissionRepository.all();
    if (token != _rebuildToken || isClosed) return;

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    int synced = 0;
    int pending = 0;
    int failed = 0;
    int todayCount = 0;
    for (final WebFormSubmission s in submissions) {
      switch (s.status) {
        case WebSubmissionStatus.synced:
          synced++;
        case WebSubmissionStatus.pending:
        case WebSubmissionStatus.syncing:
          pending++;
        case WebSubmissionStatus.failed:
          failed++;
      }
      final DateTime created = DateTime(
        s.createdAt.year,
        s.createdAt.month,
        s.createdAt.day,
      );
      if (created == today) todayCount++;
    }

    final List<DashboardStat> stats = <DashboardStat>[
      DashboardStat(
        label: LocaleKeys.dashboardStatSurveysTotal.tr(),
        value: '${submissions.length}',
        trend: '',
        icon: Icons.assignment_turned_in_outlined,
        color: AppColors.primary,
      ),
      DashboardStat(
        label: LocaleKeys.dashboardStatSurveysToday.tr(),
        value: '$todayCount',
        trend: '',
        icon: Icons.today_outlined,
        color: AppColors.green,
      ),
      DashboardStat(
        label: LocaleKeys.dashboardStatSurveysSynced.tr(),
        value: '$synced',
        trend: '',
        icon: Icons.cloud_done_outlined,
        color: AppColors.teal,
      ),
      DashboardStat(
        label: LocaleKeys.dashboardStatSurveysPending.tr(),
        value: '${pending + failed}',
        trend: '',
        icon: Icons.notifications_active_outlined,
        color: AppColors.warning,
      ),
    ];

    final List<DashboardService> services = <DashboardService>[
      DashboardService(
        title: LocaleKeys.serviceVoterSearchEngineTitle.tr(),
        desc: LocaleKeys.serviceVoterSearchEngineDesc.tr(),
        icon: Icons.manage_search_outlined,
        color: AppColors.primary,
        url: voterSearchUrl,
        requiresServiceLogin: false,
        passSessionContext: false,
        openAsExternalPortal: true,
      ),
      DashboardService(
        title: LocaleKeys.serviceBoothTitle.tr(),
        desc: LocaleKeys.serviceBoothDesc.tr(),
        icon: Icons.location_on_outlined,
        color: AppColors.primaryBright,
        url: surveyWebUrl,
      ),
      DashboardService(
        title: LocaleKeys.servicePresidingTitle.tr(),
        desc: LocaleKeys.servicePresidingDesc.tr(),
        icon: Icons.how_to_vote_rounded,
        color: MpSecTokens.softBlueDark,
        url: '',
        routeName: AppRoute.presidingDashboard.path,
      ),
      DashboardService(
        title: LocaleKeys.serviceOnlineNominationTitle.tr(),
        desc: LocaleKeys.serviceOnlineNominationDesc.tr(),
        icon: Icons.how_to_reg_rounded,
        color: AppColors.green,
        url: '',
        routeName: AppRoute.onlineNominationHome.path,
        requiresServiceLogin: false,
      ),
      DashboardService(
        title: LocaleKeys.serviceExpenditureTitle.tr(),
        desc: LocaleKeys.serviceExpenditureDesc.tr(),
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.saffron,
        url: expenditureUrl,
        // Same officer login gate as booth survey; then open ASPX in WebView.
        requiresServiceLogin: true,
        passSessionContext: false,
        openAsExternalPortal: true,
      ),
    ];

    state.value = DashboardState(
      userName: name,
      designation: designation,
      district: district,
      pendingCount: pending + failed,
      stats: stats,
      services: services,
      activity: _activityFromSubmissions(submissions),
    );
  }

  /// Recent activity from locally tracked survey / web form submissions.
  static List<ActivityEvent> _activityFromSubmissions(
    List<WebFormSubmission> submissions,
  ) {
    final List<WebFormSubmission> sorted =
        List<WebFormSubmission>.from(submissions)
          ..sort(
            (WebFormSubmission a, WebFormSubmission b) =>
                b.createdAt.compareTo(a.createdAt),
          );

    return <ActivityEvent>[
      for (final WebFormSubmission s in sorted)
        ActivityEvent(
          id: s.clientId,
          type: _activityTypeFor(s.status),
          title: _activityTitleFor(s),
          deviceId: _formLabel(s.formType),
          officer: _officerLabel(s),
          timestamp: s.syncedAt ?? s.createdAt,
        ),
    ];
  }

  static ActivityType _activityTypeFor(WebSubmissionStatus status) =>
      switch (status) {
        WebSubmissionStatus.synced => ActivityType.sync,
        WebSubmissionStatus.failed => ActivityType.updated,
        WebSubmissionStatus.pending ||
        WebSubmissionStatus.syncing => ActivityType.registered,
      };

  static String _activityTitleFor(WebFormSubmission s) {
    final String form = _formLabel(s.formType);
    return switch (s.status) {
      WebSubmissionStatus.synced => LocaleKeys.dashboardActSurveySynced.tr(
        args: <String>[form],
      ),
      WebSubmissionStatus.failed => LocaleKeys.dashboardActSurveyFailed.tr(
        args: <String>[form],
      ),
      WebSubmissionStatus.pending || WebSubmissionStatus.syncing =>
        LocaleKeys.dashboardActSurveySubmitted.tr(args: <String>[form]),
    };
  }

  static String _formLabel(String formType) {
    final String trimmed = formType.trim();
    if (trimmed.isEmpty) return LocaleKeys.dashboardActSurveyDefault.tr();
    return trimmed;
  }

  static String _officerLabel(WebFormSubmission s) {
    final Object? by = s.payload['submittedBy'];
    if (by != null && by.toString().trim().isNotEmpty) {
      return by.toString().trim();
    }
    return switch (s.status) {
      WebSubmissionStatus.synced => LocaleKeys.dashboardStatSurveysSynced.tr(),
      WebSubmissionStatus.failed => LocaleKeys.statsFailed.tr(),
      WebSubmissionStatus.pending || WebSubmissionStatus.syncing =>
        LocaleKeys.dashboardStatSurveysPending.tr(),
    };
  }
}
