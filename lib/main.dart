import 'package:flutter/material.dart';

import 'app.dart';
import 'services/app_settings_controller.dart';
import 'services/startup_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StartupService.init();
  await appSettingsController.load();

  runApp(const GitHubWatcherApp());
}
