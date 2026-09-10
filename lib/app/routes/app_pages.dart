import 'package:evm_management_system/app/app_splash_screen.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/app/router/app_shell.dart';
import 'package:evm_management_system/app/routes/auth_middleware.dart';
import 'package:evm_management_system/features/auth/presentation/screens/login_screen.dart';
import 'package:evm_management_system/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:evm_management_system/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:evm_management_system/features/offline/presentation/screens/offline_screen.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/screens/presiding_dashboard_screen.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/screens/presiding_live_poll_screen.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/screens/presiding_party_details_screen.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/screens/presiding_party_otp_screen.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/screens/presiding_po_details_screen.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/screens/presiding_turnout_screen.dart';
import 'package:evm_management_system/features/profile/presentation/screens/profile_screen.dart';
import 'package:evm_management_system/features/service_auth/presentation/models/service_login_args.dart';
import 'package:evm_management_system/features/service_auth/presentation/screens/service_login_screen.dart';
import 'package:evm_management_system/features/voter_search/presentation/screens/voter_search_screen.dart';
import 'package:evm_management_system/features/web_portal/presentation/screens/offline_fallback_screen.dart';
import 'package:evm_management_system/features/web_portal/presentation/screens/web_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

Widget _shell(Widget child) => AppShell(child: child);

abstract final class AppPages {
  static final String initial = AppRoute.splash.path;

  static final List<GetPage<dynamic>> routes = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: AppRoute.splash.path,
      page: () => const AppSplashScreen(),
    ),
    GetPage<dynamic>(
      name: AppRoute.login.path,
      page: () => const LoginScreen(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.serviceLogin.path,
      page: () {
        final ServiceLoginArgs args = ServiceLoginArgs.from(Get.arguments);
        return ServiceLoginScreen(
          serviceTitle: args.serviceTitle,
          loginKind: args.loginKind,
          registrationAllowed: args.registrationAllowed,
        );
      },
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
      name: AppRoute.presidingPoDetails.path,
      page: () => const PresidingPoDetailsScreen(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.presidingPartyDetails.path,
      page: () => const PresidingPartyDetailsScreen(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.presidingPartyOtp.path,
      page: () => const PresidingPartyOtpScreen(),
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
      name: AppRoute.voterSearch.path,
      page: () => const VoterSearchScreen(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoute.dashboard.path,
      page: () => _shell(const DashboardScreen()),
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
  ];
}
