import 'package:workmanager/workmanager.dart';

import '../utils/constants.dart';
import '../workers/background_worker.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class StartupService {
  static Future<void> init() async {
    try {
      await NotificationService.init();
      await Workmanager().initialize(
        callbackDispatcher,
      );

      // Daftarkan task hanya jika belum ada — tidak mereset countdown
      await _registerTask(
        defaultSyncIntervalMinutes,
        ExistingPeriodicWorkPolicy.keep,
      );

      final storage = StorageService();
      final currentNextSync = await storage.getNextSyncAt();
      if (currentNextSync == null || currentNextSync.isBefore(DateTime.now().subtract(const Duration(minutes: 5)))) {
        await storage.setNextSyncAt(
            DateTime.now().add(const Duration(minutes: defaultSyncIntervalMinutes)));
      }

      if (await NotificationService.launchedFromUpdateNotification()) {
        NotificationService.openUpdateScreen();
      }
    } catch (_) {
      // Startup must never block opening the app. Foreground sync still works.
    }
  }

  static Future<void> resetBackgroundSync(int intervalMinutes) async {
    try {
      await Workmanager().cancelByUniqueName(githubSyncTask);
      await Future.delayed(const Duration(milliseconds: 300));
      await _registerTask(intervalMinutes, ExistingPeriodicWorkPolicy.replace);
      
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
    ExistingPeriodicWorkPolicy policy,
  ) async {
    await Workmanager().registerPeriodicTask(
      githubSyncTask,
      githubSyncTask,
      frequency: Duration(minutes: intervalMinutes),
      flexInterval: Duration(
        minutes: (intervalMinutes * 0.25).round().clamp(5, 30),
      ),
      // Hanya wajibkan koneksi internet saja.
      // requiresBatteryNotLow & requiresStorageNotLow terlalu ketat
      // dan sering memblokir eksekusi di Android modern.
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: policy,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 5),
    );
  }
}
