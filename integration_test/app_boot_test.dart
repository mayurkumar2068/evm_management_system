import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/app.dart';
import 'package:evm_management_system/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'test_app_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// End-to-end smoke test: boots the app and asserts the guest dashboard renders.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots to dashboard as guest when onboarding complete', (
    tester,
  ) async {
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

    expect(find.byType(DashboardScreen), findsOneWidget);
  });
}
