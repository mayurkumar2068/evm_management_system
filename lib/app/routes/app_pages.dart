import 'package:evm_management_system/app/app_splash_screen.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/app/router/app_shell.dart';
import 'package:evm_management_system/app/routes/auth_middleware.dart';
import 'package:evm_management_system/features/about/presentation/screens/about_screen.dart';
import 'package:evm_management_system/features/audit_trail/presentation/screens/audit_trail_screen.dart';
import 'package:evm_management_system/features/auth/presentation/screens/login_screen.dart';
import 'package:evm_management_system/features/ballot_unit/presentation/screens/ballot_unit_screen.dart';
import 'package:evm_management_system/features/control_unit/presentation/screens/control_unit_screen.dart';
import 'package:evm_management_system/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:evm_management_system/features/dashboard/presentation/widgets/dashboard_view_all.dart';
import 'package:evm_management_system/features/device_detail/presentation/screens/device_detail_screen.dart';
import 'package:evm_management_system/features/help_support/presentation/screens/help_support_screen.dart';
import 'package:evm_management_system/features/master_stock_register/presentation/screens/master_stock_register_screen.dart';
import 'package:evm_management_system/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:evm_management_system/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:evm_management_system/features/offline/presentation/screens/offline_screen.dart';
import 'package:evm_management_system/features/online_nomination/presentation/models/nomination_models.dart';
import 'package:evm_management_system/features/online_nomination/presentation/screens/nomination_receipt_screen.dart';
import 'package:evm_management_system/features/online_nomination/presentation/screens/nomination_success_screen.dart';
import 'package:evm_management_system/features/online_nomination/presentation/screens/nomination_track_status_screen.dart';
import 'package:evm_management_system/features/online_nomination/presentation/screens/nomination_workflow_screen.dart';
import 'package:evm_management_system/features/online_nomination/presentation/screens/online_nomination_home_screen.dart';
import 'package:evm_management_system/features/online_nomination/presentation/screens/panchayat_nomination_selection_screen.dart';
import 'package:evm_management_system/features/online_nomination/presentation/screens/urban_nomination_selection_screen.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/screens/presiding_dashboard_screen.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/screens/presiding_live_poll_screen.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/screens/presiding_turnout_screen.dart';
import 'package:evm_management_system/features/profile/presentation/screens/profile_screen.dart';
import 'package:evm_management_system/features/reports/presentation/screens/reports_screen.dart';
import 'package:evm_management_system/features/scanner/presentation/screens/scanner_screen.dart';
import 'package:evm_management_system/features/search/presentation/screens/search_screen.dart';
import 'package:evm_management_system/features/service_auth/presentation/screens/service_login_screen.dart';
import 'package:evm_management_system/features/settings/presentation/screens/settings_screen.dart';
import 'package:evm_management_system/features/sync_management/presentation/screens/sync_management_screen.dart';
import 'package:evm_management_system/features/web_portal/presentation/screens/offline_fallback_screen.dart';
import 'package:evm_management_system/features/web_portal/presentation/screens/web_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Wraps authenticated shell routes with the persistent bottom navigation.
Widget _shell(Widget child) => AppShell(child: child);

/// Central GetX route table (replaces GoRouter).
abstract final class AppPages {
  static final String initial = AppRoute.splash.path;

  static final List<GetPage<dynamic>> routes = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: AppRoute.splash.path,
      page: () => const AppSplashScreen(),
    ),
    GetPage<dynamic>(
      name: AppRoute.onboarding.path,
      page: () => const OnboardingScreen(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.login.path,
      page: () => const LoginScreen(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.serviceLogin.path,
      page: () => ServiceLoginScreen(
        serviceTitle: Get.arguments is String ? Get.arguments as String : null,
      ),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.scanner.path,
      page: () => const ScannerScreen(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.search.path,
      page: () => const SearchScreen(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.webView.path,
      page: () {
        final Object? args = Get.arguments;
        final WebViewArgs resolved = args is WebViewArgs
            ? args
            : const WebViewArgs(title: 'Web', url: 'https://www.eci.gov.in');
        return WebViewScreen(args: resolved);
      },
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.offlineFallback.path,
      page: () => OfflineFallbackScreen(
        title: Get.arguments is String
            ? Get.arguments as String
            : 'Offline Form',
      ),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.offlineHub.path,
      page: () => const OfflineScreen(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.presidingDashboard.path,
      page: () => const PresidingDashboardScreen(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.presidingTurnout.path,
      page: () => const PresidingTurnoutScreen(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.presidingLivePoll.path,
      page: () => const PresidingLivePollScreen(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.onlineNominationHome.path,
      page: () => const OnlineNominationHomeScreen(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.urbanNominationSelection.path,
      page: () => const UrbanNominationSelectionScreen(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.panchayatNominationSelection.path,
      page: () => const PanchayatNominationSelectionScreen(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.nominationWorkflow.path,
      page: () {
        final Object? args = Get.arguments;
        final NominationFlowArgs resolved = args is NominationFlowArgs
            ? args
            : const NominationFlowArgs(
                electionType: NominationElectionType.urban,
                postType: NominationPostType.mahapaur,
              );
        return NominationWorkflowScreen(args: resolved);
      },
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.nominationSuccess.path,
      page: () {
        final Object? args = Get.arguments;
        final NominationFlowArgs resolved = args is NominationFlowArgs
            ? args
            : const NominationFlowArgs(
                electionType: NominationElectionType.urban,
                postType: NominationPostType.mahapaur,
              );
        return NominationSuccessScreen(args: resolved);
      },
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.nominationReceipt.path,
      page: () {
        final Object? args = Get.arguments;
        final NominationFlowArgs resolved = args is NominationFlowArgs
            ? args
            : const NominationFlowArgs(
                electionType: NominationElectionType.urban,
                postType: NominationPostType.mahapaur,
              );
        return NominationReceiptScreen(args: resolved);
      },
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.nominationTrackStatus.path,
      page: () {
        final Object? args = Get.arguments;
        final NominationFlowArgs resolved = args is NominationFlowArgs
            ? args
            : const NominationFlowArgs(
                electionType: NominationElectionType.urban,
                postType: NominationPostType.mahapaur,
              );
        return NominationTrackStatusScreen(args: resolved);
      },
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.controlUnit.path,
      page: () => const ControlUnitScreen(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.ballotUnit.path,
      page: () => const BallotUnitScreen(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.dashboard.path,
      page: () => _shell(const DashboardScreen()),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.activityHistory.path,
      page: () => _shell(const DashboardViewAllScreen()),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.masterStockRegister.path,
      page: () => _shell(const MasterStockRegisterScreen()),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.reports.path,
      page: () => _shell(const ReportsScreen()),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.profile.path,
      page: () => _shell(const ProfileScreen()),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.notifications.path,
      page: () => _shell(const NotificationsScreen()),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.deviceDetail.path,
      page: () => _shell(
        DeviceDetailScreen(
          deviceId: Get.arguments is String ? Get.arguments as String : null,
        ),
      ),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.auditTrail.path,
      page: () => _shell(const AuditTrailScreen()),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.syncManagement.path,
      page: () => _shell(const SyncManagementScreen()),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.settings.path,
      page: () => _shell(const SettingsScreen()),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.help.path,
      page: () => _shell(const HelpSupportScreen()),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.about.path,
      page: () => _shell(const AboutScreen()),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
  ];
}
