import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';

import '../workers/alarm_worker.dart';
import 'notification_service.dart';

class StartupService {
  static Future<void> init() async {
    try {
      await NotificationService.init();
    } catch (e) {
      debugPrint('StartupService: notification init failed: $e');
    }

    try {
      await AndroidAlarmManager.initialize();
      await registerSyncAlarm();
    } catch (e) {
      debugPrint('StartupService: alarm init failed: $e');
    }
  }

  static Future<void> applySyncInterval() async {
    try {
      await registerSyncAlarm();
    } catch (e) {
      debugPrint('StartupService: alarm reschedule failed: $e');
    }
  }

  static Future<void> requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) {
      return;
    }

    const intent = AndroidIntent(
      action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
    );
    try {
      await intent.launch();
    } catch (e) {
      debugPrint('StartupService: could not open battery settings: $e');
    }
  }
}
