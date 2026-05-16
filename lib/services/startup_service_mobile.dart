import 'package:android_intent_plus/android_intent.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

import '../workers/alarm_worker.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class StartupService {
  static Future<void> init() async {
    try {
      // 1. Initialize Notifications
      try {
        await NotificationService.init();
      } catch (e) {
        debugPrint('StartupService: Notification init failed: $e');
      }

      // 2. Initialize AndroidAlarmManager
      try {
        await AndroidAlarmManager.initialize();
      } catch (e) {
        debugPrint('StartupService: AlarmManager init failed: $e');
      }

      // 3. Register exact periodic alarm (60 menit, presisi)
      //    ExistingPeriodicWorkPolicy.keep: tidak reset jika sudah terdaftar
      await registerExactAlarm();

      // 4. Note: WorkManager is removed to avoid redundancy with AlarmManager.

      // 5. Set status awal jika belum ada
      final storage = StorageService();
      final existingStatus = await storage.getLastBackgroundSyncStatus();
      if (existingStatus == null || existingStatus.isEmpty) {
        await storage.setLastBackgroundSyncStatus(
            'Scheduled — waiting for first run');
      }

      // 6. Handle notification-launched state
      if (await NotificationService.launchedFromUpdateNotification()) {
        NotificationService.openUpdateScreen();
      }
    } catch (e) {
      debugPrint('StartupService critical error: $e');
    }
  }

  static Future<void> requestBatteryOptimizationExemption() async {
    if (Platform.isAndroid) {
      const intent = AndroidIntent(
        action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
      );
      try {
        await intent.launch();
      } catch (e) {
        debugPrint('StartupService: Could not launch battery settings: $e');
      }
    }
  }
}
