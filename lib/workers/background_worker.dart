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
    // Both of these are required to use Flutter plugins inside a background isolate.
    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize notifications early so they're ready when sync completes.
    try {
      await NotificationService.init(isBackground: true);
    } catch (e) {
      debugPrint('BackgroundWorker: Notification init failed: $e');
    }

    final storage = StorageService();

    try {
      await storage.setLastBackgroundSyncAt(DateTime.now());
      await storage.setLastBackgroundSyncStatus('Sedang sinkronisasi...');

      if (task == githubSyncTask || task.contains('githubSync')) {
        final updates = await SyncService.checkUpdates(
          isBackground: true,
        ).timeout(const Duration(minutes: 8));

        final status = updates.isEmpty
            ? 'Berhasil (Tidak ada update)'
            : 'Berhasil (${updates.length} repo diupdate)';

        await storage.setLastBackgroundSyncStatus(status);
        debugPrint('BackgroundWorker: $status');
      }

      return Future.value(true);
    } catch (e, stackTrace) {
      final errorMsg = 'Gagal: ${e.toString()}';
      debugPrint('BackgroundWorker Error: $errorMsg\n$stackTrace');
      await storage.setLastBackgroundSyncStatus(errorMsg);
      // Returning true so WorkManager doesn't retry this specific run
      // with exponential backoff — the periodic schedule handles retries.
      return Future.value(true);
    }
  });
}
