import 'package:workmanager/workmanager.dart';

import '../services/notification_service.dart';
import '../services/sync_service.dart';
import '../utils/constants.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == githubSyncTask) {
        // NotificationService harus diinisialisasi di isolate baru ini
        await NotificationService.init();

        // Jalankan sync dengan timeout yang cukup
        // (timeout terlalu pendek = sync selalu gagal di background)
        await SyncService.checkUpdates().timeout(
          const Duration(seconds: 55),
        );
      }
      return true;
    } catch (_) {
      // Kembalikan false agar WorkManager retry sesuai backoff policy
      return false;
    }
  });
}
