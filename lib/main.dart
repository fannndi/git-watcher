import 'package:flutter/material.dart';

import 'app.dart';
import 'services/app_settings_controller.dart';
import 'services/startup_service.dart';
import 'services/storage_service.dart';

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

  // Parallel initialization
  await Future.wait([
    _bootstrap(),
    _preloadData(),
  ]);

  stopwatch.stop();
  debugPrint('Startup completed in ${stopwatch.elapsedMilliseconds}ms');

  runApp(const GitHubWatcherApp());
}

Future<void> _preloadData() async {
  // Preload frequently accessed data
  final storage = StorageService();
  await storage.getAppSettings();
  await storage.getCredentials();
}

Future<void> _bootstrap() async {
  try {
    await appSettingsController.load();
  } catch (_) {
    // Default settings are enough to open the app if local storage is unavailable.
  }

  await StartupService.init();
}
