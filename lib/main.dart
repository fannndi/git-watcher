import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'services/app_settings_controller.dart';
import 'services/startup_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const GitHubWatcherApp());

  unawaited(_bootstrap());
}

Future<void> _bootstrap() async {
  try {
    await appSettingsController.load();
  } catch (_) {
    // Default settings are enough to open the app if local storage is unavailable.
  }

  await StartupService.init();
}
