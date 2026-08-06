import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'services/app_settings_controller.dart';
import 'services/startup_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up error handling
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // Set up platform error handling
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform error: $error');
    debugPrint('Stack trace: $stack');
    return true;
  };

  // Performance monitoring
  final stopwatch = Stopwatch()..start();

  runApp(const GitHubWatcherApp());

  unawaited(_bootstrap());

  stopwatch.stop();
  debugPrint('Bootstrap completed in ${stopwatch.elapsedMilliseconds}ms');
}

Future<void> _bootstrap() async {
  try {
    await appSettingsController.load();
  } catch (_) {
    // Default settings are enough to open the app if local storage is unavailable.
  }

  await StartupService.init();
}
