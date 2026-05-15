import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../services/notification_service.dart';
import '../services/startup_service.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../utils/constants.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      if (task == githubSyncTask) {
        // NotificationService harus diinisialisasi di isolate baru ini
        await NotificationService.init(isBackground: true);

        // Jalankan sync dengan timeout yang cukup
        // (timeout terlalu pendek = sync selalu gagal di background)
        await SyncService.checkUpdates(isBackground: true).timeout(
          const Duration(seconds: 55),
        );
        
        // Jika ini task demo, jadwal kembali periodic task reguler
        if (inputData?['isDemo'] == true) {
          final storage = StorageService();
          final appSettings = await storage.getAppSettings();
          await StartupService.resetBackgroundSync(appSettings.syncIntervalMinutes);
        }
      }
      return true;
    } catch (_) {
      // Kembalikan false agar WorkManager retry sesuai backoff policy
      return false;
    }
  });
}
