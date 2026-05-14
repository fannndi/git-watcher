import 'package:workmanager/workmanager.dart';

import '../utils/constants.dart';
import '../workers/background_worker.dart';
import 'notification_service.dart';

class StartupService {
  static Future<void> init() async {
    try {
      await NotificationService.init();
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );

      // Daftarkan task hanya jika belum ada — tidak mereset countdown
      await _registerTask(
        defaultSyncIntervalMinutes,
        ExistingPeriodicWorkPolicy.keep,
      );

      if (await NotificationService.launchedFromUpdateNotification()) {
        NotificationService.openUpdateScreen();
      }
    } catch (_) {
      // Startup must never block opening the app. Foreground sync still works.
    }
  }

  /// Cancel task lama dan daftarkan ulang — countdown dimulai dari sekarang.
  static Future<void> resetBackgroundSync(int intervalMinutes) async {
    try {
      await Workmanager().cancelByUniqueName(githubSyncTask);
      await Future.delayed(const Duration(milliseconds: 300));
      await _registerTask(intervalMinutes, ExistingPeriodicWorkPolicy.replace);
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
