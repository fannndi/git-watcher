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

      final storage = StorageService();
      final settings = await storage.getAppSettings();

      // Gunakan interval dari settings, bukan default
      await _registerTask(
        settings.syncIntervalMinutes,
        ExistingWorkPolicy.keep,
      );

      final currentNextSync = await storage.getNextSyncAt();
      final now = DateTime.now();
      
      // Jika nextSync belum ada atau sudah lewat (missed), 
      // set ke 'sekarang' agar HomeScreen bisa mentrigger sync pada saat build selesai.
      if (currentNextSync == null || currentNextSync.isBefore(now.subtract(const Duration(minutes: 1)))) {
        await storage.setNextSyncAt(now);
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
