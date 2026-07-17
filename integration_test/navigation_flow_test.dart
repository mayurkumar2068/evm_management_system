import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/app.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/features/audit_trail/presentation/screens/audit_trail_screen.dart';
import 'package:evm_management_system/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:evm_management_system/features/device_detail/presentation/screens/device_detail_screen.dart';
import 'package:evm_management_system/features/settings/presentation/screens/settings_screen.dart';
import 'test_app_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';

/// Regression coverage for navigation stacking with GetX routes.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Boots the real app as an authenticated guest and waits out the splash.
  Future<void> pumpToDashboard(WidgetTester tester) async {
    await pumpEvmAppForTest(onboardingSeen: true);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[Locale('en'), Locale('hi')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const EvmApp(),
      ),
    );

    await tester.pump();
    await Future<void>.delayed(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(
      find.byType(DashboardScreen),
      findsOneWidget,
      reason: 'guest session should land on the dashboard',
    );
  }

  testWidgets('device detail: push -> back -> push again does not crash', (
    tester,
  ) async {
    await pumpToDashboard(tester);

    await Get.toNamed<dynamic>(AppRoute.deviceDetail.path, arguments: 'EVM-CU-1001');
    await tester.pumpAndSettle();
    expect(find.byType(DeviceDetailScreen), findsOneWidget);

    Get.back<void>();
    await tester.pumpAndSettle();
    expect(find.byType(DeviceDetailScreen), findsNothing);
    expect(find.byType(DashboardScreen), findsOneWidget);

    await Get.toNamed<dynamic>(AppRoute.deviceDetail.path, arguments: 'EVM-CU-2002');
    await tester.pumpAndSettle();
    expect(find.byType(DeviceDetailScreen), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('stacking settings -> audit -> settings does not crash', (
    tester,
  ) async {
    await pumpToDashboard(tester);

    await Get.toNamed<dynamic>(AppRoute.settings.path);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    await Get.toNamed<dynamic>(AppRoute.auditTrail.path);
    await tester.pumpAndSettle();
    expect(find.byType(AuditTrailScreen), findsOneWidget);

    await Get.toNamed<dynamic>(AppRoute.settings.path);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    expect(tester.takeException(), isNull);

    Get.back<void>();
    Get.back<void>();
    Get.back<void>();
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);
  });
}
