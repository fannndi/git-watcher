import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../utils/constants.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final storage = StorageService();
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await storage.setLastBackgroundSyncAt(DateTime.now());

      if (task == githubSyncTask) {
        // NotificationService harus diinisialisasi di isolate baru ini
        await NotificationService.init(isBackground: true);

        final appSettings = await storage.getAppSettings();
        final bool isDemo = inputData?['isDemo'] == true;
        final interval = isDemo ? 5 : appSettings.syncIntervalMinutes;

        // Jalankan sync
        final updates = await SyncService.checkUpdates(
          isBackground: true,
          customInterval: interval,
        ).timeout(
          const Duration(seconds: 55),
        );

        await storage.setLastBackgroundSyncStatus(
          updates.isEmpty
              ? 'Success (No updates)'
              : 'Success (${updates.length} repos updated)',
        );

        // Jadwalkan ulang task berikutnya (Chaining One-Off Task)
        await Workmanager().registerOneOffTask(
          githubSyncTask,
          githubSyncTask,
          initialDelay: Duration(minutes: interval),
          constraints: Constraints(networkType: NetworkType.connected),
          // Jika demo, task berikutnya kembali ke normal (isDemo: false)
          inputData: isDemo ? {'isDemo': false} : inputData,
          existingWorkPolicy: ExistingWorkPolicy.replace,
          backoffPolicy: BackoffPolicy.linear,
          backoffPolicyDelay: const Duration(minutes: 5),
        );
      }
      return true;
    } catch (e) {
      await storage.setLastBackgroundSyncStatus('Failed: ${e.toString()}');
      // Kembalikan false agar WorkManager retry sesuai backoff policy
      return false;
    }
  });
}
