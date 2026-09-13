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
    final storage = StorageService();
    final settings = await storage.getAppSettings();
    final now = DateTime.now();

    if (settings.isQuietHour(now)) {
      return;
    }

    final level = await storage.getSyncBackoffLevel();
    final effectiveInterval = Duration(
      minutes: settings.effectiveSyncIntervalMinutes(level),
    );
    final lastSyncAt = await storage.getLastSyncAt();
    if (lastSyncAt != null && now.difference(lastSyncAt) < effectiveInterval) {
      return;
    }

    final notificationActive =
        await NotificationService.hasActiveUpdateNotification();
    final morningDigest = settings.quietHoursEnabled &&
        now.hour >= settings.quietEndHour &&
        now.hour < settings.quietEndHour + 3 &&
        await storage.getMorningDigestDate() != _dateKey(now);

    await NotificationService.init(isBackground: true);
    await SyncService.checkUpdates(
      isBackground: true,
      morningDigest: morningDigest,
    ).timeout(backgroundSyncTimeout);

    final nextLevel = notificationActive ? level + 1 : 0;
    await storage.setSyncBackoffLevel(nextLevel);
  } catch (e) {
    debugPrint('alarmCallback failed: $e');
  }
}

String _dateKey(DateTime time) => '${time.year}-${time.month}-${time.day}';

Future<void> registerSyncAlarm() async {
  final storage = StorageService();
  final settings = await storage.getAppSettings();
  final intervalMinutes = settings.syncIntervalMinutes;
  final precise = settings.preciseSync;
  final registered = await storage.isAlarmRegistered();
  final currentInterval = await storage.getAlarmIntervalMinutes();
  final currentPrecise = await storage.isAlarmPrecise();

  if (registered &&
      currentInterval == intervalMinutes &&
      currentPrecise == precise) {
    return;
  }

  if (registered) {
    await AndroidAlarmManager.cancel(alarmId);
  }

  final interval = Duration(minutes: intervalMinutes);
  final startAt = DateTime.now().add(interval);

  var scheduled = false;
  if (precise) {
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
    await storage.setAlarmPrecise(precise);
    await storage.setAlarmRegistered(true);
  }
}
