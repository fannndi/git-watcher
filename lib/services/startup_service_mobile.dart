import 'package:workmanager/workmanager.dart';

import '../utils/constants.dart';
import '../workers/background_worker.dart';
import 'notification_service.dart';

class StartupService {
  static Future<void> init() async {
    try {
      await NotificationService.init();
      await Workmanager().initialize(callbackDispatcher);
      await Workmanager().registerPeriodicTask(
        githubSyncTask,
        githubSyncTask,
        frequency: const Duration(hours: 1),
        flexInterval: const Duration(minutes: 20),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
          requiresStorageNotLow: true,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 15),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );

      if (await NotificationService.launchedFromUpdateNotification()) {
        NotificationService.openUpdateScreen();
      }
    } catch (_) {
      // Startup must never block opening the app. Foreground sync still works.
    }
  }
}
