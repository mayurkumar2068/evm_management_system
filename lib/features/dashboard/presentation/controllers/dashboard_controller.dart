import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/constants/app_urls.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/design_system/mpsec/mpsec_design_system.dart';
import 'package:evm_management_system/features/dashboard/presentation/models/dashboard_models.dart';
import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:evm_management_system/shared/controllers/device_records_controller.dart';
import 'package:evm_management_system/shared/models/activity_event.dart';
import 'package:evm_management_system/shared/models/device_record.dart';
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
  final int pendingCount;
  final List<DashboardStat> stats;
  final List<DashboardService> services;
  final List<ActivityEvent> activity;
}

/// Builds dashboard view-model from shared GetX controllers.
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

  @override
  void onInit() {
    super.onInit();
    ever(AppServices.deviceRecords.records, (_) => _rebuild());
    ever(AppServices.activityLog.events, (_) => _rebuild());
    ever(AppServices.serviceAuth.session, (_) => _rebuild());
    ever(AppServices.settings.locale, (_) => _rebuild());
  }

  /// Rebuilds dashboard labels after EasyLocalization is available.
  void rebuildDashboard() => _rebuild();

  void _rebuild() {
    final List<DeviceRecord> all = AppServices.deviceRecords.records;
    final DeviceRecordsController store = AppServices.deviceRecords;
    final List<ActivityEvent> activity = AppServices.activityLog.events;
    final String surveyWebUrl = AppServices.config.surveyWebBaseUrl;
    final ServiceSession? session = AppServices.serviceAuth.session.value;

    final String name =
        (session != null &&
            session.districtName != null &&
            session.districtName!.isNotEmpty)
        ? session.districtName!
        : LocaleKeys.dashboardGuest.tr();
    final String designation = LocaleKeys.dashboardRole.tr();
    final String district =
        (session != null &&
            session.districtId != null &&
            session.districtId!.isNotEmpty)
        ? session.districtId!
        : LocaleKeys.dashboardDistrictUnset.tr();

    final DeviceStats bu = store.statsFor(DeviceKind.ballotUnit);
    final DeviceStats total = store.statsFor(null);
    final int boxes = all
        .map((DeviceRecord r) => r.box)
        .where((String b) => b != 'Unassigned')
        .toSet()
        .length;

    final List<DashboardStat> stats = <DashboardStat>[
      DashboardStat(
        label: LocaleKeys.dashboardStatObservers.tr(),
        value: '${total.total}',
        trend: '+12%',
        icon: Icons.groups_2_outlined,
        color: const Color(0xFF0F8A5F),
      ),
      DashboardStat(
        label: LocaleKeys.dashboardStatExpenditure.tr(),
        value: '${bu.registered}',
        trend: '+8%',
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFFFF8C00),
      ),
      DashboardStat(
        label: LocaleKeys.dashboardStatInspections.tr(),
        value: '$boxes',
        trend: '+5%',
        icon: Icons.fact_check_outlined,
        color: AppColors.primary,
      ),
      DashboardStat(
        label: LocaleKeys.dashboardStatEms.tr(),
        value: '${total.registered}',
        trend: '+15%',
        icon: Icons.assessment_outlined,
        color: AppColors.teal,
      ),
    ];

    final List<DashboardService> services = <DashboardService>[
      DashboardService(
        title: LocaleKeys.serviceVoterSearchEngineTitle.tr(),
        desc: LocaleKeys.serviceVoterSearchEngineDesc.tr(),
        icon: Icons.manage_search_outlined,
        color: AppColors.primary,
        url: AppUrls.mpSecVoterSearchEngine,
        requiresServiceLogin: false,
      ),
      DashboardService(
        title: LocaleKeys.serviceBoothTitle.tr(),
        desc: LocaleKeys.serviceBoothDesc.tr(),
        icon: Icons.location_on_outlined,
        color: AppColors.purple,
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
    ];

    state.value = DashboardState(
      userName: name,
      designation: designation,
      district: district,
      pendingCount: total.pending,
      stats: stats,
      services: services,
      activity: activity,
    );
  }
}
