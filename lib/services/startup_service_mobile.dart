import 'package:workmanager/workmanager.dart';

import '../utils/constants.dart';
import '../workers/background_worker.dart';
import 'notification_service.dart';

class StartupService {
  static Future<void> init() async {
    try {
      await NotificationService.init();
      await Workmanager().initialize(callbackDispatcher);
      await _registerTask(defaultSyncIntervalMinutes);

      if (await NotificationService.launchedFromUpdateNotification()) {
        NotificationService.openUpdateScreen();
      }
    } catch (_) {
      // Startup must never block opening the app. Foreground sync still works.
    }
  }

  /// Cancel task lama dan daftarkan ulang — countdown 1 jam dimulai dari sekarang.
  static Future<void> resetBackgroundSync(int intervalMinutes) async {
    try {
      await Workmanager().cancelByUniqueName(githubSyncTask);
      await _registerTask(intervalMinutes);
    } catch (_) {}
  }

  static Future<void> _registerTask(int intervalMinutes) async {
    await Workmanager().registerPeriodicTask(
      githubSyncTask,
      githubSyncTask,
      frequency: Duration(minutes: intervalMinutes),
      flexInterval: const Duration(minutes: 10),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
        requiresStorageNotLow: true,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }
}
