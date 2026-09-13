import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/widgets.dart';

import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../utils/constants.dart';

@pragma('vm:entry-point')
Future<void> alarmCallback() async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await NotificationService.init(isBackground: true);
    await SyncService.checkUpdates(isBackground: true)
        .timeout(backgroundSyncTimeout);
  } catch (e) {
    debugPrint('alarmCallback failed: $e');
  }
}

Future<void> registerSyncAlarm() async {
  final storage = StorageService();
  final settings = await storage.getAppSettings();
  final intervalMinutes = settings.syncIntervalMinutes;
  final registered = await storage.isAlarmRegistered();
  final currentInterval = await storage.getAlarmIntervalMinutes();

  if (registered && currentInterval == intervalMinutes) {
    return;
  }

  if (registered) {
    await AndroidAlarmManager.cancel(alarmId);
  }

  final interval = Duration(minutes: intervalMinutes);
  final startAt = DateTime.now().add(interval);

  var scheduled = false;
  try {
    scheduled = await AndroidAlarmManager.periodic(
      interval,
      alarmId,
      alarmCallback,
      startAt: startAt,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
  } catch (e) {
    debugPrint('registerSyncAlarm: exact alarm unavailable: $e');
  }

  if (!scheduled) {
    scheduled = await AndroidAlarmManager.periodic(
      interval,
      alarmId,
      alarmCallback,
      startAt: startAt,
      exact: false,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
  }

  if (scheduled) {
    await storage.setAlarmIntervalMinutes(intervalMinutes);
    await storage.setAlarmRegistered(true);
  }
}
