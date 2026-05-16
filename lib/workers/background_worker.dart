import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../utils/constants.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();
    
    final storage = StorageService();
    bool isDemo = inputData?['isDemo'] == true;
    int interval = 30; // fallback

    try {
      await storage.setLastBackgroundSyncAt(DateTime.now());
      await storage.setLastBackgroundSyncStatus('Sinkronisasi GitHub...');

      if (task == githubSyncTask || task.contains('githubSync')) {
        final appSettings = await storage.getAppSettings();
        interval = isDemo ? 5 : appSettings.syncIntervalMinutes;

        final updates = await SyncService.checkUpdates(
          isBackground: true,
          customInterval: interval,
        ).timeout(
          const Duration(minutes: 5),
        );

        final status = updates.isEmpty
            ? 'Success (No updates)'
            : 'Success (${updates.length} repos updated)';
        
        await storage.setLastBackgroundSyncStatus(status);
      }
      return true;
    } catch (e, stackTrace) {
      final errorMsg = 'Failed: ${e.toString()}';
      debugPrint('BackgroundWorker Error: $errorMsg\n$stackTrace');
      await storage.setLastBackgroundSyncStatus(errorMsg);
      // Kita kembalikan true agar WorkManager menganggap task ini selesai
      // (kita akan menjadwalkan task berikutnya di logic chaining di bawah).
      // Jika kita kembalikan false, WorkManager akan retry task yang SAMA,
      // yang bisa mengacaukan jadwal sync berikutnya.
      return true;
    } finally {
      // Chain the next task NO MATTER WHAT (selama bukan task tak dikenal)
      if (task == githubSyncTask) {
        try {
          // Jika demo, task berikutnya kembali ke normal (isDemo: false)
          // Jika gagal di tengah jalan, kita pastikan interval tetap valid
          await Workmanager().registerOneOffTask(
            githubSyncTask,
            githubSyncTask,
            initialDelay: Duration(minutes: interval),
            constraints: Constraints(networkType: NetworkType.connected),
            inputData: isDemo ? {'isDemo': false} : inputData,
            existingWorkPolicy: ExistingWorkPolicy.replace,
            backoffPolicy: BackoffPolicy.linear,
            backoffPolicyDelay: const Duration(minutes: 5),
          );
        } catch (_) {
          // Gagal menjadwalkan ulang? Setidaknya kita sudah mencoba.
        }
      }
    }
  });
}
