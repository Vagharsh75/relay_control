import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsService = SettingsService();
  await settingsService.init();
  runApp(LiftRestartApp(settingsService: settingsService));
}

class LiftRestartApp extends StatelessWidget {
  final SettingsService settingsService;

  const LiftRestartApp({super.key, required this.settingsService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Relay Control',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomeScreen(settingsService: settingsService),
    );
  }
}
