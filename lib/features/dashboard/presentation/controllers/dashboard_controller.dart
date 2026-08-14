import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/constants/feature_flags.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/offline/web_form_submission.dart';
import 'package:evm_management_system/design_system/mpsec/mpsec_design_system.dart';
import 'package:evm_management_system/features/auth/domain/entities/auth_user.dart';
import 'package:evm_management_system/features/auth/presentation/controllers/auth_controller.dart';
import 'package:evm_management_system/features/dashboard/presentation/models/dashboard_models.dart';
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

  final Rx<DashboardCategory> activeCategory =
      DashboardCategory.voterServices.obs;

  List<DashboardService> get filteredServices => state.value.services
      .where((DashboardService s) => s.category == activeCategory.value)
      .toList(growable: false);

  void setCategory(DashboardCategory category) {
    if (activeCategory.value == category) return;
    activeCategory.value = category;
  }

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
    // EasyLocalization loads JSON async after first frame; wait until keys resolve
    // so we don't bake raw key strings into dashboard labels.
    for (int i = 0; i < 40; i++) {
      if (token != _rebuildToken || isClosed) return;
      if (LocaleKeys.dashboardGuest.tr() != LocaleKeys.dashboardGuest) break;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (token != _rebuildToken || isClosed) return;

    final String surveyWebUrl = AppServices.config.surveyWebBaseUrl;
    final String voterRegistrationUrl = AppServices.config.voterRegistrationUrl;
    final String expenditureUrl = AppServices.config.candidateExpenditureUrl;
    final String emsUrl = AppServices.config.emsUrl;
    final ServiceSession? session = AppServices.serviceAuth.session.value;
    final AuthUser? authUser = Get.isRegistered<AuthController>()
        ? AppServices.auth.authState.value.user
        : null;
    final bool isGuestAuth =
        authUser?.isGuest == true &&
        (session == null || session.name.trim().isEmpty);

    final List<WebFormSubmission> submissions =
        await AppServices.webSubmissionRepository.all();
    if (token != _rebuildToken || isClosed) return;

    final _SubmissionCounts counts = _countSubmissions(submissions);

    state.value = DashboardState(
      userName: _resolveUserName(
        session: session,
        authUser: authUser,
        isGuestAuth: isGuestAuth,
      ),
      designation: _resolveDesignation(
        session: session,
        authUser: authUser,
        isGuestAuth: isGuestAuth,
      ),
      district: _resolveDistrict(
        session: session,
        authUser: authUser,
        isGuestAuth: isGuestAuth,
      ),
      pendingCount: counts.pending + counts.failed,
      stats: _buildStats(submissions.length, counts),
      services: _buildServices(
        surveyWebUrl: surveyWebUrl,
        voterRegistrationUrl: voterRegistrationUrl,
        expenditureUrl: expenditureUrl,
        emsUrl: emsUrl,
      ),
      activity: _activityFromSubmissions(submissions),
    );
  }

  static _SubmissionCounts _countSubmissions(
    List<WebFormSubmission> submissions,
  ) {
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

    return _SubmissionCounts(
      synced: synced,
      pending: pending,
      failed: failed,
      todayCount: todayCount,
    );
  }

  static List<DashboardStat> _buildStats(
    int total,
    _SubmissionCounts counts,
  ) {
    return <DashboardStat>[
      DashboardStat(
        label: LocaleKeys.dashboardStatSurveysTotal.tr(),
        value: '$total',
        trend: '',
        icon: Icons.assignment_turned_in_outlined,
        color: AppColors.primary,
      ),
      DashboardStat(
        label: LocaleKeys.dashboardStatSurveysToday.tr(),
        value: '${counts.todayCount}',
        trend: '',
        icon: Icons.today_outlined,
        color: AppColors.green,
      ),
      DashboardStat(
        label: LocaleKeys.dashboardStatSurveysSynced.tr(),
        value: '${counts.synced}',
        trend: '',
        icon: Icons.cloud_done_outlined,
        color: AppColors.teal,
      ),
      DashboardStat(
        label: LocaleKeys.dashboardStatSurveysPending.tr(),
        value: '${counts.pending + counts.failed}',
        trend: '',
        icon: Icons.notifications_active_outlined,
        color: AppColors.warning,
      ),
    ];
  }

  static List<DashboardService> _buildServices({
    required String surveyWebUrl,
    required String voterRegistrationUrl,
    required String expenditureUrl,
    required String emsUrl,
  }) {
    return <DashboardService>[
      // Tab 1 — Voter Services
      DashboardService(
        title: LocaleKeys.serviceVoterRegistrationTitle.tr(),
        desc: '',
        icon: Icons.app_registration_rounded,
        color: AppColors.teal,
        url: voterRegistrationUrl,
        category: DashboardCategory.voterServices,
        requiresServiceLogin: false,
        passSessionContext: false,
        openAsExternalPortal: true,
      ),
      DashboardService(
        title: LocaleKeys.serviceVoterSearchEngineTitle.tr(),
        desc: '',
        icon: Icons.manage_search_outlined,
        color: AppColors.primary,
        url: '',
        category: DashboardCategory.voterServices,
        routeName: AppRoute.voterSearch.path,
        requiresServiceLogin: false,
      ),
      if (!kHideEms)
        DashboardService(
          title: LocaleKeys.serviceEmsTitle.tr(),
          desc: '',
          icon: Icons.dns_outlined,
          color: AppColors.primaryBright,
          url: emsUrl,
          category: DashboardCategory.voterServices,
          requiresServiceLogin: false,
          passSessionContext: false,
          openAsExternalPortal: true,
        ),
      // Tab 2 — About Elections
      if (!kHideOnlineNomination)
        DashboardService(
          title: LocaleKeys.serviceOnlineNominationTitle.tr(),
          desc: LocaleKeys.serviceOnlineNominationDesc.tr(),
          icon: Icons.how_to_reg_rounded,
          color: AppColors.green,
          url: '',
          category: DashboardCategory.aboutElections,
          routeName: AppRoute.onlineNominationHome.path,
          requiresServiceLogin: false,
        ),
      if (!kHideExpenditureAccount)
        DashboardService(
          title: LocaleKeys.serviceExpenditureTitle.tr(),
          desc: '',
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.saffron,
          url: expenditureUrl,
          category: DashboardCategory.aboutElections,
          requiresServiceLogin: true,
          passSessionContext: false,
          openAsExternalPortal: true,
          requiredLoginKind: ServiceLoginKind.survey,
        ),
      DashboardService(
        title: LocaleKeys.serviceBoothTitle.tr(),
        desc: '',
        icon: Icons.location_on_outlined,
        color: AppColors.primaryBright,
        url: surveyWebUrl,
        category: DashboardCategory.aboutElections,
        requiredLoginKind: ServiceLoginKind.survey,
      ),
      DashboardService(
        title: LocaleKeys.servicePresidingTitle.tr(),
        desc: LocaleKeys.servicePresidingDesc.tr(),
        icon: Icons.how_to_vote_rounded,
        color: MpSecTokens.softBlueDark,
        url: '',
        category: DashboardCategory.aboutElections,
        routeName: AppRoute.presidingDashboard.path,
        forceFreshLogin: false,
        requiredLoginKind: ServiceLoginKind.presiding,
      ),
    ];
  }

  static String _resolveUserName({
    required ServiceSession? session,
    required AuthUser? authUser,
    required bool isGuestAuth,
  }) {
    final String? sessionName = _trimmedOrNull(session?.name);
    if (sessionName != null) return sessionName;
    if (!isGuestAuth) {
      final String? fullName = _trimmedOrNull(authUser?.fullName);
      if (fullName != null) return fullName;
    }
    return LocaleKeys.dashboardGuest.tr();
  }

  static String _resolveDesignation({
    required ServiceSession? session,
    required AuthUser? authUser,
    required bool isGuestAuth,
  }) {
    final String? section = _trimmedOrNull(session?.section);
    if (section != null) return section;
    if (!isGuestAuth) {
      final String? designation = _trimmedOrNull(authUser?.designation);
      if (designation != null) return designation;
    }
    return LocaleKeys.dashboardRole.tr();
  }

  static String _resolveDistrict({
    required ServiceSession? session,
    required AuthUser? authUser,
    required bool isGuestAuth,
  }) {
    final String? districtName = _trimmedOrNull(session?.districtName);
    if (districtName != null) return districtName;
    final String? districtId = _trimmedOrNull(session?.districtId);
    if (districtId != null) return districtId;
    if (!isGuestAuth) {
      final String? districtCode = _trimmedOrNull(authUser?.districtCode);
      if (districtCode != null) return districtCode;
    }
    return LocaleKeys.dashboardDistrictUnset.tr();
  }

  static String? _trimmedOrNull(String? value) {
    if (value == null) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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

class _SubmissionCounts {
  const _SubmissionCounts({
    required this.synced,
    required this.pending,
    required this.failed,
    required this.todayCount,
  });

  final int synced;
  final int pending;
  final int failed;
  final int todayCount;
}
