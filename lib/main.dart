import 'dart:ui';

import 'package:flutter/material.dart';

import 'app.dart';
import 'services/app_settings_controller.dart';
import 'services/startup_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}\n${details.stack}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformError: $error\n$stack');
    return true;
  };

  try {
    await appSettingsController.load();
  } catch (e) {
    debugPrint('Settings load failed, using defaults: $e');
  }

  await StartupService.init();

  runApp(const GitHubWatcherApp());
}
