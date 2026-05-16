import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../utils/constants.dart';
import '../workers/background_worker.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class StartupService {
  static Future<void> init() async {
    try {
      // 1. Initialize Workmanager FIRST as it is critical for background sync
      try {
        await Workmanager().initialize(
          callbackDispatcher,
        );
      } catch (e) {
        debugPrint('StartupService: Workmanager init failed: $e');
      }

      // 2. Initialize Notification independently
      try {
        await NotificationService.init();
      } catch (e) {
        debugPrint('StartupService: Notification init failed: $e');
      }

      final storage = StorageService();
      final settings = await storage.getAppSettings();

      final currentNextSync = await storage.getNextSyncAt();
      final now = DateTime.now();

      // Jika nextSync belum ada atau sudah lewat (missed),
      // segera jadwalkan task dalam 1 menit agar user melihat hasil secepatnya.
      if (currentNextSync == null || currentNextSync.isBefore(now)) {
        await storage.setNextSyncAt(now);
        await _registerTask(
          1, // Jadwalkan dalam 1 menit
          ExistingWorkPolicy.replace,
        );
      } else {
        // Tetap pastikan task terdaftar dengan sisa waktu yang ada
        final remainingMinutes = currentNextSync.difference(now).inMinutes;
        await _registerTask(
          remainingMinutes.clamp(0, settings.syncIntervalMinutes),
          ExistingWorkPolicy.keep,
        );
      }

      if (await NotificationService.launchedFromUpdateNotification()) {
        NotificationService.openUpdateScreen();
      }
    } catch (e) {
      debugPrint('StartupService critical error: $e');
      // Startup must never block opening the app.
    }
  }

  static Future<void> resetBackgroundSync(int intervalMinutes) async {
    try {
      await Workmanager().cancelByUniqueName(githubSyncTask);
      await Future.delayed(const Duration(milliseconds: 300));
      await _registerTask(intervalMinutes, ExistingWorkPolicy.replace);
      
      final storage = StorageService();
      await storage.setNextSyncAt(
          DateTime.now().add(Duration(minutes: intervalMinutes)));
    } catch (_) {}
  }

  static Future<void> startDemoSync() async {
    try {
      await Workmanager().cancelByUniqueName(githubSyncTask);
      await Future.delayed(const Duration(milliseconds: 300));
      await Workmanager().registerOneOffTask(
        githubSyncTask, // reuse same unique name
        githubSyncTask, // taskName
        initialDelay: const Duration(minutes: 5),
        constraints: Constraints(networkType: NetworkType.connected),
        inputData: {'isDemo': true},
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 5),
      );
      
      final storage = StorageService();
      await storage.setNextSyncAt(
          DateTime.now().add(const Duration(minutes: 5)));
    } catch (_) {}
  }

  static Future<void> _registerTask(
    int intervalMinutes,
    ExistingWorkPolicy policy,
  ) async {
    await Workmanager().registerOneOffTask(
      githubSyncTask,
      githubSyncTask,
      initialDelay: Duration(minutes: intervalMinutes),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: policy,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 5),
    );
  }
}
