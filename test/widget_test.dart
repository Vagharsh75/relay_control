import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lift_restart/main.dart';
import 'package:lift_restart/services/settings_service.dart';

void main() {
  testWidgets('App renders home screen with command buttons', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final settingsService = SettingsService();
    await settingsService.init();

    await tester.pumpWidget(LiftRestartApp(settingsService: settingsService));

    expect(find.text('Relay Control'), findsOneWidget);
    expect(find.text('RESTART'), findsOneWidget);
    expect(find.text('STOP'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });
}
