import 'package:evm_management_system/shared/design_system/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('AppButton renders label and fires onPressed', (tester) async {
    int taps = 0;
    await tester.pumpWidget(
      host(AppButton(label: 'Sign In', onPressed: () => taps++)),
    );

    expect(find.text('Sign In'), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    expect(taps, 1);
  });

  testWidgets('AppButton shows loader and blocks taps when loading', (
    tester,
  ) async {
    int taps = 0;
    await tester.pumpWidget(
      host(
        AppButton(label: 'Sign In', isLoading: true, onPressed: () => taps++),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    expect(taps, 0);
  });
}
