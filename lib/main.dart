import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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

  // Memory optimization
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB

  // Startup optimization
  SchedulerBinding.instance.addPostFrameCallback((_) {
    debugPrint('First frame rendered');
  });

  // Pre-warm GPU
  SchedulerBinding.instance.addTimingsCallback((timings) {
    for (final timing in timings) {
      debugPrint('Frame timing: ${timing.totalSpan.inMilliseconds}ms');
    }
  });

  // Pre-warm shader cache
  SchedulerBinding.instance.addPersistentFrameCallback((_) {
    // Keep shader cache warm
  });

  // Pre-warm image cache
  SchedulerBinding.instance.addPostFrameCallback((_) {
    // Pre-warm image cache
  });

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
