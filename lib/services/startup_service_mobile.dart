import 'package:workmanager/workmanager.dart';

import '../utils/constants.dart';
import '../workers/background_worker.dart';
import 'notification_service.dart';

class StartupService {
  static Future<void> init() async {
    await NotificationService.init();
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      githubSyncTask,
      githubSyncTask,
      frequency: const Duration(hours: 1),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }
}
