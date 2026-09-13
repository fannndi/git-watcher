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

Future<void> registerExactAlarm() async {
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

  await AndroidAlarmManager.periodic(
    interval,
    alarmId,
    alarmCallback,
    startAt: DateTime.now().add(interval),
    exact: true,
    wakeup: true,
    rescheduleOnReboot: true,
  );

  await storage.setAlarmIntervalMinutes(intervalMinutes);
  await storage.setAlarmRegistered(true);
}
