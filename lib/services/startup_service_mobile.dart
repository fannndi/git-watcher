import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../utils/constants.dart';
import '../workers/background_worker.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class StartupService {
  static Future<void> init() async {
    try {
      // 1. Initialize Workmanager FIRST — critical for background sync
      try {
        await Workmanager().initialize(
          callbackDispatcher,
        );
      } catch (e) {
        debugPrint('StartupService: Workmanager init failed: $e');
      }

      // 2. Initialize Notifications independently
      try {
        await NotificationService.init();
      } catch (e) {
        debugPrint('StartupService: Notification init failed: $e');
      }

      // 3. Schedule periodic sync task (idempotent: safe to call every startup)
      final storage = StorageService();
      final settings = await storage.getAppSettings();
      await _registerPeriodicTask(settings.syncIntervalMinutes);

      // 4. Handle notification-launched state
      if (await NotificationService.launchedFromUpdateNotification()) {
        NotificationService.openUpdateScreen();
      }
    } catch (e) {
      debugPrint('StartupService critical error: $e');
      // Startup must never block the app from opening.
    }
  }

  /// Re-register the periodic sync task with a new interval.
  /// Called when the user changes the sync interval in Settings.
  static Future<void> resetBackgroundSync(int intervalMinutes) async {
    try {
      // Cancel existing and re-register with new interval.
      await Workmanager().cancelByUniqueName(githubSyncTask);
      await Future.delayed(const Duration(milliseconds: 300));
      await _registerPeriodicTask(intervalMinutes);

      final storage = StorageService();
      await storage.setNextSyncAt(
          DateTime.now().add(Duration(minutes: intervalMinutes)));
    } catch (e) {
      debugPrint('StartupService: resetBackgroundSync failed: $e');
    }
  }

  /// Request Android to exclude this app from battery optimization.
  /// This is the #1 most important step for reliable background sync.
  /// Should be called once from the UI (e.g., on first launch or from a prompt).
  static Future<void> requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) return;
    try {
      final intent = AndroidIntent(
        action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
        data: 'package:com.ti24a4.app32',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    } catch (e) {
      debugPrint('StartupService: Could not open battery settings: $e');
    }
  }

  static Future<void> _registerPeriodicTask(int intervalMinutes) async {
    // WorkManager enforces a minimum of 15 minutes for periodic tasks on Android.
    final effectiveInterval = intervalMinutes.clamp(15, 24 * 60);

    await Workmanager().registerPeriodicTask(
      githubSyncTask,
      githubSyncTask,
      frequency: Duration(minutes: effectiveInterval),
      // initialDelay ensures first run doesn't compete with app startup sync
      initialDelay: const Duration(minutes: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 5),
    );
    debugPrint('StartupService: Periodic task registered (interval: ${effectiveInterval}min)');
  }
}
