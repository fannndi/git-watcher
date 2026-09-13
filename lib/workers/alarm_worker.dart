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
  if (await storage.isAlarmRegistered()) {
    return;
  }

  await AndroidAlarmManager.periodic(
    alarmInterval,
    alarmId,
    alarmCallback,
    startAt: DateTime.now().add(alarmInitialDelay),
    exact: true,
    wakeup: true,
    rescheduleOnReboot: true,
  );

  await storage.setAlarmRegistered(true);
}
